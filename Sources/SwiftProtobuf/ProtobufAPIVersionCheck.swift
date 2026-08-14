// Sources/SwiftProtobuf/ProtobufAPIVersionCheck.swift - Version checking
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// A scheme that ensures the compiler cannot compile or link generated protos
// against a version of the runtime with which they are not compatible.
//
// In many cases, API changes themselves might introduce incompatibilities
// between generated code and the runtime library, but we also want to protect
// against cases where breaking behavioral changes (without affecting the API)
// would cause generated code to be incompatible with a particular version of
// the runtime.
//
// -----------------------------------------------------------------------------

/// An empty protocol that encodes the version of the runtime library.
///
/// Maintainers replace this protocol with one that has a different version
/// number any time they make breaking changes to the Swift Protobuf API.
/// Combined with the protocol below, this lets us verify that the compiler
/// never compiles generated code against a version of the API with which it
/// is incompatible.
///
/// `protoc-gen-swift` defines the version associated with a particular build
/// of the compiler as `Version.compatibilityVersion`. That version and this
/// version must match for the generated protos to be compatible, so if you
/// update one, make sure to update it here and in the associated type below.
public protocol ProtobufAPIVersion_2 {}

/// A binding between the version of generated code and the version of this library.
///
/// `protoc-gen-swift` implements this with a fileprivate type in each source
/// file it emits; that type causes a compile-time error, with reasonable
/// diagnostics, if the versions are incompatible.
public protocol ProtobufAPIVersionCheck {
    associatedtype Version: ProtobufAPIVersion_2
}
