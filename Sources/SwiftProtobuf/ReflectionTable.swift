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
///
/// ## Reflection Table Layout
///
/// Unlike the message and enum schemas, which use a base-128 encoding to allow them to be packed
/// into UTF-8 `StaticString`s, reflection tables are packed *after* being compressed. This means
/// that the uncompressed table layout, which is described below, can use standard little-endian
/// fixed-size integers.
///
/// The reflection table consists of a sequence of sections. The first 4 bytes of the table contain
/// the offset to the next section (Section 1).
///
/// ### Global Layout
///
/// To support future extensions without breaking ABI, the layout is divided into sections. Each
/// section starts with a 4-byte little-endian integer indicating the offset to the next section.
/// It is possible for a section to be empty (the offset to the next section will simply be the
/// current offset + 4).
///
/// ```
/// +-------------------+
/// | Bytes 0-3         |
/// | Offset to Sec 1   |
/// +-------------------+
/// | Section 0 Data    |
/// | ...               |
/// +-------------------+
/// | Section 1 Header  |
/// | (Offset to Sec 2) |
/// +-------------------+
/// | Section 1 Data    |
/// | ...               |
/// +-------------------+
/// ```
///
/// ### Section 0 Layout
///
/// Section 0 contains the main reflection data (names and numbers). Offsets are all relative to the
/// beginning of the section.
///
/// ```
/// +---------------------+---------------------+-----------------+-------------+-----------------+
/// | Bytes 0-1           | Bytes 2-3           | Bytes 4-5       | Bytes 6-7   | Bytes 8...      |
/// | Distinct JSON count | Reserved name count | Text name count | (Padding)   | Tables and text |
/// +---------------------+---------------------+-----------------+-------------+-----------------+
/// ```
///
/// *   **Distinct JSON count**: The number of fields whose JSON names differ from their text format
///     names.
/// *   **Reserved name count**: The number of reserved names.
/// *   **Text name count**: The total count of entries in the text name to number table.
///
/// Following the header are the tables and the name data blob:
///
/// *   **Field number to text offset table** (size: `fieldCount * 8` bytes): A sequence of pairs of
///     `UInt32` values `[FieldNumber, TaggedTextOffset]`. The `TaggedTextOffset` is an offset into
///     the name data blob. Its high bit indicates whether the field has a distinct JSON name (1) or
///     not (0).
/// *   **Text offset to field number table** (size: `textNameTableCount * 8` bytes): A sequence of
///     pairs of `UInt32` values `[TextOffset, FieldNumber]`. This table is sorted by the string
///     value at `TextOffset` to allow binary search.
/// *   **JSON name offset to field number table** (size: `distinctJSONNameCount * 8` bytes): A
///     sequence of pairs of `UInt32` values `[JSONOffset, FieldNumber]`. This table is sorted by
///     the string value at `JSONOffset` to allow binary search.
/// *   **Name data blob**: A sequence of null-terminated UTF-8 strings containing the field names.
///
/// ### Section 1 Layout
///
/// Section 1 contains reserved field numbers.
///
/// ```
/// +----------------------+---------------------+------------+
/// | Bytes 0-1            | Bytes 2-3           | Bytes 4... |
/// | Single element count | Multi-element count | Ranges     |
/// +----------------------+---------------------+------------+
/// ```
///
/// *   **Single element count**: The number of single-element reserved ranges.
/// *   **Multi element count**: The number of multi-element reserved ranges.
/// *   **Ranges**: The data area containing the reserved field numbers, split into two parts:
///     1. **Single-element ranges** (`singleCount * 4` bytes): A sequence of `UInt32` values
///        representing individual reserved field numbers.
///     2. **Multi-element ranges** (`multiCount * 8` bytes): A sequence of pairs of `UInt32`
///        values `[LowerBound, UpperBound]`. Each pair represents a range of reserved field
///        numbers from `LowerBound` (inclusive) up to `UpperBound` (exclusive).
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

/// The offset of the data in the first section of the reflection table (which is simply the first
/// byte after the initial `UInt32` offset to the next section).
private let firstSectionStart = MemoryLayout<UInt32>.size

/// Loads a little-endian `UInt16` from the given buffer at the specified offset.
@inline(__always)
private func loadUInt16(from bytes: UnsafeRawBufferPointer, at offset: Int) -> UInt16 {
    UInt16(littleEndian: bytes.load(fromByteOffset: offset, as: UInt16.self))
}

/// Loads a little-endian `UInt32` from the given buffer at the specified offset.
@inline(__always)
private func loadUInt32(from bytes: UnsafeRawBufferPointer, at offset: Int) -> UInt32 {
    UInt32(littleEndian: bytes.load(fromByteOffset: offset, as: UInt32.self))
}

extension ReflectionTable {
    /// Returns the text name for the given field number.
    package func textName(forFieldNumber fieldNumber: UInt32) -> String? {
        guard let offset = taggedTextOffset(forFieldNumber: fieldNumber) else { return nil }
        return name(at: offset)
    }

    /// Returns the text name for the given enum case.
    package func textName(forEnumCase enumCase: Int32) -> String? {
        textName(forFieldNumber: UInt32(bitPattern: enumCase))
    }

    /// Returns the JSON name for the given field number.
    package func jsonName(forFieldNumber fieldNumber: UInt32) -> String? {
        guard let offset = taggedTextOffset(forFieldNumber: fieldNumber) else { return nil }
        return secondName(at: offset)
    }

    /// Returns the JSON name for the given enum case.
    package func jsonName(forEnumCase enumCase: Int32) -> String? {
        jsonName(forFieldNumber: UInt32(bitPattern: enumCase))
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
        // Use a linear search for now since the number of reserved fields is likely small and this
        // will only be hit if we see a field number we don't recognize in text format parsing. If
        // this ever shows up as a bottleneck, we can dynamically choose a binary search or linear
        // search based on a threshold in the future.
        precondition(data.count >= firstSectionStart, "malformed reflection data")
        let bounds = sectionBounds(forSection: 1)
        let sectionStart = bounds.start
        let sectionEnd = bounds.end

        // Fast path: Section is empty (no reserved numbers)
        guard sectionEnd != sectionStart else {
            return false
        }

        return data.withUnsafeBytes { bytes in
            let singleCount = Int(loadUInt16(from: bytes, at: sectionStart))
            let multiCount = Int(loadUInt16(from: bytes, at: sectionStart &+ MemoryLayout<UInt16>.size))
            let currentOffset = sectionStart &+ 2 &* MemoryLayout<UInt16>.size

            // Single-element ranges
            guard currentOffset &+ singleCount &* MemoryLayout<UInt32>.size <= sectionEnd else { return false }
            for i in 0..<singleCount {
                let offset = currentOffset &+ i &* MemoryLayout<UInt32>.size
                if loadUInt32(from: bytes, at: offset) == number {
                    return true
                }
            }

            // Multi-element ranges
            let multiStart = currentOffset &+ singleCount &* MemoryLayout<UInt32>.size
            guard multiStart &+ multiCount &* (2 &* MemoryLayout<UInt32>.size) <= sectionEnd else { return false }
            for i in 0..<multiCount {
                let offset = multiStart &+ i &* 2 &* MemoryLayout<UInt32>.size
                let lower = loadUInt32(from: bytes, at: offset)
                let upper = loadUInt32(from: bytes, at: offset &+ MemoryLayout<UInt32>.size)
                if number >= lower && number < upper {
                    return true
                }
            }

            return false
        }
    }

    /// Returns true if the given name is reserved.
    package func isNameReserved(_ name: String) -> Bool {
        let fieldTableSize = fieldCount &* 2 &* MemoryLayout<UInt32>.size
        return number(
            for: name,
            inTableStartingAt: 3 &* MemoryLayout<UInt32>.size &+ fieldTableSize,
            count: textNameTableCount
        ) == 0
    }

    /// Returns the bounds of the given section.
    ///
    /// - Parameter index: The zero-based index of the section.
    /// - Returns: A tuple containing the start offset of the section data and the end offset.
    private func sectionBounds(forSection index: Int) -> (start: Int, end: Int) {
        precondition(index >= 0, "Invalid section index")

        return data.withUnsafeBytes { bytes in
            if index == 0 {
                let start = firstSectionStart
                let end = Int(loadUInt32(from: bytes, at: 0))
                return (start, end)
            }

            var currentOffset = 0  // Start at Section 1 header at byte 0
            for _ in 0..<index {
                currentOffset = Int(loadUInt32(from: bytes, at: currentOffset))
            }

            let start = currentOffset &+ MemoryLayout<UInt32>.size
            let end = Int(loadUInt32(from: bytes, at: currentOffset))
            return (start, end)
        }
    }
}

extension ReflectionTable {
    /// Returns the count of fields with distinct JSON names (i.e., that differ from
    /// their text names).
    @inline(__always) @_alwaysEmitIntoClient
    private var distinctJSONNameCount: Int {
        data.withUnsafeBytes { bytes in
            Int(loadUInt16(from: bytes, at: firstSectionStart))
        }
    }

    /// Returns the count of reserved names.
    @inline(__always) @_alwaysEmitIntoClient
    private var reservedNameCount: Int {
        data.withUnsafeBytes { bytes in
            Int(loadUInt16(from: bytes, at: firstSectionStart &+ 2))
        }
    }

    /// Returns the total count of entries in the text name to number table.
    @inline(__always) @_alwaysEmitIntoClient
    private var textNameTableCount: Int {
        data.withUnsafeBytes { bytes in
            Int(loadUInt16(from: bytes, at: firstSectionStart &+ 4))
        }
    }

    /// The offset of the name table within the reflection data.
    @inline(__always) @_alwaysEmitIntoClient
    private var nameTableOffset: Int {
        3 &* MemoryLayout<UInt32>.size
            &+ 2 &* fieldCount &* MemoryLayout<UInt32>.size
            &+ 2 &* textNameTableCount &* MemoryLayout<UInt32>.size
            &+ 2 &* distinctJSONNameCount &* MemoryLayout<UInt32>.size
    }

    /// Returns the field or enum case number associated with the given text name.
    private func rawNumber(forTextName name: String) -> UInt32? {
        let fieldTableSize = fieldCount &* 2 &* MemoryLayout<UInt32>.size
        return number(
            for: name,
            inTableStartingAt: 3 &* MemoryLayout<UInt32>.size &+ fieldTableSize,
            count: textNameTableCount
        )
    }

    /// Returns the field or enum case number associated with the given JSON name.
    private func rawNumber(forJSONName name: String) -> UInt32? {
        let fieldTableSize = fieldCount &* 2 &* MemoryLayout<UInt32>.size
        let textTableSize = textNameTableCount &* 2 &* MemoryLayout<UInt32>.size
        return number(
            for: name,
            inTableStartingAt: 3 &* MemoryLayout<UInt32>.size &+ fieldTableSize &+ textTableSize,
            count: distinctJSONNameCount
        )
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
            var high = fieldCount &- 1

            while low <= high {
                let mid = (low &+ high) / 2
                let bounds = sectionBounds(forSection: 0)
                let offset = bounds.start &+ 2 &* MemoryLayout<UInt32>.size &+ mid &* (2 &* MemoryLayout<UInt32>.size)
                let currentNumber = loadUInt32(from: bytes, at: offset)

                if currentNumber == fieldNumber {
                    return loadUInt32(from: bytes, at: offset &+ MemoryLayout<UInt32>.size)
                } else if currentNumber < fieldNumber {
                    low = mid &+ 1
                } else {
                    high = mid &- 1
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
            var high = count &- 1

            while low <= high {
                let mid = (low &+ high) / 2
                let entryOffset = tableStart &+ mid &* (2 &* MemoryLayout<UInt32>.size)
                let stringOffset = loadUInt32(from: bytes, at: entryOffset)

                let currentName = self.name(at: stringOffset)

                if currentName == name {
                    return loadUInt32(from: bytes, at: entryOffset &+ MemoryLayout<UInt32>.size)
                } else if currentName < name {
                    low = mid &+ 1
                } else {
                    high = mid &- 1
                }
            }
            return nil
        }
    }

    /// Returns the string at the given offset in the name table.
    private func name(at taggedOffset: UInt32) -> String {
        let offset = taggedOffset & 0x7fff_ffff
        let start = nameTableOffset &+ Int(offset)
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
        let start = nameTableOffset &+ Int(offset)
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
                56, 0, 0, 0,  // Offset to Section 1
                0, 0,         // distinctJSONNameCount (0)
                0, 0,         // reservedNameCount (0)
                2, 0,         // textNameTableCount (2)
                0, 0,         // Padding
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
                60, 0, 0, 0,  // Offset of Section 2
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
