// Sources/SwiftProtobuf/ReflectionTableReference.swift - Reflection table reference
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A self-caching reference to a reflection table that may have been
/// compressed in a `StaticString` in generated code.
///
// -----------------------------------------------------------------------------

/// A reference to a reflection table, which may be inlined (embedded in the generated code) or
/// stored as a compressed buffer.
final class ReflectionTableReference: @unchecked Sendable {
    /// The compressed reflection table data, if any.
    private let compressed: UnsafeRawBufferPointer?

    /// The number of fields in the message whose reflection table is being referenced.
    private let fieldCount: Int

    /// A singleton instance that references the fixed reflection table for map entries.
    static let mapEntry: ReflectionTableReference = .init(direct: .mapEntry)

    /// Guards `cachedTable` during decompression.
    private let lock = Lock()

    /// The cached decompressed reflection table.
    private var cachedTable: ReflectionTable?

    /// Creates a new reflection table reference from a compressed buffer.
    ///
    /// The pointer to the compressed data is assumed to be immortal (either static data in
    /// the binary or allocated in a pool that lives for the lifetime of the reference).
    init(compressed: UnsafeRawBufferPointer, fieldCount: Int) {
        self.compressed = compressed
        self.fieldCount = fieldCount
        self.cachedTable = nil
    }

    /// Creates a new reference to an existing reflection table.
    private init(direct table: ReflectionTable) {
        self.compressed = nil
        self.fieldCount = 0
        self.cachedTable = table
    }

    /// Calls the given body with the reflection table, decompressing it on the
    /// first call if needed.
    func withTable<R>(_ body: (borrowing ReflectionTable) throws -> R) rethrows -> R {
        try lock.withLock {
            if let table = cachedTable {
                return try body(table)
            }

            guard let compressed else {
                fatalError("Corrupted state: compressed buffer missing")
            }

            let table = ReflectionTable(
                fieldCount: fieldCount,
                data: Compression.decompress(compressed)
            )
            cachedTable = table
            return try body(table)
        }
    }
}
