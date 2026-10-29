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
/// ## Enum schema layout
///
/// The **enum schema** is encoded in 7-bit ASCII as a `StaticString`. Its layout depends on
/// whether the enum is open or closed, indicated by bit 20 (`0x40` of Byte 3) of Bytes 1-3:
///
/// ### Open enum (`isClosed == false`, bit 20 of Bytes 1-3 is `0`)
///
/// ```
/// +---------+-------------------+-------------+------------+
/// | Byte 0  | Bytes 1-3         | Bytes 4-5   | Bytes 6... |
/// | Version | Value count       | Name length | Enum name  |
/// |         | & isClosed = 0    | (2 bytes)   | (UTF-8)    |
/// +---------+-------------------+-------------+------------+
/// ```
///
/// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
/// *   Bytes 1-3: A 3-byte base-128 integer where bits 0-19 encode the number of defined values in
///     the enum (excluding aliases) and bit 20 (`0x40` of Byte 3) is `0`.
/// *   Bytes 4-5: The length of the enum's fully-qualified name, as a 2-byte base-128 integer.
/// *   Bytes 6...: The fully-qualified name of the enum, as UTF-8 encoded bytes.
///
/// ### Closed enum (`isClosed == true`, bit 20 of Bytes 1-3 is `1`)
///
/// ```
/// +---------+----------------------+--------------+-------------+---------------+-------------+------------+
/// | Byte 0  | Bytes 1-3            | Bytes 4-6    | Bytes 7...  | Next 5*S      | Next 2      | Remaining  |
/// | Version | Mask byte count (M)  | Sparse value | Bitmask     | Sparse values | Name length | Enum name  |
/// |         | & isClosed = 1       | count (S)    | (M bytes)   | (5*S bytes)   | (2 bytes)   | (UTF-8)    |
/// +---------+----------------------+--------------+-------------+---------------+-------------+------------+
/// ```
///
/// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
/// *   Bytes 1-3: A 3-byte base-128 integer where bits 0-19 encode `M`, the number of bytes in the
///     dense bitmask section, and bit 20 (`0x40` of Byte 3) is `1`.
/// *   Bytes 4-6: `S`, the number of values in the sparse values section, as a 3-byte base-128
///     integer.
/// *   Bytes 7..<(7 + M): The dense bitmask section. Each byte stores 7 bits covering non-negative
///     enum values `0 ..< M * 7` (`bit = unsignedValue % 7` in `byte = unsignedValue / 7`).
/// *   Next `5 * S` bytes: The sparse values section, containing defined enum values outside
///     `0 ..< M * 7` (including large positive values and negative values), encoded as 5-byte
///     base-128 `UInt32(bitPattern:)` integers in ascending unsigned order.
/// *   Next 2 bytes: The length of the enum's fully-qualified name, as a 2-byte base-128 integer.
/// *   Remaining bytes: The fully-qualified name of the enum, as UTF-8 encoded bytes.
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
    public typealias DynamicLookupThunk = @convention(thin) @Sendable (UnsafeMutableRawPointer) -> Void

    @_spi(ForGeneratedCodeOnly)
    public typealias DynamicMapWitnessThunk = @convention(thin) @Sendable (UInt8, UnsafeMutableRawPointer) -> Void

    @_spi(ForGeneratedCodeOnly)
    public let invokeWitness: InvokeWitnessFunction

    /// Creates a new enum schema from the given values.
    @_spi(ForGeneratedCodeOnly)
    public convenience init(
        schema: StaticString,
        reflection: StaticString,
        invokeWitness: @escaping InvokeWitnessFunction,
        dynamicLookupThunk: DynamicLookupThunk? = nil,
        dynamicMapWitnessThunk: DynamicMapWitnessThunk? = nil
    ) {
        precondition(
            reflection.hasPointerRepresentation,
            "The reflection string should have a pointer-based representation; this is a generator bug"
        )
        self.init(
            schema: schema,
            reflection: .compressed(reflection.rawBufferPointer),
            invokeWitness: invokeWitness,
            dynamicLookupThunk: dynamicLookupThunk,
            dynamicMapWitnessThunk: dynamicMapWitnessThunk
        )
    }

    /// Creates a new enum schema from the given values, resolving the witness function
    /// dynamically by symbol name.
    @_spi(ForGeneratedCodeOnly)
    public convenience init(
        schema: StaticString,
        reflection: StaticString,
        witnessSymbol: StaticString,
        dynamicLookupThunk: DynamicLookupThunk? = nil
    ) {
        precondition(
            reflection.hasPointerRepresentation,
            "The reflection string should have a pointer-based representation; this is a generator bug"
        )
        self.init(
            schema: schema,
            reflection: .compressed(reflection.rawBufferPointer),
            invokeWitness: Self.resolveLazyWitness(named: witnessSymbol),
            dynamicLookupThunk: dynamicLookupThunk
        )
    }

    #if canImport(Darwin)
    /// Creates a new enum schema from the given values, resolving the reflection table and
    /// witness function dynamically by symbol name.
    @_spi(ForGeneratedCodeOnly)
    public convenience init(
        schema: StaticString,
        reflectionSymbol: StaticString,
        witnessSymbol: StaticString,
        dynamicLookupThunk: DynamicLookupThunk? = nil
    ) {
        self.init(
            schema: schema,
            reflection: .unloaded(reflectionSymbol),
            invokeWitness: Self.resolveLazyWitness(named: witnessSymbol),
            dynamicLookupThunk: dynamicLookupThunk
        )
    }
    #endif

    /// Creates a new enum schema from a raw schema buffer for testing.
    package init(schemaBuffer: UnsafeRawBufferPointer) {
        self.schema = schemaBuffer
        self.reflection = .uncompressed(ReflectionTable(fieldCount: 0, data: []))
        self.invokeWitness = EnumWitnesses<SwiftProtobuf_ImplicitWeakEnum>.perform
        validateSchemaBuffer()
    }

    private init(
        schema: StaticString,
        reflection: ReflectionTable.State,
        invokeWitness: InvokeWitnessFunction?,
        dynamicLookupThunk: DynamicLookupThunk? = nil,
        dynamicMapWitnessThunk: DynamicMapWitnessThunk? = nil
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        let schemaBuffer = schema.rawBufferPointer
        self.schema = schemaBuffer
        self.reflection = reflection
        // If this schema belongs to a weakly-imported enum whose concrete Swift type and
        // witness table (`.pb.o`) were dead-stripped, use `SwiftProtobuf_ImplicitWeakEnum`
        // as a layout-compatible stand-in.
        self.invokeWitness = invokeWitness ?? EnumWitnesses<SwiftProtobuf_ImplicitWeakEnum>.perform

        // Referencing the thunks forces them to be retained by the compiler if the schema
        // itself is retained; see the comments in `WeakLinkageSupport.swift` for more details.
        _ = dynamicLookupThunk
        _ = dynamicMapWitnessThunk

        validateSchemaBuffer()
    }

    private func validateSchemaBuffer() {
        precondition(
            schema.count >= openEnumSchemaHeaderSize + 2,
            "The schema is too small for the values it claims to have; this is a generator bug"
        )
        precondition(version == 0, "This runtime only supports version 0 enum schemas")
        if isClosed {
            precondition(
                schema.count >= closedEnumSchemaHeaderSize + maskByteCount + sparseCount * sparseValueSize + 2,
                "The schema is too small for the values it claims to have; this is a generator bug"
            )
        }
    }
}

private let openEnumSchemaHeaderSize = 4
private let closedEnumSchemaHeaderSize = 7
private let sparseValueSize = 5
private let enumIsClosedBitMask: UInt8 = 0x40
private let enumIsClosedWordMask = Int(enumIsClosedBitMask) << 14

extension EnumSchema {
    private var version: UInt8 {
        schema.load(fromByteOffset: 0, as: UInt8.self)
    }

    /// Whether this enum has closed semantics (unrecognized values are treated as unknown fields)
    /// or open semantics (unrecognized values are preserved in the field).
    package var isClosed: Bool {
        (schema.load(fromByteOffset: 3, as: UInt8.self) & enumIsClosedBitMask) != 0
    }

    /// The number of bytes in the dense bitmask section (0 for open enums).
    package var maskByteCount: Int {
        let word = fixed3ByteBase128(in: schema, atByteOffset: 1)
        guard (word & enumIsClosedWordMask) != 0 else { return 0 }
        return word & ~enumIsClosedWordMask
    }

    /// The number of 5-byte entries in the sparse values section (0 for open enums).
    package var sparseCount: Int {
        guard isClosed else { return 0 }
        return fixed3ByteBase128(in: schema, atByteOffset: 4)
    }

    /// The number of values defined in this enum, excluding aliases.
    package var valueCount: Int {
        let word = fixed3ByteBase128(in: schema, atByteOffset: 1)
        guard (word & enumIsClosedWordMask) != 0 else {
            return word
        }
        let maskBytes = word & ~enumIsClosedWordMask
        var count = fixed3ByteBase128(in: schema, atByteOffset: 4)
        for i in 0..<maskBytes {
            count += schema.load(fromByteOffset: closedEnumSchemaHeaderSize + i, as: UInt8.self).nonzeroBitCount
        }
        return count
    }

    /// The fully-qualified name of the enum.
    package var enumName: UTF8Name {
        let word = fixed3ByteBase128(in: schema, atByteOffset: 1)
        let lengthOffset: Int
        if (word & enumIsClosedWordMask) != 0 {
            let maskBytes = word & ~enumIsClosedWordMask
            let sparseEntries = fixed3ByteBase128(in: schema, atByteOffset: 4)
            lengthOffset = closedEnumSchemaHeaderSize + maskBytes + sparseEntries * sparseValueSize
        } else {
            lengthOffset = openEnumSchemaHeaderSize
        }
        let length = fixed2ByteBase128(in: schema, atByteOffset: lengthOffset)
        let nameStart = lengthOffset + 2
        return UTF8Name(start: schema.baseAddress! + nameStart, count: length)
    }
}

extension EnumSchema {
    /// Returns true if the given value is a valid value for this enum.
    ///
    /// For open enums, any value is considered valid. For closed enums, a value is valid only if
    /// it corresponds to an explicitly defined case encoded in the bitmask or sparse values list.
    package func isValidValue(_ value: Int32) -> Bool {
        let maskByteCountAndClosedFlag = fixed3ByteBase128(in: schema, atByteOffset: 1)
        guard (maskByteCountAndClosedFlag & enumIsClosedWordMask) != 0 else { return true }

        let unsignedValue = UInt32(bitPattern: value)
        let maskBytes = maskByteCountAndClosedFlag & ~enumIsClosedWordMask
        let maskLimit = UInt32(maskBytes) * 7
        if unsignedValue < maskLimit {
            let byteIndex = Int(unsignedValue / 7)
            let bitIndex = unsignedValue % 7
            let byte = schema.load(fromByteOffset: closedEnumSchemaHeaderSize + byteIndex, as: UInt8.self)
            return (byte & (1 &<< bitIndex)) != 0
        }

        let count = fixed3ByteBase128(in: schema, atByteOffset: 4)
        guard count > 0 else { return false }

        let sparseStart = closedEnumSchemaHeaderSize + maskBytes
        var low = 0
        var high = count
        while low < high {
            let mid = (low + high) &>> 1
            let candidate = fixed5ByteBase128(
                in: schema,
                atByteOffset: sparseStart + mid * sparseValueSize
            )
            if candidate == unsignedValue {
                return true
            } else if candidate < unsignedValue {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return false
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
