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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A reference to a reflection table, which may be inlined (embedded in the generated code) or
/// stored as a compressed buffer.
final class ReflectionTableReference: @unchecked Sendable {
    private enum State {
        case compressed(UnsafeRawBufferPointer, fieldCount: Int)
        case direct(ReflectionTable)
    }

    /// A singleton instance that references the fixed reflection table for map entries.
    static let mapEntry: ReflectionTableReference = .init(direct: .mapEntry)

    /// Guards `state`.
    private let lock = NSLock()

    /// The state of the table, either compressed or decompressed.
    private var state: State

    /// Creates a new reflection table reference from a compressed buffer.
    ///
    /// The pointer to the compressed data is assumed to be immortal (either static data in
    /// the binary or allocated in a pool that lives for the lifetime of the reference).
    init(compressed: UnsafeRawBufferPointer, fieldCount: Int) {
        self.state = .compressed(compressed, fieldCount: fieldCount)
    }

    /// Creates a new reference to an existing reflection table.
    private init(direct table: ReflectionTable) {
        self.state = .direct(table)
    }

    /// Calls the given body with the reflection table, decompressing it on the
    /// first call if needed.
    func withTable<R>(_ body: (borrowing ReflectionTable) throws -> R) rethrows -> R {
        try lock.withLock {
            switch state {
            case .direct(let table):
                return try body(table)

            case .compressed(let buffer, let fieldCount):
                let table = ReflectionTable(
                    fieldCount: fieldCount,
                    data: Compression.decompress(buffer)
                )
                state = .direct(table)
                return try body(table)
            }
        }
    }
}
