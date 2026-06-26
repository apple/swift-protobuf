// Sources/protoc-gen-swift/MessageSchemaCalculator.swift - Message schema calculator
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implements the logic that computes the in-memory layout of a message and
/// the string representation used to encode it in the generated message.
///
// -----------------------------------------------------------------------------

import SwiftProtobuf

/// Iterates over the fields of a message to compute the encoded schema string that will be emitted
/// into generated code.
struct MessageSchemaCalculator {
    /// Manages the generation of the Swift string literal that encodes the message schema in the
    /// generated source.
    private var schemaWriter: SchemaWriter

    /// Collects submessage information as it is encountered while iterating over the fields of the
    /// message.
    private var submessageOrEnumCollector = SubmessageOrEnumCollector()

    /// The Swift string literal (without surrounding quotes) that encodes the message schema in
    /// the generated source.
    var schemaLiteral: String {
        schemaWriter.schemaCode
    }

    /// The fully-qualified names of all submessages used by the message whose schema is being
    /// calculated.
    ///
    /// The first element in this array corresponds to the submessage with index 1, and the rest
    /// increase accordingly.
    var submessageOrEnumFields: [SubmessageOrEnumField] {
        submessageOrEnumCollector.usedFields.sorted { $0.value.index < $1.value.index }.map { $0.value }
    }

    /// Creates a new message schema calculator for a message containing the given fields.
    init(
        fullyQualifiedName: String,
        fieldsSortedByNumber: [any FieldGenerator],
        extensibilityMode: ExtensibilityMode = .nonextensible
    ) {
        self.schemaWriter = .init()

        let fieldCount = fieldsSortedByNumber.count

        // Compute the field density threshold. This is the largest value `N` such that all fields
        // `1..<N` are defined.
        var lastFieldNumber = 0
        for field in fieldsSortedByNumber {
            guard field.number == lastFieldNumber + 1 else {
                break
            }
            lastFieldNumber = field.number
        }
        let denseBelow = lastFieldNumber + 1

        let fieldsSortedByPresence = fieldsSortedByNumber.sorted {
            // Requires fields should be first, followed by fields that have explicit presence (but
            // are not required).
            if $0.isRequired {
                return !$1.isRequired
            }
            return $0.hasPresence && !$1.hasPresence
        }
        var requiredCount = 0
        var explicitPresenceCount = 0
        var hasBitIndex: UInt16 = 0
        var deferredOneofMembers = [any FieldGenerator]()
        for field in fieldsSortedByPresence {
            if field.oneofIndex != nil {
                deferredOneofMembers.append(field)
            } else {
                // The presence is just the has-bit index.
                field.presence = .hasBit(hasBitIndex)
                hasBitIndex += 1

                if field.isRequired {
                    requiredCount += 1
                }
                if field.hasPresence {
                    explicitPresenceCount += 1
                }
            }
        }
        assert(
            requiredCount <= explicitPresenceCount,
            "internal error: requiredCount should not be higher than explicitPresenceCount"
        )
        assert(
            explicitPresenceCount <= fieldsSortedByNumber.count,
            "internal error: explicitPresenceCount should not be higher than field count"
        )

        // Compute the byte offset following the has-bits.
        var byteOffset = fieldCount / 8 + (fieldCount % 8 != 0 ? 1 : 0)

        // If any oneofs are present in the message, allocate a `UInt32` for each one that will be
        // used to record the field number of the currently set member field. These are placed
        // immediately after the has-bits (modulo alignment).
        if !deferredOneofMembers.isEmpty {
            let misalignment = byteOffset % MemoryLayout<UInt32>.alignment
            if misalignment != 0 {
                byteOffset += MemoryLayout<UInt32>.alignment - misalignment
            }
            for field in deferredOneofMembers {
                field.presence = .oneofMember(UInt16(byteOffset + field.oneofIndex! * MemoryLayout<UInt32>.stride))
            }
            byteOffset += deferredOneofMembers.count * MemoryLayout<UInt32>.stride
        }

        // Group fields into their respective storage buckets.
        var stableFields = [any FieldGenerator]()
        var repeatedFields = [any FieldGenerator]()
        var mapFields = [any FieldGenerator]()
        var messageFields = [any FieldGenerator]()
        var stringFields = [any FieldGenerator]()
        var bytesFields = [any FieldGenerator]()

        for field in fieldsSortedByNumber {
            switch field.storageBucket {
            case .stable:
                stableFields.append(field)
            case .repeated:
                repeatedFields.append(field)
            case .map:
                mapFields.append(field)
            case .message:
                messageFields.append(field)
            case .string:
                stringFields.append(field)
            case .bytes:
                bytesFields.append(field)
            default:
                preconditionFailure("Unreachable")
            }
        }

        // Lay out stable-size fields. Since stable-size fields only have sizes of 1, 4, or 8 bytes
        // (which are identical on 32-bit and 64-bit platforms), their layout is 100% target-independent.
        let stableFieldsSortedByStorage = stableFields.sorted { $0.stableStride < $1.stableStride }
        for field in stableFieldsSortedByStorage {
            let stride = field.stableStride
            let misalignment = byteOffset % stride
            if misalignment != 0 {
                byteOffset += stride - misalignment
            }
            field.storageOffsetOrIndex = byteOffset
            byteOffset += stride
            submessageOrEnumCollector.collect(field)
        }
        let stableSize = byteOffset

        // Helper to assign zero-based indices to unstable-size fields within their respective buckets.
        func assignIndices(to bucket: [any FieldGenerator]) {
            for (index, field) in bucket.enumerated() {
                field.storageOffsetOrIndex = index
                submessageOrEnumCollector.collect(field)
            }
        }
        assignIndices(to: repeatedFields)
        assignIndices(to: mapFields)
        assignIndices(to: messageFields)
        assignIndices(to: stringFields)
        assignIndices(to: bytesFields)

        // Now we have all the information we need to generate the schema string. First we write
        // the header, then the fields in order of field number.
        schemaWriter.writeBase128Int(0, byteWidth: 1)
        let encodedSize = UInt64(stableSize) | (UInt64(extensibilityMode.rawValue) << 14)
        schemaWriter.writeBase128Int(encodedSize, byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(fieldsSortedByNumber.count), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(requiredCount), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(explicitPresenceCount), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(denseBelow), byteWidth: 3)

        // Append 5 independent 3-byte base-128 bucket counts
        schemaWriter.writeBase128Int(UInt64(repeatedFields.count), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(mapFields.count), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(messageFields.count), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(stringFields.count), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(bytesFields.count), byteWidth: 3)

        for field in fieldsSortedByNumber {
            schemaWriter.writeBase128Int(UInt64(field.number) | (UInt64(field.fieldMode.rawValue) << 28), byteWidth: 5)

            // Pack 3-bit StorageBucket into the top 3 bits (bits 18-20) of the 21-bit offset/index payload
            let rawOffsetOrIndex = UInt64(field.storageOffsetOrIndex)
            let bucket = field.storageBucket
            let packedOffsetOrIndex = rawOffsetOrIndex | (UInt64(bucket.rawValue) << 18)
            schemaWriter.writeBase128Int(packedOffsetOrIndex, byteWidth: 3)

            schemaWriter.writeBase128Int(UInt64(field.presence.rawPresence), byteWidth: 2)
            schemaWriter.writeBase128Int(
                UInt64(submessageOrEnumCollector.fieldNumberToIndexMap[field.number, default: 0]),
                byteWidth: 2
            )
            schemaWriter.writeBase128Int(UInt64(field.rawFieldType.rawValue), byteWidth: 1)
        }
        schemaWriter.writeBase128Int(UInt64(fullyQualifiedName.utf8.count), byteWidth: 2)
        schemaWriter.writeString(fullyQualifiedName)
    }

    /// Creates a new message schema writer for a single extension field.
    init(extensionField: any FieldGenerator, extensionName: String) {
        submessageOrEnumCollector.collect(extensionField)

        self.schemaWriter = .init()
        schemaWriter.writeBase128Int(0, byteWidth: 1)
        schemaWriter.writeBase128Int(
            UInt64(extensionField.number) | (UInt64(extensionField.fieldMode.rawValue) << 28),
            byteWidth: 5
        )
        schemaWriter.writeBase128Int(UInt64(0), byteWidth: 3)
        schemaWriter.writeBase128Int(UInt64(0), byteWidth: 2)
        schemaWriter.writeBase128Int(
            UInt64(submessageOrEnumCollector.fieldNumberToIndexMap[extensionField.number, default: 0]),
            byteWidth: 2
        )
        schemaWriter.writeBase128Int(UInt64(extensionField.rawFieldType.rawValue), byteWidth: 1)

        schemaWriter.writeBase128Int(UInt64(extensionName.utf8.count), byteWidth: 2)
        schemaWriter.writeString(extensionName)
    }
}

/// Collects the message and enum types referenced by a message whose schema is being generated,
/// assigning each one a unique index that will be used when looking them up by the runtime.
private struct SubmessageOrEnumCollector {
    /// Tracks the field numbers of any submessage fields and the corresponding index of that
    /// submessage.
    var fieldNumberToIndexMap: [Int: Int] = [:]

    /// Tracks which submessage types have already been encountered, along with their field
    /// generator and index.
    var usedFields: [SubmessageOrEnumReference: SubmessageOrEnumField] = [:]

    /// Tracks the index that will be assigned to the next newly encountered submessage.
    private var nextIndex = 1

    /// Tracks the submessage with the given type name and field number.
    mutating func collect(_ field: any FieldGenerator) {
        guard let kind = field.submessageOrEnumReference else { return }
        let submessageOrEnumIndex: Int
        if let foundIndex = usedFields[kind]?.index {
            submessageOrEnumIndex = foundIndex
        } else {
            submessageOrEnumIndex = nextIndex
            usedFields[kind] = SubmessageOrEnumField(
                kind: kind,
                index: submessageOrEnumIndex
            )
            nextIndex += 1
        }
        fieldNumberToIndexMap[field.number] = submessageOrEnumIndex
    }
}

/// Information about a submessage or enum field that needs extra information to generate it.
struct SubmessageOrEnumField {
    /// The kind and name of the submessage or enum.
    var kind: SubmessageOrEnumReference

    /// The index of the submessage, which will be used to generate submessage tokens.
    var index: Int
}
