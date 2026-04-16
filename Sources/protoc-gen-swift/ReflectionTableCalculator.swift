// Sources/protoc-gen-swift/ReflectionTableCalculator.swift - Reflection table calculator
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implements the logic that computes the compressed reflection data that is
/// associated with a message or enum. This table includes the field or enum
/// case names and default values.
///
// -----------------------------------------------------------------------------

import SwiftProtobuf
import SwiftProtobufPluginLibrary

/// Calculates the compressed reflection data for a generated message or enum.
///
/// This data includes field names, JSON field names, and default values.
package struct ReflectionTableCalculator {
    /// Describes the name of a field or enum case.
    struct Names {
        /// The text format name of the field or enum case.
        var name: String

        /// The JSON name of the field or enum case, if it differs from the text format name.
        ///
        /// If nil, the JSON name is assumed to be the same as the text format name.
        var jsonName: String?
    }

    /// The names of the fields or enum cases.
    ///
    /// When this type is used to store fields, each value array will only have one element. When
    /// it is being used to store enum case values, there will be multiple elements if there are
    /// aliases (the first is always the primary name), and we store the unsigned bit-pattern
    /// equivalent of the case values, which may be negative.
    private var names: [UInt32: [Names]] = [:]

    /// The ranges of any reserved field numbers (used for messages only).
    private var reservedRanges: [Range<Int32>] = []

    /// The names of any reserved field names (used for messages only).
    private var reservedNames: [String] = []

    // TODO: Add default values for fields.

    /// Initializes a new reflection table calculator for a message with the given fields.
    package init(
        fields: [any FieldGenerator],
        reservedRanges: [Range<Int32>],
        reservedNames: [String]
    ) {
        for field in fields {
            addField(field)
        }
        self.reservedRanges = reservedRanges
        self.reservedNames = reservedNames
    }

    /// Initializes a new reflection table calculator for an enum with the given values and alias
    /// information.
    package init(enumValues: [EnumValueDescriptor], aliasInfo: EnumDescriptor.ValueAliasInfo) {
        for enumValue in enumValues {
            addEnumValue(enumValue, aliases: aliasInfo.aliases(enumValue) ?? [])
        }
    }

    /// Adds information about a message field to the reflection tables.
    private mutating func addField(_ field: any FieldGenerator) {
        let fieldNumber = UInt32(field.number)
        let jsonName: String? = (field.name == field.jsonName) ? nil : field.jsonName
        names[fieldNumber] = [Names(name: field.name, jsonName: jsonName)]
    }

    /// Adds information about an enum value and all of its aliases to the reflection tables.
    private mutating func addEnumValue(_ enumValue: EnumValueDescriptor, aliases: [EnumValueDescriptor]) {
        let valueNumber = UInt32(bitPattern: enumValue.number)
        var list = [Names(name: enumValue.name, jsonName: nil)]
        for alias in aliases {
            list.append(Names(name: alias.name, jsonName: nil))
        }
        names[valueNumber] = list
    }

    /// Returns the uncompressed table data.
    ///
    /// This is exposed for testing. Generators should call `stringLiteral()` instead.
    package func uncompressedData() -> [UInt8] {
        var result: [UInt8] = []

        /// Keeps track of the original name stored at the given offset for ease of sorting the
        /// name -> number tables alphabetically.
        struct NameOffsetKey: Equatable, Hashable {
            var offset: UInt32
            var name: String
        }

        /// Adds zero padding to the result buffer to ensure that it is properly aligned for the
        /// next value to be written of type `T`.
        func align<T: BinaryInteger & FixedWidthInteger>(to type: T.Type) {
            let misalignment = result.count % MemoryLayout<T>.alignment
            if misalignment != 0 {
                result.append(contentsOf: repeatElement(0, count: MemoryLayout<T>.alignment - misalignment))
            }
        }

        /// Encodes an integer in the result buffer, ensuring that the buffer is properly aligned
        /// and the value is stored in little endian form.
        func appendInteger<T: BinaryInteger & FixedWidthInteger>(_ value: T) {
            align(to: T.self)
            withUnsafeBytes(of: T(littleEndian: value)) { bytes in
                result.append(contentsOf: bytes)
            }
        }

        /// Reserves space for an aligned integer of the given type and returns the index where it
        /// should be written later by calling `updateInteger`.
        func appendSection(body: () -> Void) {
            align(to: UInt32.self)
            let nextSectionOffsetIndex = result.endIndex
            for _ in 0..<MemoryLayout<UInt32>.size {
                // Fill it with something other than 0 to help debugging if we need it.
                result.append(0xcc)
            }
            body()
            align(to: UInt32.self)
            updateInteger(at: nextSectionOffsetIndex, to: UInt32(result.count))
        }

        /// Updates an integer in the result buffer at the given index, ensuring that the value is
        /// stored in little endian form.
        func updateInteger<T: BinaryInteger & FixedWidthInteger>(at index: Int, to value: T) {
            withUnsafeBytes(of: T(littleEndian: value)) { bytes in
                result[index..<(index + bytes.count)] = Array(bytes)[...]
            }
        }

        // Build the string blob and index tables.
        var numberToTextOffset: [UInt32: UInt32] = [:]
        var textOffsetToNumber: [NameOffsetKey: UInt32] = [:]
        var jsonOffsetToNumber: [NameOffsetKey: UInt32] = [:]
        var namesBlob: [UInt8] = []
        for number in names.keys.sorted() {
            let namesAndAliases = names[number]!
            for (index, names) in namesAndAliases.enumerated() {
                // Record the offset of the text format name.
                let textOffset = UInt32(namesBlob.count)
                textOffsetToNumber[.init(offset: textOffset, name: names.name)] = number

                // Append the name to the blob.
                namesBlob.append(contentsOf: names.name.utf8)
                namesBlob.append(0)

                // Record the offset of the JSON name and append it to the blob if it's different
                // from the text format name.
                var numberToTextOffsetTag: UInt32 = 0
                if let jsonName = names.jsonName {
                    // If the JSON name is distinct, use the MSB of the offset in the number -> name
                    // offset map to indicate that JSON serialization will need to scan forward to
                    // the next name.
                    numberToTextOffsetTag = 0x8000_0000

                    let jsonOffset = UInt32(namesBlob.count)
                    jsonOffsetToNumber[.init(offset: jsonOffset, name: jsonName)] = number
                    namesBlob.append(contentsOf: jsonName.utf8)
                    namesBlob.append(0)
                }

                // Only record the number -> offset mapping for the primary name (in the case of an
                // enum with aliases).
                if index == 0 {
                    numberToTextOffset[number] = textOffset | numberToTextOffsetTag
                }
            }
        }

        // Add any reserved names to the table.
        for name in reservedNames {
            // Record the offset of the text format name, and use field number 0 (invalid) to
            // indicate that it's a reserved name.
            let textOffset = UInt32(namesBlob.count)
            textOffsetToNumber[.init(offset: textOffset, name: name)] = 0

            // Append the name to the blob.
            namesBlob.append(contentsOf: name.utf8)
            namesBlob.append(0)
        }

        // Split the reserved ranges into those that have a single element and those that are
        // larger.
        var singleElementReservedRanges: [Int32] = []
        var multipleElementReservedRanges: [Range<Int32>] = []
        for range in reservedRanges {
            if range.count == 1 {
                singleElementReservedRanges.append(range.lowerBound)
            } else {
                multipleElementReservedRanges.append(range)
            }
        }
        guard reservedNames.count <= 1 << 16
            && singleElementReservedRanges.count <= 1 << 16
            && multipleElementReservedRanges.count <= 1 << 16
        else {
            // Nobody should ever hit this.
            fatalError(
                """
                The current metadata format only supports a maximum of 2^16 reserved names, \
                2^16 single-element reserved ranges, and 2^16 multi-element reserved ranges.
                """)
        }
        singleElementReservedRanges.sort()
        multipleElementReservedRanges.sort { $0.lowerBound < $1.lowerBound }

        // This section contains bidirectional mappings between numbers and names.
        appendSection {
            // Number of fields with JSON names that differ from their text format counterparts,
            // 16-bit little endian.
            appendInteger(UInt16(jsonOffsetToNumber.count))

            // Number of reserved names, 16-bit little endian.
            appendInteger(UInt16(reservedNames.count))

            // Field/case number to text offset table (UInt32 -> UInt32), in field/case number order.
            // Note that enum values are stored as their unsigned bit-pattern, so the effective sort
            // order is 0...2^31-1, then -2^31...-1. The runtime must therefore perform an unsigned
            // search when looking up enum values.
            for (number, textOffset) in numberToTextOffset.sorted(by: { $0.key < $1.key }) {
                appendInteger(number)
                appendInteger(textOffset)
            }

            // Text format name offset to field/case number (UInt32 -> UInt32), in alphabetical order.
            for (offsetAndName, number) in textOffsetToNumber.sorted(by: { $0.key.name < $1.key.name}) {
                appendInteger(offsetAndName.offset)
                appendInteger(number)
            }

            // JSON format name offset to field/case number (UInt32 -> UInt32), in alphabetical order.
            for (offsetAndName, number) in jsonOffsetToNumber.sorted(by: { $0.key.name < $1.key.name}) {
                appendInteger(offsetAndName.offset)
                appendInteger(number)
            }

            // Name data blob, null-delimited entries.
            result.append(contentsOf: namesBlob)
        }

        // This section contains the reserved field numbers and ranges.
        appendSection {
            // Number of single-element reserved ranges, 16-bit little endian.
            appendInteger(UInt16(singleElementReservedRanges.count))

            // Number of multiple-element reserved ranges, 16-bit little endian.
            appendInteger(UInt16(multipleElementReservedRanges.count))

            // Single-element reserved ranges, in ascending order of the reserved number.
            for number in singleElementReservedRanges {
                appendInteger(number)
            }

            // Multiple-element reserved ranges, in ascending order of the lower bound.
            for range in multipleElementReservedRanges {
                appendInteger(range.lowerBound)
                appendInteger(range.upperBound)
            }
        }

        // TODO: Encode non-zero/non-empty default values.
        return result
    }

    /// Returns the Swift string literal that encodes the compressed table data.
    func stringLiteral() -> String {
        let result = uncompressedData()
        let compressed = Compression.compress(result)
        var literal = ""
        for byte in compressed {
            switch byte {
            case UInt8(ascii: "\0"): literal += "\\0"
            case UInt8(ascii: "\t"): literal += "\\t"
            case UInt8(ascii: "\n"): literal += "\\n"
            case UInt8(ascii: "\r"): literal += "\\r"
            case UInt8(ascii: "\""): literal += "\\\""
            case UInt8(ascii: "\\"): literal += "\\\\"
            case UInt8(ascii: " ")...UInt8(ascii: "~"):
                literal.unicodeScalars.append(UnicodeScalar(byte))
            default:
                literal += "\\u{\(String(byte, radix: 16))}"
            }
        }
        return literal
    }
}
