// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: google/protobuf/late_loaded_option.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct ProtobufUnittest_LateLoadedOption: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var value: Int32 {
    get {return _value ?? 0}
    set {_value = newValue}
  }
  /// Returns true if `value` has been explicitly set.
  var hasValue: Bool {return self._value != nil}
  /// Clears the value of `value`. Subsequent reads from it will return its default value.
  mutating func clearValue() {self._value = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _value: Int32? = nil
}

// MARK: - Extension support defined in late_loaded_option.proto.

// MARK: - Extension Properties

// Swift Extensions on the extended Messages to add easy access to the declared
// extension fields. The names are based on the extension field name from the proto
// declaration. To avoid naming collisions, the names are prefixed with the name of
// the scope where the extend directive occurs.

extension SwiftProtobuf.Google_Protobuf_MessageOptions {

  var ProtobufUnittest_LateLoadedOption_ext: ProtobufUnittest_LateLoadedOption {
    get {return getExtensionValue(ext: ProtobufUnittest_LateLoadedOption.Extensions.ext) ?? ProtobufUnittest_LateLoadedOption()}
    set {setExtensionValue(ext: ProtobufUnittest_LateLoadedOption.Extensions.ext, value: newValue)}
  }
  /// Returns true if extension `ProtobufUnittest_LateLoadedOption.Extensions.ext`
  /// has been explicitly set.
  var hasProtobufUnittest_LateLoadedOption_ext: Bool {
    return hasExtensionValue(ext: ProtobufUnittest_LateLoadedOption.Extensions.ext)
  }
  /// Clears the value of extension `ProtobufUnittest_LateLoadedOption.Extensions.ext`.
  /// Subsequent reads from it will return its default value.
  mutating func clearProtobufUnittest_LateLoadedOption_ext() {
    clearExtensionValue(ext: ProtobufUnittest_LateLoadedOption.Extensions.ext)
  }

}

// MARK: - File's ExtensionMap: ProtobufUnittest_LateLoadedOption_Extensions

/// A `SwiftProtobuf.SimpleExtensionMap` that includes all of the extensions defined by
/// this .proto file. It can be used any place an `SwiftProtobuf.ExtensionMap` is needed
/// in parsing, or it can be combined with other `SwiftProtobuf.SimpleExtensionMap`s to create
/// a larger `SwiftProtobuf.SimpleExtensionMap`.
let ProtobufUnittest_LateLoadedOption_Extensions: SwiftProtobuf.SimpleExtensionMap = [
  ProtobufUnittest_LateLoadedOption.Extensions.ext
]

// Extension Objects - The only reason these might be needed is when manually
// constructing a `SimpleExtensionMap`, otherwise, use the above _Extension Properties_
// accessors for the extension fields on the messages directly.

extension ProtobufUnittest_LateLoadedOption {
  enum Extensions {
    static let ext = SwiftProtobuf.MessageExtension<SwiftProtobuf.OptionalMessageExtensionField<ProtobufUnittest_LateLoadedOption>, SwiftProtobuf.Google_Protobuf_MessageOptions>(
      _protobuf_fieldNumber: 95126892,
      fieldName: "protobuf_unittest.LateLoadedOption.ext"
    )
  }
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "protobuf_unittest"

extension ProtobufUnittest_LateLoadedOption: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".LateLoadedOption"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "value"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self._value) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._value {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtobufUnittest_LateLoadedOption, rhs: ProtobufUnittest_LateLoadedOption) -> Bool {
    if lhs._value != rhs._value {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}