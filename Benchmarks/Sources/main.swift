// Benchmarks/Sources/main.swift - (de)serialization wall-clock benchmarks
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Measures binary decode and encode against real-world message shapes. Built once
/// per baseline by `run.py`, which links it against a chosen swift-protobuf checkout
/// and sets `SP_BASELINE` to name the result.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

/// Decodes every fixture once per batch.
func benchDecode<M: SwiftProtobuf.Message>(
    _ type: M.Type,
    fixtures: [[UInt8]]
) throws -> Measurement {
    try measure(opsPerBatch: fixtures.count) {
        for bytes in fixtures {
            _ = try M(serializedBytes: bytes)
        }
    }
}

/// Encodes every fixture once per batch. The messages are decoded first, so decoding
/// is not part of the encode number.
func benchEncode<M: SwiftProtobuf.Message>(
    _ type: M.Type,
    fixtures: [[UInt8]]
) throws -> Measurement {
    let messages = try fixtures.map { try M(serializedBytes: $0) }
    return try measure(opsPerBatch: messages.count) {
        for message in messages {
            _ = try message.serializedBytes() as [UInt8]
        }
    }
}

/// Fails the run before timing if the baseline cannot round-trip the fixtures.
/// A decoder that silently drops fields would otherwise look fast.
func gateRoundTrip<M: SwiftProtobuf.Message & Equatable>(
    _ type: M.Type,
    fixtures: [[UInt8]]
) throws {
    for (index, bytes) in fixtures.enumerated() {
        let message = try M(serializedBytes: bytes)
        let reencoded: [UInt8] = try message.serializedBytes()
        let roundTripped = try M(serializedBytes: reencoded)
        guard roundTripped == message else {
            fatalError("\(M.self) round-trip mismatch at fixture \(index)")
        }
    }
}

func run<M: SwiftProtobuf.Message & Equatable>(
    _ type: M.Type,
    named name: String,
    fixtures: [[UInt8]]
) throws {
    try gateRoundTrip(type, fixtures: fixtures)
    report(type: name, op: "decode", messages: fixtures.count, try benchDecode(type, fixtures: fixtures))
    report(type: name, op: "encode", messages: fixtures.count, try benchEncode(type, fixtures: fixtures))
}

// MARK: - CatalogEntry (~80 fields: scalars, enums, submessages, repeated, strings)

let catalogFixtures = try FixtureLoader.named("catalog_entries.pb")
precondition(!catalogFixtures.isEmpty, "catalog_entries.pb produced no messages")
try run(Benchmarks_CatalogEntry.self, named: "CatalogEntry", fixtures: catalogFixtures)

// MARK: - Per-field-type breakdown

// You can skip this. The real-world workload is the one to watch most of the time.
// The synthetic sweep adds 21 more workloads.
if ProcessInfo.processInfo.environment["SP_SKIP_SYNTHETIC"] == nil {
    try runSyntheticWorkloads()
}
