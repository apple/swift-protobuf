// Sources/SwiftProtobuf/ProtoNameResolvers.swift - Resolve proto field names
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------


/// This type contains helper functions to resolve field names based on their
/// numbers during encoding.
///
internal enum ProtoNameResolvers {

  /// Returns a function that resolves the proto/text name for fields defined on
  /// the given message or in any set extensions.
  ///
  /// If the name cannot be resolved (because the field number is not defined
  /// on the message or any of its extensions, or names were not compiled into
  /// the binary), then the resolver returns nil.
  static func protoFieldNameResolver(
    for message: Message
  ) -> (Int) -> StaticString? {
    if let nameProviding = message as? ProtoNameProviding {
      return { number in
        nameProviding._protobuf_fieldNames(for: number)?.protoStaticStringName
      }
    } else {
      return { _ in nil }
    }
  }

  /// Returns a function that resolves the JSON name for fields defined on the
  /// given message or in any set extensions.
  ///
  /// If the name cannot be resolved (because the field number is not defined
  /// on the message or any of its extensions, or names were not compiled into
  /// the binary), then the resolver returns nil.
  static func jsonFieldNameResolver(
    for message: Message
  ) -> (Int) -> StaticString? {
    if let nameProviding = message as? ProtoNameProviding {
      return { number in
        nameProviding._protobuf_fieldNames(for: number)?.jsonStaticStringName
      }
    } else {
      return { _ in nil }
    }
  }
}
