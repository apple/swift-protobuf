add_library(SwiftProtobuf
  any.pb.swift
  AnyMessageStorage.swift
  AnyUnpackError.swift
  api.pb.swift
  BinaryDecoder.swift
  BinaryDecodingError.swift
  BinaryDecodingOptions.swift
  BinaryDelimited.swift
  BinaryEncoder.swift
  BinaryEncodingError.swift
  BinaryEncodingSizeVisitor.swift
  BinaryEncodingVisitor.swift
  CustomJSONCodable.swift
  Data+Extensions.swift
  Decoder.swift
  descriptor.pb.swift
  DoubleParser.swift
  duration.pb.swift
  empty.pb.swift
  Enum.swift
  ExtensibleMessage.swift
  ExtensionFields.swift
  ExtensionFieldValueSet.swift
  ExtensionMap.swift
  FieldTag.swift
  FieldTypes.swift
  field_mask.pb.swift
  Google_Protobuf_Any+Extensions.swift
  Google_Protobuf_Any+Registry.swift
  Google_Protobuf_Duration+Extensions.swift
  Google_Protobuf_FieldMask+Extensions.swift
  Google_Protobuf_ListValue+Extensions.swift
  Google_Protobuf_NullValue+Extensions.swift
  Google_Protobuf_Struct+Extensions.swift
  Google_Protobuf_Timestamp+Extensions.swift
  Google_Protobuf_Value+Extensions.swift
  Google_Protobuf_Wrappers+Extensions.swift
  HashVisitor.swift
  Internal.swift
  JSONDecoder.swift
  JSONDecodingError.swift
  JSONDecodingOptions.swift
  JSONEncoder.swift
  JSONEncodingError.swift
  JSONEncodingOptions.swift
  JSONEncodingVisitor.swift
  JSONMapEncodingVisitor.swift
  JSONScanner.swift
  MathUtils.swift
  Message+AnyAdditions.swift
  Message+BinaryAdditions.swift
  Message+JSONAdditions.swift
  Message+JSONArrayAdditions.swift
  Message+TextFormatAdditions.swift
  Message.swift
  MessageExtension.swift
  NameMap.swift
  ProtobufAPIVersionCheck.swift
  ProtobufMap.swift
  ProtoNameProviding.swift
  SelectiveVisitor.swift
  SimpleExtensionMap.swift
  source_context.pb.swift
  StringUtils.swift
  struct.pb.swift
  TextFormatDecoder.swift
  TextFormatDecodingError.swift
  TextFormatEncoder.swift
  TextFormatEncodingOptions.swift
  TextFormatEncodingVisitor.swift
  TextFormatScanner.swift
  timestamp.pb.swift
  TimeUtils.swift
  type.pb.swift
  UnknownStorage.swift
  UnsafeBufferPointer+Shims.swift
  UnsafeRawPointer+Shims.swift
  Varint.swift
  Version.swift
  Visitor.swift
  WireFormat.swift
  wrappers.pb.swift
  ZigZag.swift)
set_target_properties(SwiftProtobuf PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})


install(TARGETS SwiftProtobuf
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
get_swift_host_arch(swift_arch)
install(FILES
  $<TARGET_PROPERTY:SwiftProtobuf,Swift_MODULE_DIRECTORY>/SwiftProtobuf.swiftdoc
  $<TARGET_PROPERTY:SwiftProtobuf,Swift_MODULE_DIRECTORY>/SwiftProtobuf.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
set_property(GLOBAL APPEND PROPERTY Protobuf_EXPORTS SwiftProtobuf)
