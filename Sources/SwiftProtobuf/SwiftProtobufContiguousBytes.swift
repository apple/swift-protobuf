// Sources/SwiftProtobuf/SwiftProtobufContiguousBytes.swift
//
// Copyright (c) 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

/// Conformance to this protocol gives users a way to provide their own "bag of bytes" types
/// to be used for serialization and deserialization of protobufs.
/// It provides a general interface for bytes since the Swift Standard Library currently does not
/// provide such a protocol.
///
/// By conforming your own types to this protocol, you will be able to pass instances of said types
/// directly to `SwiftProtobuf.Message`'s deserialisation methods
/// (i.e. `init(contiguousBytes:)` for binary format and `init(jsonUTF8Bytes:)` for JSON).
public protocol SwiftProtobufContiguousBytes {
    /// An initializer for a bag of bytes type.
    ///
    /// - Parameters:
    ///   - repeating: the byte value to be repeated.
    ///   - count: the number of times to repeat the byte value.
    init(repeating: UInt8, count: Int)

    /// An initializer for a bag of bytes type, given a sequence of bytes.
    ///
    /// - Parameters:
    ///   - sequence: a sequence of UInt8 from which the bag of bytes should be constructed.
    init<S: Sequence>(_ sequence: S) where S.Element == UInt8

    /// The number of bytes in the bag of bytes.
    var count: Int { get }

    /// Calls the given closure with the contents of underlying storage.
    ///
    /// - note: Calling `withUnsafeBytes` multiple times does not guarantee that
    ///         the same buffer pointer will be passed in every time.
    /// - warning: The buffer argument to the body should not be stored or used
    ///            outside of the lifetime of the call to the closure.
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R

    /// Calls the given closure with the contents of underlying storage.
    ///
    /// - note: Calling `withUnsafeBytes` multiple times does not guarantee that
    ///         the same buffer pointer will be passed in every time.
    /// - warning: The buffer argument to the body should not be stored or used
    ///            outside of the lifetime of the call to the closure.
    mutating func withUnsafeMutableBytes<R>(_ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R
}

extension Array: SwiftProtobufContiguousBytes where Array.Element == UInt8 {}

extension Data: SwiftProtobufContiguousBytes {}
