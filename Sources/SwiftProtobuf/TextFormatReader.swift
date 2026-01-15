// Sources/SwiftProtobuf/TextFormatReader.swift - Text format reader
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// High-level wrapper around `TextFormatScanner`.
///
// -----------------------------------------------------------------------------

import Foundation

/// This type is a high-level wrapper around `TextFormatScanner`. It is the analogue of
/// `TextFormatDecoder` from the old implementation, but without the `Decoder` infrastructure that
/// we'll be deleting. Once that refactoring is complete, we should consider whether it makes sense
/// to merge this with `TextFormatScanner` instead of keeping them separate.
struct TextFormatReader {
    var scanner: TextFormatScanner
    private var nameMap: _NameMap
    private var hasSeenField = false
    private let terminator: UInt8?

    var options: TextFormatDecodingOptions { scanner.options }

    var complete: Bool { scanner.complete }

    /// Creates a new text format reader.
    ///
    /// - Precondition: `buffer.baseAddress` is not nil.
    internal init(
        buffer: UnsafeBufferPointer<UInt8>,
        nameMap: _NameMap,
        options: TextFormatDecodingOptions,
        extensions: (any ExtensionMap)?
    ) {
        self.init(
            scanner: TextFormatScanner(
                utf8Pointer: buffer.baseAddress!,
                count: buffer.count,
                options: options,
                extensions: extensions
            ),
            nameMap: nameMap,
            terminator: nil
        )
    }

    private init(
        scanner: TextFormatScanner,
        nameMap: _NameMap,
        terminator: UInt8?
    ) {
        self.scanner = scanner
        self.nameMap = nameMap
        self.terminator = terminator
    }

    /// Parses and returns the number of the next field in the text format string, or nil if the
    /// end of the input was reached.
    mutating func nextFieldNumber() throws -> UInt32? {
        if hasSeenField {
            scanner.skipOptionalSeparator()
        }
        // TODO: Remove the `messageType` argument from the scanner.
        guard let fieldNumber = try scanner.nextFieldNumber(names: nameMap, messageType: nil, terminator: terminator)
        else {
            return nil
        }
        hasSeenField = true
        return UInt32(fieldNumber)
    }

    /// Creates a new `TextFormatReader` that is configured to start reading the object at the
    /// receiver's current position (and terminate at the matching closing delimiter) and passes it
    /// to the given closure.
    ///
    /// When the closure has completed, the receiver's current position will be located after the
    /// closing of the object that was read.
    ///
    /// - Parameters:
    ///   - expectedLayout: The `_MessageLayout` of the message that we are expecting to read, from
    ///     which the name map will be retrieved.
    ///   - body: A closure that will be executed within the context of the sub-reader.
    mutating func withReaderForNextObject(
        expectedLayout: _MessageLayout,
        _ body: (inout TextFormatReader) throws -> Void
    ) throws {
        let subTerminator = try scanner.skipObjectStart()
        var subReader = TextFormatReader(scanner: scanner, nameMap: expectedLayout.nameMap, terminator: subTerminator)
        try body(&subReader)
        assert((scanner.recursionBudget + 1) == subReader.scanner.recursionBudget)
        self.scanner = subReader.scanner
    }
}
