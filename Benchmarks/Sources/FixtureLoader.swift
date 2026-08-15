// Benchmarks/Sources/FixtureLoader.swift - length-delimited .pb fixture loader
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

/// Reads a stream of length-delimited protobuf messages into their raw bytes.
///
/// The fixture files are checked in rather than synthesized, so that every baseline
/// decodes byte-identical input. This loader is hand-rolled instead of `BinaryDelimited`.
/// That API is behind a package trait and differs between the baselines we compare. Its
/// use would make the loader itself part of what we measure.
enum FixtureLoader {
    static func load(from url: URL) throws -> [[UInt8]] {
        let fileData = try Data(contentsOf: url)
        var messages: [[UInt8]] = []
        var offset = 0
        while offset < fileData.count {
            var length: UInt64 = 0
            var shift: UInt64 = 0
            while offset < fileData.count {
                let byte = fileData[offset]
                offset += 1
                length |= UInt64(byte & 0x7F) << shift
                if byte & 0x80 == 0 { break }
                shift += 7
            }
            let msgLen = Int(length)
            guard offset + msgLen <= fileData.count else { break }
            messages.append(Array(fileData[offset..<offset + msgLen]))
            offset += msgLen
        }
        return messages
    }

    /// Loads a fixture by name from `Benchmarks/fixtures/`.
    ///
    /// Resolved from `#filePath` rather than the working directory so the harness
    /// runs correctly no matter where the driver invokes it from.
    static func named(_ filename: String) throws -> [[UInt8]] {
        let here = URL(filePath: #filePath).deletingLastPathComponent()
        let benchmarksDir = here.appending(path: "..").standardizedFileURL
        return try load(from: benchmarksDir.appending(path: "fixtures/\(filename)"))
    }
}
