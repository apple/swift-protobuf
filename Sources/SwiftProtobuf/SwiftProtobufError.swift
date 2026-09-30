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
/// of the error. For example, an issue when decoding binary data into a proto will result in a
/// ``SwiftProtobufError/Code-swift.struct/binaryDecodingError`` error code.
/// Errors also include a message describing what went wrong and how to remedy it (if applicable). The
/// message is not static and may include dynamic information such as the
/// type URL for a type the decoder could not decode, for example.
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

    /// A message describing what went wrong and how to remedy it.
    package var message: String {
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

    /// Creates a new error using the code, message, and location you provide.
    ///
    /// - Parameters:
    ///   - code: A high-level ``SwiftProtobufError/Code-swift.struct`` that classifies the error.
    ///   - message: A message describing what went wrong and how to remedy it.
    ///   - location: The location in source code that threw the error.
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
            case jsonDecodingError
            case jsonEncodingError

            var description: String {
                switch self {
                case .binaryDecodingError:
                    return "Binary decoding error"
                case .binaryStreamDecodingError:
                    return "Stream decoding error"
                case .jsonDecodingError:
                    return "JSON decoding error"
                case .jsonEncodingError:
                    return "JSON encoding error"
                }
            }
        }

        /// A short, human-readable label for the kind of error this code represents.
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

        /// Errors arising from decoding streams of binary messages.
        ///
        /// These errors have to do with the framing of the messages in the stream, or the stream as a whole.
        public static var binaryStreamDecodingError: Self {
            Self(.binaryStreamDecodingError)
        }

        /// Errors arising from JSON decoding of data into protobufs.
        public static var jsonDecodingError: Self {
            Self(.jsonDecodingError)
        }

        /// Errors arising from JSON encoding of messages.
        public static var jsonEncodingError: Self {
            Self(.jsonEncodingError)
        }
    }

    /// A location within source code.
    public struct SourceLocation: Sendable, Hashable {
        /// The function that threw the error.
        public var function: String

        /// The file that threw the error.
        public var file: String

        /// The line that threw the error.
        public var line: Int

        /// Creates a new location within source code.
        ///
        /// - Parameters:
        ///   - function: The function that threw the error.
        ///   - file: The file that threw the error.
        ///   - line: The line that threw the error.
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
    /// A human-readable summary that combines the error's code, location, and message.
    public var description: String {
        "\(self.code) (at \(self.location)): \(self.message)"
    }
}

extension SwiftProtobufError: CustomDebugStringConvertible {
    /// A more detailed summary that reflects the full code, location, and message for debugging.
    public var debugDescription: String {
        "\(String(reflecting: self.code)) (at \(String(reflecting: self.location))): \(String(reflecting: self.message))"
    }
}

// - MARK: Common errors

extension SwiftProtobufError {
    /// Errors arising from binary decoding of data into protobufs.
    public enum BinaryDecoding {
        /// Message is too large.
        ///
        /// Bytes and strings have a max size of 2GB.
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

    /// Errors arising from decoding streams of binary messages.
    ///
    /// These errors have to do with the framing
    /// of the messages in the stream, or the stream as a whole.
    public enum BinaryStreamDecoding {
        /// Message is too large.
        ///
        /// Bytes and strings have a max size of 2GB.
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

        /// Indicates that no bytes were available when reading from the stream.
        ///
        /// This isn't really an error: `InputStream` documents that `hasBytesAvailable`
        /// may return `true` if a read is needed to determine if there really are
        /// bytes available. `parse` or `merge` throws this when it fails because
        /// there were no bytes available. If you encounter this, use other means
        /// to determine whether the stream has completely ended
        /// or more bytes might eventually show up.
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

    /// Errors arising from JSON decoding of data into protobufs.
    public enum JSONDecoding {
        /// While decoding an Any message, the type URL was malformed.
        ///
        /// The JSON representation stores the type URL under the `@type` key.
        public static func invalidAnyTypeURL(
            type_url: String,
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .jsonDecodingError,
                message: "google.protobuf.Any '@type' was invalid: \(type_url).",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }

        /// While decoding an Any message, the type URL was missing even though the message had other fields.
        public static func emptyAnyTypeURL(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .jsonDecodingError,
                message: "google.protobuf.Any '@type' was must be present if if the object is not empty.",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }
    }

    /// Errors arising from JSON encoding of messages.
    public enum JSONEncoding {
        /// While encoding an Any message, the type URL was malformed.
        public static func invalidAnyTypeURL(
            type_url: String,
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .jsonEncodingError,
                message: "google.protobuf.Any 'type_url' was invalid: \(type_url).",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }

        /// While encoding an Any message, the type URL was empty.
        public static func emptyAnyTypeURL(
            function: String = #function,
            file: String = #fileID,
            line: Int = #line
        ) -> SwiftProtobufError {
            SwiftProtobufError(
                code: .jsonEncodingError,
                message: "google.protobuf.Any 'type_url' was empty, only allowed for empty objects.",
                location: SourceLocation(function: function, file: file, line: line)
            )
        }
    }
}
