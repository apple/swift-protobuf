// Sources/protoc-gen-swift/Weak.swift - Weak reference helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper types to work with weak references.
///
// -----------------------------------------------------------------------------

/// A wrapper that holds a weak reference to an object so that it can be stored
/// in a collection without strongly retaining the reference.
internal struct Weak<Wrapped: AnyObject> {

  /// The object that is being weakly referenced. May be nil if the object was
  /// released after the receiver was created.
  internal private(set) weak var wrapped: Wrapped?

  /// Creates a value that weakly wraps a reference to the given object.
  ///
  /// - Parameter wrapped: The object to be weakly retained.
  internal init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }
}
