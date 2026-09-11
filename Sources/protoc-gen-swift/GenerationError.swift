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
    /// Indicates that the parameter string contains a key that isn't recognized.
    case unknownParameter(name: String)
    /// Indicates that a parameter has an invalid value.
    case invalidParameterValue(name: String, value: String)
    /// Wraps another error and adds a context message.
    case wrappedError(message: String, error: any Error)
    /// Carries a specific message with no additional context.
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
