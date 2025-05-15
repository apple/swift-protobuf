// Sources/protoc-gen-swift/GenerationError.swift - Generation errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

enum GenerationError: Error, CustomStringConvertible {
    /// Raised when parsing the parameter string and found an unknown key.
    case unknownParameter(name: String)
    /// Raised when a parameter was given an invalid value.
    case invalidParameterValue(name: String, value: String)
    /// Raised to wrap another error but provide a context message.
    case wrappedError(message: String, error: any Error)
    /// Raised with an specific message
    case message(message: String)

    var description: String {
        switch self {
        case .unknownParameter(let name):
            return "Unknown generation parameter '\(name)'"
        case .invalidParameterValue(let name, let value):
            return "Unknown value for generation parameter '\(name)': '\(value)'"
        case .wrappedError(let message, let error):
            return "\(message): \(error)"
        case .message(let message):
            return message
        }
    }
}
