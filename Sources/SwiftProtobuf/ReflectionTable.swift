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
        let num = rawNumber(forTextName: name)
        // We might hit a reserved name with a number of 0, so convert that to nil.
        return num == 0 ? nil : num
    }

    /// Returns the enum case with the given text name.
    package func enumCase(forTextName name: String) -> Int32? {
        rawNumber(forTextName: name).map(Int32.init(bitPattern:))
    }

    /// Returns the field number with the given JSON name.
    package func fieldNumber(forJSONName name: String) -> UInt32? {
        let num = rawNumber(forJSONName: name) ?? fieldNumber(forTextName: name)
        // We might hit a reserved name with a number of 0, so convert that to nil.
        return num == 0 ? nil : num
    }

    /// Returns the enum case with the given JSON name.
    package func enumCase(forJSONName name: String) -> Int32? {
        guard let number = rawNumber(forJSONName: name) ?? rawNumber(forTextName: name) else { return nil }
        return Int32(bitPattern: number)
    }
}

extension ReflectionTable {
    /// Returns true if the given field number is reserved.
    package func isNumberReserved(_ number: UInt32) -> Bool {
        guard data.count >= 4 else { return false }
        let section2Offset = data.withUnsafeBytes { bytes in
            Int(bytes.load(fromByteOffset: 0, as: UInt32.self))
        }
        guard section2Offset > 0 && section2Offset < data.count else { return false }
        
        return data.withUnsafeBytes { bytes in
            let endOffset = Int(bytes.load(fromByteOffset: section2Offset, as: UInt32.self))
            if endOffset - section2Offset <= 8 {
                return false // Fast path: Section 2 is empty
            }

            let dataStart = section2Offset + 4
            guard dataStart + 4 <= data.count else { return false }
            
            let singleCount = Int(bytes.load(fromByteOffset: dataStart, as: UInt16.self))
            let multiCount = Int(bytes.load(fromByteOffset: dataStart + 2, as: UInt16.self))
            
            let currentOffset = dataStart + 4
            
            // Single-element ranges (Binary Search)
            guard currentOffset + singleCount * 4 <= data.count else { return false }
            var low = 0
            var high = singleCount - 1
            while low <= high {
                let mid = (low + high) / 2
                let offset = currentOffset + mid * 4
                let reservedNumber = bytes.load(fromByteOffset: offset, as: Int32.self)
                let uReserved = UInt32(bitPattern: reservedNumber)
                
                if uReserved == number {
                    return true
                } else if uReserved < number {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }

            // Multi-element ranges (Binary Search)
            let multiStart = currentOffset + singleCount * 4
            guard multiStart + multiCount * 8 <= data.count else { return false }
            low = 0
            high = multiCount - 1
            var candidateIndex = -1

            while low <= high {
                let mid = (low + high) / 2
                let offset = multiStart + mid * 8
                let lower = bytes.load(fromByteOffset: offset, as: Int32.self)
                let uLower = UInt32(bitPattern: lower)

                if uLower <= number {
                    candidateIndex = mid
                    low = mid + 1 // Look for a larger lower bound
                } else {
                    high = mid - 1
                }
            }

            if candidateIndex != -1 {
                let offset = multiStart + candidateIndex * 8
                let upper = bytes.load(fromByteOffset: offset + 4, as: Int32.self)
                let uUpper = UInt32(bitPattern: upper)
                if number < uUpper {
                    return true
                }
            }

            return false
        }
    }

    /// Returns true if the given name is reserved.
    package func isNameReserved(_ name: String) -> Bool {
        guard reservedNameCount > 0 else { return false } // Fast path
        return number(for: name, inTableStartingAt: 8 + fieldCount * 8, count: fieldCount + reservedNameCount) == 0
    }
}

extension ReflectionTable {
    /// Returns the count of fields with distinct JSON names (i.e., that differ from
    /// their text names).
    @inline(__always) @_alwaysEmitIntoClient
    private var distinctJSONNameCount: Int {
        data.withUnsafeBytes { bytes in
            Int(bytes.load(fromByteOffset: 4, as: UInt16.self))
        }
    }

    /// Returns the count of reserved names.
    @inline(__always) @_alwaysEmitIntoClient
    private var reservedNameCount: Int {
        data.withUnsafeBytes { bytes in
            Int(bytes.load(fromByteOffset: 6, as: UInt16.self))
        }
    }

    /// The offset of the name table within the reflection data.
    @inline(__always) @_alwaysEmitIntoClient
    private var nameTableOffset: Int {
        2 * MemoryLayout<UInt32>.size
            + 2 * fieldCount * MemoryLayout<UInt32>.size
            + 2 * (fieldCount + reservedNameCount) * MemoryLayout<UInt32>.size
            + 2 * distinctJSONNameCount * MemoryLayout<UInt32>.size
    }

    /// Returns the field or enum case number associated with the given text name.
    private func rawNumber(forTextName name: String) -> UInt32? {
        number(for: name, inTableStartingAt: 8 + fieldCount * 8, count: fieldCount + reservedNameCount)
    }

    /// Returns the field or enum case number associated with the given JSON name.
    private func rawNumber(forJSONName name: String) -> UInt32? {
        number(for: name, inTableStartingAt: 8 + fieldCount * 16, count: distinctJSONNameCount)
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
                52, 0, 0, 0,  // Offset of reserved numbers section (unused)
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
                56, 0, 0, 0,  // Offset of default values section (unused)
            ]
        )
    }()
}

/// A reference to a reflection table, which may be inlined (embedded in the generated code) or
/// stored as a compressed buffer.
enum ReflectionTableReference: @unchecked Sendable {
    /// A compressed reflection table stored as a static string in generated code.
    /// 
    /// The pointer to the compressed data is used as a unique key to reference the table.
    case compressed(UnsafeRawBufferPointer, fieldCount: Int)

    /// Refers to a reflection table that already exists at the time a message/enum schema is
    /// created.
    ///
    /// This is used for map entry pseudo-messages, which have a fixed reflection table shared
    /// across all map entries.
    case direct(ReflectionTable)

    /// Returns the reflection table, decompressing it if necessary.
    var table: ReflectionTable {
        switch self {
        case .compressed(let buffer, let fieldCount):
            // TODO: Move this to a cache instead of decompressing every time.
            let decompressed = Compression.decompress(buffer)
            return ReflectionTable(fieldCount: fieldCount, data: decompressed)
        case .direct(let table):
            return table
        }
    }
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
