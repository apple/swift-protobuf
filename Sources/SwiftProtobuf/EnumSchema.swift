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

import Foundation

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
public struct EnumSchema: @unchecked Sendable {
    /// The encoded schema of the values of this enum.
    private let schema: UnsafeRawBufferPointer

    /// The reference to the reflection table for the enum.
    private let reflection: ReflectionTableReference

    @_spi(ForGeneratedCodeOnly)
    public typealias InvokeWitnessFunction = (EnumWitnessOperation) -> Void

    let invokeWitness: InvokeWitnessFunction

    /// Creates a new enum schema from the given values.
    @_spi(ForGeneratedCodeOnly)
    public init(schema: StaticString, reflection: StaticString, invokeWitness: @escaping InvokeWitnessFunction) {
        self.schema = schema.rawBufferPointer
        // TODO: Use the `.compressed` form and lazily decompress and cache it.
        self.reflection = .direct(ReflectionTable(
            fieldCount: Self.valueCount(from: schema.rawBufferPointer),
            data: Compression.decompress(reflection.rawBufferPointer)
        ))
        self.invokeWitness = invokeWitness
    }
}

private let enumSchemaHeaderSize = 6

extension EnumSchema {
    /// Helper function to read the value count from the schema buffer.
    static func valueCount(from buffer: UnsafeRawBufferPointer) -> Int {
        let lowBits = UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: 1, as: UInt32.self))
        let highBits = buffer.loadUnaligned(fromByteOffset: 5, as: UInt8.self)
        return Int((lowBits & 0x00_0000_007f)
            | ((lowBits & 0x00_0000_7f00) >> 1)
            | ((lowBits & 0x00_007f_0000) >> 2)
            | ((lowBits & 0x00_7f00_0000) >> 3)
            | (UInt32(highBits & 0x0f) << 28))
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

    /// The text and JSON name for the given enum case value.
    func textName(forEnumCase value: Int32) -> UTF8Name? {
        reflection.table.textName(forEnumCase: value)
    }

    /// The enum case value for the given text and JSON name.
    func enumCase(forTextName name: String) -> Int32? {
        reflection.table.enumCase(forTextName: name)
    }
}
