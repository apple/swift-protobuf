// Sources/SwiftProtobuf/MapEntryWorkingSpace.swift - Temporary storage cache for map entries
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Manages temporary message storage objects used to encode and decode map
/// entries.
///
// -----------------------------------------------------------------------------

/// Manages temporary message storage objects used to encode and decode map entries.
///
/// Map entries are represented on the wire as messages with two fields -- the key and the value.
/// We don't want to generate full message types for these because they would be mostly bloat. The
/// key observation is that we still store maps as Swift `Dictionary`s in memory; the message
/// representation is only used when encoding/decoding.
///
/// To minimize unnecessary allocations, the encode/decode loop for a message creates an instance
/// of this type to maintain a cache of `_MessageStorage` objects that it uses as temporary
/// workspace before/after transferring the key and value into/out of the dictionary. This allows
/// map entry serialization to be implemented in essentially the same fashion as other types.
struct MapEntryWorkingSpace {
    /// The layout of the message that contains the map field being encoded/decoded.
    private let ownerLayout: _MessageLayout

    /// The cache of `_MessageStorage` objects used for the map entries in this message.
    private var entryStorage: [Int: _MessageStorage]

    /// Creates a new map entry working space for the message with the given layout.
    init(ownerLayout: _MessageLayout) {
        self.ownerLayout = ownerLayout
        self.entryStorage = [:]
    }

    /// Returns the `_MessageStorage` used to encode/decode map entries with the given trampoline
    /// index, creating it if necessary.
    mutating func storage(for trampolineIndex: Int) -> _MessageStorage {
        if let storage = entryStorage[trampolineIndex] {
            return storage
        }

        // It didn't already exist, so create it and cache it.
        let storage = _MessageStorage(
            layout: ownerLayout.mapEntryLayout(_MessageLayout.TrampolineToken(index: trampolineIndex))
        )
        entryStorage[trampolineIndex] = storage
        return storage
    }
}
