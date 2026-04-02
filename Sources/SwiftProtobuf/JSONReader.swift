// Sources/SwiftProtobuf/JSONReader.swift - JSON reader
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// High-level wrapper around `JSONScanner`.
///
// -----------------------------------------------------------------------------

import Foundation

/// This type is a high-level wrapper around `JSONScanner`. It is the analogue of `JSONDecoder`
/// from the old implementation, but without the `Decoder` infrastructure that we'll be deleting.
/// Once that refactoring is complete, we should consider whether it makes sense to merge this with
/// `JSONScanner` instead of keeping them separate.
struct JSONReader {
    var scanner: JSONScanner
    private var nameMap: _NameMap
    private var messageSchema: MessageSchema?
    private var hasSeenField = false

    var options: JSONDecodingOptions { scanner.options }

    var complete: Bool {
        mutating get { scanner.complete }
    }

    /// Creates a new text format reader.
    ///
    /// - Precondition: `buffer.baseAddress` is not nil.
    internal init(
        buffer: UnsafeRawBufferPointer,
        nameMap: _NameMap,
        messageSchema: MessageSchema? = nil,
        options: JSONDecodingOptions,
        extensions: (any ExtensionMap)?,
    ) {
        self.init(
            scanner: JSONScanner(
                source: buffer,
                options: options,
                extensions: extensions,
            ),
            nameMap: nameMap,
            messageSchema: messageSchema
        )
    }

    private init(scanner: JSONScanner, nameMap: _NameMap, messageSchema: MessageSchema?) {
        self.scanner = scanner
        self.nameMap = nameMap
        self.messageSchema = messageSchema
    }

    /// Parses and returns the number of the next field in the JSON string, or nil if the end of the
    /// current object was reached.
    mutating func nextFieldNumber() throws -> UInt32? {
        if scanner.skipOptionalObjectEnd() {
            return nil
        }
        if hasSeenField {
            try scanner.skipRequiredComma()
        }
        // TODO: Remove the `messageType` argument from the scanner.
        guard let fieldNumber = try scanner.nextFieldNumber(names: nameMap, messageType: nil, messageSchema: messageSchema) else {
            return nil
        }
        hasSeenField = true
        return UInt32(fieldNumber)
    }

    /// Creates a new `JSONReader` that is configured to start reading the object at the receiver's
    /// current position (and terminate at the matching closing delimiter) and passes it to the
    /// given closure.
    ///
    /// When the closure has completed, the receiver's current position will be located after the
    /// closing of the object that was read.
    ///
    /// - Parameters:
    ///   - expectedSchema: The `MessageSchema` of the message that we are expecting to read, from
    ///     which the name map will be retrieved.
    ///   - body: A closure that will be executed within the context of the sub-reader.
    mutating func withReaderForNextObject(
        expectedSchema: MessageSchema,
        _ body: (inout JSONReader) throws -> Void
    ) throws {
        var subReader = JSONReader(
            scanner: scanner,
            nameMap: expectedSchema.nameMap,
            messageSchema: messageSchema)
        try body(&subReader)
        assert(scanner.recursionBudget == subReader.scanner.recursionBudget)
        self.scanner = subReader.scanner
    }
}
