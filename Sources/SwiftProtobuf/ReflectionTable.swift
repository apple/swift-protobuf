// Sources/SwiftProtobuf/ReflectionTable.swift - Reflection data table
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Manages access to the reflection data for a message or enum (its names and
/// default values).
///
// -----------------------------------------------------------------------------

import Foundation

/// Provides access to the reflection data embedded in a generated message or enum.
package struct ReflectionTable: Sendable {
    /// The number of fields in the owning message.
    private let fieldCount: Int

    /// The raw reflection data for the message or enum.
    ///
    /// This data may come from a variety of sources: in the case of generated messages/enums, it is
    /// a compressed data blob that is uncompressed and cached on demand. For map entries, it is
    /// embedded directly into a static stored property. A future version of this library could
    /// support reflection by generating this from a descriptor provided by the client. In all
    /// cases, the data is immutable so passing around these tables should be a lightweight
    /// operation.
    private let data: [UInt8]

    /// Creates a new reflection table from the given raw data.
    package init(fieldCount: Int, data: [UInt8]) {
        self.fieldCount = fieldCount
        self.data = data
    }
}

// TODO: Add APIs to read default values.

extension ReflectionTable {
    /// Returns the text name for the given field number.
    package func textName(forFieldNumber fieldNumber: UInt32) -> String? {
        guard let offset = taggedTextOffset(forFieldNumber: fieldNumber) else { return nil }
        return name(at: offset)
    }

    /// Returns the text name for the given enum case.
    package func textName(forEnumCase enumCase: Int32) -> String? {
        return textName(forFieldNumber: UInt32(bitPattern: enumCase))
    }

    /// Returns the JSON name for the given field number.
    package func jsonName(forFieldNumber fieldNumber: UInt32) -> String? {
        guard let offset = taggedTextOffset(forFieldNumber: fieldNumber) else { return nil }
        return secondName(at: offset)
    }

    /// Returns the JSON name for the given enum case.
    package func jsonName(forEnumCase enumCase: Int32) -> String? {
        return jsonName(forFieldNumber: UInt32(bitPattern: enumCase))
    }

    /// Returns the field number with the given text name.
    package func fieldNumber(forTextName name: String) -> UInt32? {
        number(for: name, inTableStartingAt: 8 + fieldCount * 8, count: fieldCount)
    }

    /// Returns the enum case with the given text name.
    package func enumCase(forTextName name: String) -> Int32? {
        guard let number = fieldNumber(forTextName: name) else { return nil }
        return Int32(bitPattern: number)
    }

    /// Returns the field number with the given JSON name.
    package func fieldNumber(forJSONName name: String) -> UInt32? {
        number(for: name, inTableStartingAt: 8 + fieldCount * 16, count: distinctJSONNameCount)
            ?? fieldNumber(forTextName: name)
    }

    /// Returns the enum case with the given JSON name.
    package func enumCase(forJSONName name: String) -> Int32? {
        guard let number = fieldNumber(forJSONName: name) else { return nil }
        return Int32(bitPattern: number)
    }
}

extension ReflectionTable {
    /// Returns the count of fields with distinct JSON names (i.e., that differ from
    /// their text names).
    @inline(__always) @_alwaysEmitIntoClient
    private var distinctJSONNameCount: Int {
        data.withUnsafeBytes { bytes in
            Int(bytes.load(fromByteOffset: 4, as: UInt32.self))
        }
    }

    /// The offset of the name table within the reflection data.
    @inline(__always) @_alwaysEmitIntoClient
    private var nameTableOffset: Int {
        2 * MemoryLayout<UInt32>.size
            + 4 * fieldCount * MemoryLayout<UInt32>.size
            + 2 * distinctJSONNameCount * MemoryLayout<UInt32>.size
    }

    /// Returns the offset of the text name for the given field number.
    ///
    /// The returned offset is "tagged" so that the high bit indicates whether the
    /// corresponding JSON name is distinct from the text name (if the high bit is 0,
    /// the JSON name is the same as the text name; if 1, it is different).
    private func taggedTextOffset(forFieldNumber fieldNumber: UInt32) -> UInt32? {
        guard fieldCount > 0 else { return nil }
        return data.withUnsafeBytes { bytes in
            var low = 0
            var high = fieldCount - 1

            while low <= high {
                let mid = (low + high) / 2
                let offset = 8 + mid * 8
                let currentNumber = bytes.load(fromByteOffset: offset, as: UInt32.self)

                if currentNumber == fieldNumber {
                    return bytes.load(fromByteOffset: offset + 4, as: UInt32.self)
                } else if currentNumber < fieldNumber {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            return nil
        }
    }

    /// Returns the field number for a name, looking in the given table.
    private func number(for name: String, inTableStartingAt tableStart: Int, count: Int) -> UInt32? {
        guard count > 0 else { return nil }
        return data.withUnsafeBytes { bytes in
            var low = 0
            var high = count - 1

            while low <= high {
                let mid = (low + high) / 2
                let entryOffset = tableStart + mid * 8
                let stringOffset = bytes.load(fromByteOffset: entryOffset, as: UInt32.self)

                let currentName = self.name(at: stringOffset)

                if currentName == name {
                    return bytes.load(fromByteOffset: entryOffset + 4, as: UInt32.self)
                } else if currentName < name {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            return nil
        }
    }

    /// Returns the string at the given offset in the name table.
    private func name(at taggedOffset: UInt32) -> String {
        let offset = taggedOffset & 0x7fff_ffff
        let start = nameTableOffset + Int(offset)
        return data.withUnsafeBytes { bytes in
            let base = bytes.baseAddress!.assumingMemoryBound(to: CChar.self)
            return String(cString: base + start)
        }
    }

    /// Returns the string at the given offset in the name table.
    private func secondName(at taggedOffset: UInt32) -> String {
        guard taggedOffset & 0x8000_0000 != 0 else {
            return name(at: taggedOffset)
        }
        let offset = taggedOffset & 0x7fff_ffff
        let start = nameTableOffset + Int(offset)
        return data.withUnsafeBytes { bytes in
            let base = bytes.baseAddress!.assumingMemoryBound(to: CChar.self)
            var p = base + start
            while p.pointee != 0 {
                p += 1
            }
            return String(cString: p + 1)
        }
    }
}

extension ReflectionTable {
    /// The fixed reflection table for the pseudo-message used to represent map entries.
    package static let mapEntry: ReflectionTable = {
        ReflectionTable(
            fieldCount: 2,
            data: [
                52, 0, 0, 0,  // Offset of default values section (unused)
                0, 0, 0, 0,  // Number of fields with distinct JSON names (0)
                // Field number to text offset table
                1, 0, 0, 0,  // field 1
                0, 0, 0, 0,  // offset 0
                2, 0, 0, 0,  // field 2
                4, 0, 0, 0,  // offset 4
                // Text offset to field number table (sorted by name)
                0, 0, 0, 0,  // offset 0 ("key")
                1, 0, 0, 0,  // field 1
                4, 0, 0, 0,  // offset 4 ("value")
                2, 0, 0, 0,  // field 2
                // Name data blob (null terminated)
                UInt8(ascii: "k"), UInt8(ascii: "e"), UInt8(ascii: "y"), 0,
                UInt8(ascii: "v"), UInt8(ascii: "a"), UInt8(ascii: "l"), UInt8(ascii: "u"),
                UInt8(ascii: "e"), 0,
                // Alignment padding
                0, 0,
            ]
        )
    }()
}

/// A reflection table that is lazily decompressed when first accessed.
final class LazyReflectionTable {
    private enum State {
        case compressed(UnsafeRawBufferPointer, fieldCount: Int)
        case decompressed(ReflectionTable)
    }

    /// Guards `state`.
    private let lock = NSLock()

    /// Whether the table is a compressed buffer or decompressed table.
    private var state: State

    /// Initializes the lazy reflection table with a buffer to be decompressed the first time it is
    /// requested.
    init(compressed: UnsafeRawBufferPointer, fieldCount: Int) {
        self.state = .compressed(compressed, fieldCount: fieldCount)
    }

    /// Initializes the lazy reflection table wrapper with an already decompressed table.
    init(decompressed: ReflectionTable) {
        self.state = .decompressed(decompressed)
    }

    /// The reflection table, decompressed for the first time if needed.
    var table: ReflectionTable {
        lock.withLock {
            switch state {
            case .decompressed(let table):
                return table

            case .compressed(let buffer, let fieldCount):
                let table = ReflectionTable(
                    fieldCount: fieldCount,
                    data: Compression.decompress(buffer)
                )
                state = .decompressed(table)
                return table
            }
        }
    }
}
