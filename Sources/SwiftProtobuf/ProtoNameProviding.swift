// Sources/SwiftProtobuf/ProtoNameProviding.swift - Support for accessing proto names
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------


/// Messages conform to this protocol to provide the proto/text and JSON field
/// names for their fields. This allows these names to be pulled out into
/// extensions in separate files so that users can omit them in release builds
/// (reducing bloat and minimizing leaks of field names).
public protocol ProtoNameProviding {

  /// The mapping between field numbers and proto/JSON field names defined in
  /// the conforming message type.
  static var _protobuf_fieldNames: FieldNameMap { get }

  /// Returns the field name bundle for the field with the given number.
  ///
  /// The default implementation looks up the field in the static name map,
  /// which is sufficient for proto3. For proto2 extensions, making this an
  /// instance method allows generated messages to override it and ask their
  /// extension sets for names as well.
  func _protobuf_fieldNames(for number: Int) -> FieldNameMap.Names?

  /// Returns the field number for the field with the given proto/text name.
  ///
  /// The default implementation looks up the field in the static name map,
  /// which is sufficient for proto3. For proto2 extensions, making this an
  /// instance method allows generated messages to override it and ask their
  /// extension sets for names as well.
  func _protobuf_fieldNumber(forProtoName name: String) -> Int?
}


extension ProtoNameProviding {

  public func _protobuf_fieldNames(for number: Int) -> FieldNameMap.Names? {
    return Self._protobuf_fieldNames.fieldNames(for: number)
  }

  public func _protobuf_fieldNumber(forProtoName name: String) -> Int? {
    return Self._protobuf_fieldNames.fieldNumber(forProtoName: name)
  }
}
