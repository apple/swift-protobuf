// Sources/SwiftProtobuf/SwiftProtobufError.swift
//
// Copyright (c) 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// A SwiftProtobuf specific error.
///
/// All errors have a high-level ``SwiftProtobufError/Code-swift.struct`` which identifies the domain
/// of the error. For example, an issue when encoding a proto into binary data will result in a
/// ``SwiftProtobufError/Code-swift.struct/binaryEncodingError`` error code.
/// Errors also include a message describing what went wrong and how to remedy it (if applicable). The
/// ``SwiftProtobufError/message`` is not static and may include dynamic information such as the
/// type URL for a type that could not be decoded, for example.
public struct SwiftProtobufError: Error, @unchecked Sendable {
    // Note: @unchecked because we use a backing class for storage.

    private var storage: Storage
    private mutating func ensureStorageIsUnique() {
        if !isKnownUniquelyReferenced(&self.storage) {
            self.storage = self.storage.copy()
        }
    }

    private final class Storage {
        var code: Code
        var message: String
        var location: SourceLocation

        init(
            code: Code,
            message: String,
            location: SourceLocation
        ) {
            self.code = code
            self.message = message
            self.location = location
        }

        func copy() -> Self {
            Self(
                code: self.code,
                message: self.message,
                location: self.location
            )
        }
    }

    /// A high-level error code to provide broad a classification.
    public var code: Code {
        get { self.storage.code }
        set {
            self.ensureStorageIsUnique()
            self.storage.code = newValue
        }
    }

    /// A message describing what went wrong and how it may be remedied.
    internal var message: String {
        get { self.storage.message }
        set {
            self.ensureStorageIsUnique()
            self.storage.message = newValue
        }
    }

    private var location: SourceLocation {
        get { self.storage.location }
        set {
            self.ensureStorageIsUnique()
            self.storage.location = newValue
        }
    }

    public init(
        code: Code,
        message: String,
        location: SourceLocation
    ) {
        self.storage = Storage(code: code, message: message, location: location)
    }
}

extension SwiftProtobufError {
    /// A high level indication of the kind of error being thrown.
    public struct Code: Hashable, Sendable, CustomStringConvertible {
        private enum Wrapped: Hashable, Sendable, CustomStringConvertible {
            case binaryDecodingError
            case binaryStreamDecodingError

            var description: String {
                switch self {
                case .binaryDecodingError:
                    return "Binary decoding error"
                case .binaryStreamDecodingError:
                    return "Stream decoding error"
                }
            }
        }

        /// This Code's description.
        public var description: String {
            String(describing: self.code)
        }

        private var code: Wrapped
        private init(_ code: Wrapped) {
            self.code = code
        }

        /// Errors arising from binary decoding of data into protobufs.
        public static var binaryDecodingError: Self {
            Self(.binaryDecodingError)
        }

        /// Errors arising from decoding streams of binary messages. These errors have to do with the framing
        /// of the messages in the stream, or the stream as a whole.
        public static var binaryStreamDecodingError: Self {
            Self(.binaryStreamDecodingError)
        }
    }

    /// A location within source code.
    public struct SourceLocation: Sendable, Hashable {
        /// The function in which the error was thrown.
        public var function: String

        /// The file in which the error was thrown.
        public var file: String

        /// The line on which the error was thrown.
        public var line: Int

        public init(function: String, file: String, line: Int) {
            self.function = function
            self.file = file
            self.line = line
        }

        @usableFromInline
        internal static func here(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> Self {
            SourceLocation(function: function, file: file, line: line)
        }
    }
}

extension SwiftProtobufError: CustomStringConvertible {
    public var description: String {
        "\(self.code) (at \(self.location)): \(self.message)"
    }
}

extension SwiftProtobufError: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(String(reflecting: self.code)) (at \(String(reflecting: self.location))): \(String(reflecting: self.message))"
    }
}

// - MARK: Common errors

extension SwiftProtobufError {
    /// Errors arising from binary decoding of data into protobufs.
    public enum BinaryDecoding {
        /// Message is too large. Bytes and Strings have a max size of 2GB.
        public static func tooLarge(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .binaryDecodingError,
                message: "Message too large: Bytes and Strings have a max size of 2GB.",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }
    }

    /// Errors arising from decoding streams of binary messages. These errors have to do with the framing
    /// of the messages in the stream, or the stream as a whole.
    public enum BinaryStreamDecoding {
        /// Message is too large. Bytes and Strings have a max size of 2GB.
        public static func tooLarge(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .binaryStreamDecodingError,
                message: "Message too large: Bytes and Strings have a max size of 2GB.",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }

        /// While attempting to read the length of a message on the stream, the
        /// bytes were malformed for the protobuf format.
        public static func malformedLength(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .binaryStreamDecodingError,
                message: """
                      While attempting to read the length of a binary-delimited message \
                      on the stream, the bytes were malformed for the protobuf format.
                    """,
                location: .init(function: function, file: file, line: line)
            )
        }

        /// This isn't really an error. `InputStream` documents that
        /// `hasBytesAvailable` _may_ return `True` if a read is needed to
        /// determine if there really are bytes available. So this "error" is thrown
        /// when a `parse` or `merge` fails because there were no bytes available.
        /// If this is raised, the callers should decide via what ever other means
        /// are correct if the stream has completely ended or if more bytes might
        /// eventually show up.
        public static func noBytesAvailable(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .binaryStreamDecodingError,
                message: """
                      This is not really an error: please read the documentation for
                      `SwiftProtobufError/BinaryStreamDecoding/noBytesAvailable` for more information.
                    """,
                location: .init(function: function, file: file, line: line)
            )
        }
    }
}
