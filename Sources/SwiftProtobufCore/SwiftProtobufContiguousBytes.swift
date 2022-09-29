// Sources/SwiftProtobufCore/SwiftProtobufContiguousBytes.swift
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
/// (i.e. `init(serializedBytes:)` for binary format and `init(jsonUTF8Bytes:)` for JSON).
// TODO: extend doc to include how this will be used in serialization once that API change has been finalised.
public protocol SwiftProtobufContiguousBytes {
    /// Calls the given closure with the contents of underlying storage.
    ///
    /// - note: Calling `withUnsafeBytes` multiple times does not guarantee that
    ///         the same buffer pointer will be passed in every time.
    /// - warning: The buffer argument to the body should not be stored or used
    ///            outside of the lifetime of the call to the closure.
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension Array: SwiftProtobufContiguousBytes where Array.Element == UInt8 {}

// TODO: Remove once `Data` is unused in all of `SwiftProtobufCore`
// This is currently necessary because `Data` is still used in some places in
// `SwiftProtobufCore`, such as all of the serialization path for JSON/binary.
// Until all of the `Data` usages in `SwiftProtobufCore` are removed, the
// conformance must live here, as we would otherwise have a circular dependency
// between the modules.
extension Data: SwiftProtobufContiguousBytes {}
