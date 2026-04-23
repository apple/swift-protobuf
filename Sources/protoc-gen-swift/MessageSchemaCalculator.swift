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

/// Iterates over the fields of a message to compute the encoded schema string that will be emitted
/// into generated code.
struct MessageSchemaCalculator {
    /// Manages the generation of the Swift string literals that encode the message schema in the
    /// generated source.
    private var schemaWriters: TargetSpecificValues<SchemaWriter>

    /// Collects submessage information as it is encountered while iterating over the fields of the
    /// message.
    private var trampolineFieldCollector = TrampolineFieldCollector()

    /// The Swift string literals (without surrounding quotes) that encode the message schema in
    /// the generated source.
    var schemaLiterals: TargetSpecificValues<String> {
        schemaWriters.map(\.schemaCode)
    }

    /// The fully-qualified names of all submessages used by the message whose schema is being
    /// calculated.
    ///
    /// The first element in this array corresponds to the submessage with index 1, and the rest
    /// increase accordingly.
    var trampolineFields: [TrampolineField] {
        trampolineFieldCollector.usedFields.sorted { $0.value.index < $1.value.index }.map { $0.value }
    }

    /// Creates a new message schema calculator for a message containing the given fields and for
    /// a platform with the given pointer bit-width.
    init(fullyQualifiedName: String, fieldsSortedByNumber: [any FieldGenerator], isMapEntry: Bool = false) {
        self.schemaWriters = .init(forAllTargets: .init())

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

        // Compute the byte offset of each field in storage. From this point on, we need to use
        // target-specific values because fields might have different sizes on different
        // architectures.
        //
        // See the documentation for `FieldStorageKind` for more information about why this order
        // has been chosen.
        var byteOffsets = TargetSpecificValues<Int>(forAllTargets: byteOffset)
        let fieldsSortedByStorage = fieldsSortedByNumber.sorted { $0.storageKind < $1.storageKind }
        for field in fieldsSortedByStorage {
            let fieldSizes = field.storageKind.strides

            // Make sure we're properly aligned for this type.
            byteOffsets.align(to: fieldSizes)
            field.storageOffsets = byteOffsets
            byteOffsets.add(fieldSizes)

            trampolineFieldCollector.collect(field)
        }

        // Now we have all the information we need to generate the schema string. First we write
        // the header, then the fields in order of field number.
        schemaWriters.modify { writer, which in
            writer.writeBase128Int(0, byteWidth: 1)
            let messageSize = UInt64(byteOffsets[which])
            let encodedSize = messageSize | (isMapEntry ? (1 << 20) : 0)
            writer.writeBase128Int(encodedSize, byteWidth: 3)
            writer.writeBase128Int(UInt64(fieldsSortedByNumber.count), byteWidth: 3)
            writer.writeBase128Int(UInt64(requiredCount), byteWidth: 3)
            writer.writeBase128Int(UInt64(explicitPresenceCount), byteWidth: 3)
            writer.writeBase128Int(UInt64(denseBelow), byteWidth: 3)
            for field in fieldsSortedByNumber {
                writer.writeBase128Int(UInt64(field.number) | (UInt64(field.fieldMode.rawValue) << 28), byteWidth: 5)
                writer.writeBase128Int(UInt64(field.storageOffsets[which]), byteWidth: 3)
                writer.writeBase128Int(UInt64(field.presence.rawPresence), byteWidth: 2)
                writer.writeBase128Int(
                    UInt64(trampolineFieldCollector.fieldNumberToTrampolineIndexMap[field.number, default: 0]),
                    byteWidth: 2
                )
                writer.writeBase128Int(UInt64(field.rawFieldType.rawValue), byteWidth: 1)
            }
            writer.writeBase128Int(UInt64(fullyQualifiedName.utf8.count), byteWidth: 2)
            writer.writeString(fullyQualifiedName)
        }
    }

    /// Creates a new message schema writer for a single extension field.
    init(extensionField: any FieldGenerator, extensionName: String) {
        trampolineFieldCollector.collect(extensionField)

        self.schemaWriters = .init(forAllTargets: .init())
        schemaWriters.modify { writer, _ in
            writer.writeBase128Int(0, byteWidth: 1)
            writer.writeBase128Int(
                UInt64(extensionField.number) | (UInt64(extensionField.fieldMode.rawValue) << 28), byteWidth: 5)
            writer.writeBase128Int(UInt64(0), byteWidth: 3)
            writer.writeBase128Int(UInt64(0), byteWidth: 2)
            writer.writeBase128Int(
                UInt64(trampolineFieldCollector.fieldNumberToTrampolineIndexMap[extensionField.number, default: 0]),
                byteWidth: 2
            )
            writer.writeBase128Int(UInt64(extensionField.rawFieldType.rawValue), byteWidth: 1)

            writer.writeBase128Int(UInt64(extensionName.utf8.count), byteWidth: 2)
            writer.writeString(extensionName)
        }
    }
}

/// Collects the message and enum types referenced by a message whose schema is being generated,
/// assigning each one a unique index that will be used when looking them up by the runtime.
private struct TrampolineFieldCollector {
    /// Tracks the field numbers of any submessage fields and the corresponding index of that
    /// submessage.
    var fieldNumberToTrampolineIndexMap: [Int: Int] = [:]

    /// Tracks which submessage types have already been encountered, along with their field
    /// generator and index.
    var usedFields: [String: TrampolineField] = [:]

    /// Tracks the index that will be assigned to the next newly encountered submessage.
    private var nextIndex = 1

    /// Tracks the submessage with the given type name and field number.
    mutating func collect(_ field: any FieldGenerator) {
        guard let kind = field.trampolineFieldKind else { return }
        let trampolineIndex: Int
        if let foundIndex = usedFields[kind.name]?.index {
            trampolineIndex = foundIndex
        } else {
            trampolineIndex = nextIndex
            usedFields[kind.name] = TrampolineField(
                kind: kind,
                index: trampolineIndex,
                needsIsInitializedCheck: field.needsIsInitializedGeneration
            )
            nextIndex += 1
        }
        fieldNumberToTrampolineIndexMap[field.number] = trampolineIndex
    }
}

struct TrampolineField {
    /// The kind and name of the field that needs trampoline generation.
    var kind: TrampolineFieldKind

    /// The index of the submessage, which will be used to generate submessage tokens.
    var index: Int

    /// Indicates whether we need to recursively walk this submessage to implement the
    /// `isInitialized` check or if it can vacuously return true (e.g., if it has no required fields
    /// or submessages with required fields).
    var needsIsInitializedCheck: Bool
}
