// Sources/SwiftProtobuf/EnumSchema.swift - Type-erased enum schema
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The schema that describes the cases of an enum.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Describes a protobuf enum.
///
/// ## Enum schema header
///
/// The **enum schema header** describes properties of the entire enum:
///
/// ```
/// +---------+-------------+-------------+------------+
/// | Byte 0  | Bytes 1-5   | Bytes 6-7   | Bytes 8... |
/// | Version | Value count | Name length | Enum name  |
/// +---------+-------------+-------------+------------+
/// ```
///
/// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
/// *   Bytes 1-5: The number of defined cases (aliases are not included), as a base-128 integer.
/// *   Bytes 6-7: The length of the enum's fully-qualified name, as a base-128 integer.
/// *   Bytes 8...: The fully-qualified name of the enum, as UTF-8 encoded bytes.
public final class EnumSchema: @unchecked Sendable {
    /// The encoded schema of the values of this enum.
    private let schema: UnsafeRawBufferPointer

    /// The reflection table state for the enum.
    ///
    /// All access to this field is guarded by `ReflectionTable.decompressionLock`.
    private var reflection: ReflectionTable.State

    @_spi(ForGeneratedCodeOnly)
    public typealias InvokeWitnessFunction = (EnumWitnessOperation) -> Void

    @_spi(ForGeneratedCodeOnly)
    public typealias DynamicLookupThunk = @convention(thin) (UnsafeMutableRawPointer) -> Void

    @_spi(ForGeneratedCodeOnly)
    public typealias DynamicMapWitnessThunk = @convention(thin) (UInt8, UnsafeMutableRawPointer) -> Void

    @_spi(ForGeneratedCodeOnly)
    public let invokeWitness: InvokeWitnessFunction

    /// Creates a new enum schema from the given values.
    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        reflection: StaticString,
        invokeWitness: @escaping InvokeWitnessFunction,
        dynamicLookupThunk: DynamicLookupThunk? = nil,
        dynamicMapWitnessThunk: DynamicMapWitnessThunk? = nil
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        precondition(
            reflection.hasPointerRepresentation,
            "The reflection string should have a pointer-based representation; this is a generator bug"
        )
        let schemaBuffer = schema.rawBufferPointer
        self.schema = schemaBuffer
        self.reflection = .compressed(reflection.rawBufferPointer)
        self.invokeWitness = invokeWitness

        // Referencing the thunks forces them to be retained by the compiler if the schema
        // itself is retained; see the comments in `WeakLinkageSupport.swift` for more details.
        _ = dynamicLookupThunk
        _ = dynamicMapWitnessThunk
    }
}

private let enumSchemaHeaderSize = 6

extension EnumSchema {
    /// Helper function to read the value count from the schema buffer.
    static func valueCount(from buffer: UnsafeRawBufferPointer) -> Int {
        let lowBits = UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: 1, as: UInt32.self))
        let highBits = buffer.loadUnaligned(fromByteOffset: 5, as: UInt8.self)
        let part1 = (lowBits & 0x00_0000_007f)
        let part2 = ((lowBits & 0x00_0000_7f00) >> 1)
        let part3 = ((lowBits & 0x00_007f_0000) >> 2)
        let part4 = ((lowBits & 0x00_7f00_0000) >> 3)
        let part5 = UInt32(highBits & 0x0f) << 28
        return Int(part1 | part2 | part3 | part4 | part5)
    }

    /// The number of values defined in this enum, excluding aliases.
    var valueCount: Int {
        Self.valueCount(from: schema)
    }

    /// The fully-qualified name of the enum.
    var enumName: UTF8Name {
        let lengthOffset = enumSchemaHeaderSize
        let length = fixed2ByteBase128(in: schema, atByteOffset: lengthOffset)
        let nameStart = lengthOffset + 2
        return UTF8Name(start: schema.baseAddress! + nameStart, count: length)
    }
}

extension EnumSchema {
    /// Returns true if the given value is a valid value for this enum.
    ///
    /// For closed enums, a value is valid only if it corresponds to an explicitly defined case.
    /// For open enums, any value is considered valid.
    func isValidValue(_ value: Int32) -> Bool {
        var isValid = false
        withUnsafeMutablePointer(to: &isValid) { isValidPointer in
            invokeWitness(.rawValueIsValid(rawValue: value, result: isValidPointer))
        }
        return isValid
    }

    /// Calls the given body with the reflection table, decompressing it on the
    /// first call if needed.
    func withReflectionTable<R>(_ body: (borrowing ReflectionTable) throws -> R) rethrows -> R {
        let table = ReflectionTable.decompressionLock.withLock {
            reflection.decompressingIfNeeded(fieldCount: valueCount)
        }
        return try body(table)
    }

    /// The text name for the given enum case value.
    func textName(forEnumCase value: Int32) -> UTF8Name? {
        withReflectionTable { $0.textName(forEnumCase: value) }
    }

    /// The JSON name for the given enum case value.
    func jsonName(forEnumCase value: Int32) -> UTF8Name? {
        withReflectionTable { $0.jsonName(forEnumCase: value) }
    }

    /// The enum case value for the given text name.
    func enumCase(forTextName name: String) -> Int32? {
        withReflectionTable { $0.enumCase(forTextName: name) }
    }

    /// The enum case value for the given JSON name.
    func enumCase(forJSONName name: String) -> Int32? {
        withReflectionTable { $0.enumCase(forJSONName: name) }
    }

    /// Compares two enums of this schema for equality.
    @_spi(ForGeneratedCodeOnly)
    public func areEqual(_ lhs: UnsafeRawPointer, _ rhs: UnsafeRawPointer) -> Bool {
        var isEqual = false
        withUnsafeMutablePointer(to: &isEqual) { resultPtr in
            invokeWitness(.enumEqual(lhs: lhs, rhs: rhs, result: resultPtr))
        }
        return isEqual
    }
}
