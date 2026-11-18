add_library(SwiftProtobuf
  any.pb.swift
  AnyUnpackError.swift
  api.pb.swift
  AsyncMessageSequence.swift
  BinaryDecodingError.swift
  BinaryDecodingOptions.swift
  BinaryDelimited.swift
  BinaryEncoder.swift
  BinaryEncodingError.swift
  BinaryEncodingOptions.swift
  Compression.swift
  Compression+Decompressing.swift
  CustomJSONWKTClassification.swift
  descriptor.pb.swift
  duration.pb.swift
  empty.pb.swift
  Enum.swift
  EnumSchema.swift
  EnumWitnesses.swift
  ExtensionMap.swift
  ExtensionSchema.swift
  ExtensionStorage.swift
  ExtensionStorage+BinaryDecoding.swift
  ExtensionStorage+BinaryEncoding.swift
  ExtensionStorage+BinarySize.swift
  ExtensionStorage+JSONDecoding.swift
  ExtensionStorage+JSONEncoding.swift
  ExtensionStorage+TextDecoding.swift
  ExtensionStorage+TextEncoding.swift
  ExtensionStorage+Witnesses.swift
  ExtensionValueStorage.swift
  field_mask.pb.swift
  FieldBitSet.swift
  FieldTag.swift
  GeneratedMessage.swift
  Google_Protobuf_Any+Extensions.swift
  Google_Protobuf_Any+Registry.swift
  Google_Protobuf_Duration+Extensions.swift
  Google_Protobuf_FieldMask+Extensions.swift
  Google_Protobuf_ListValue+Extensions.swift
  Google_Protobuf_Struct+Extensions.swift
  Google_Protobuf_Timestamp+Extensions.swift
  Google_Protobuf_Value+Extensions.swift
  Google_Protobuf_Wrappers+Extensions.swift
  implicit_weak_message.pb.swift
  JSONDecodingError.swift
  JSONDecodingOptions.swift
  JSONEncoder.swift
  JSONEncodingError.swift
  JSONEncodingOptions.swift
  JSONReader.swift
  KnownField.swift
  Lock.swift
  MapEntryWitnesses.swift
  MapEntryWorkingSpace.swift
  MathUtils.swift
  Message.swift
  Message+AnyAdditions.swift
  Message+BinaryAdditions_Data.swift
  Message+BinaryAdditions.swift
  Message+FieldMask.swift
  Message+JSONAdditions_Data.swift
  Message+JSONAdditions.swift
  Message+JSONArrayAdditions_Data.swift
  Message+JSONArrayAdditions.swift
  Message+TextFormatAdditions.swift
  MessageSchema.swift
  MessageSchema+FieldMask.swift
  MessageStorage.swift
  MessageStorage+BinaryDecoding.swift
  MessageStorage+BinaryEncoding.swift
  MessageStorage+BinarySize.swift
  MessageStorage+Equality.swift
  MessageStorage+FieldMask.swift
  MessageStorage+Hashing.swift
  MessageStorage+JSONDecoding.swift
  MessageStorage+JSONEncoding.swift
  MessageStorage+TextDecoding.swift
  MessageStorage+TextEncoding.swift
  MessageStorage+Witnesses.swift
  MessageWitnesses.swift
  ProtobufAPIVersionCheck.swift
  ProtobufMapParticipant.swift
  ReflectionTable.swift
  SchemaBase128Decoding.swift
  source_context.pb.swift
  StringUtils.swift
  struct.pb.swift
  SwiftProtobufContiguousBytes.swift
  SwiftProtobufError.swift
  TextFormatDecodingOptions.swift
  TextFormatEncoder.swift
  TextFormatEncodingOptions.swift
  TextFormatReader.swift
  TextualParser.swift
  timestamp.pb.swift
  TimeUtils.swift
  Tokenizer.swift
  type.pb.swift
  UnknownStorage.swift
  UnsafeRawPointer+Shims.swift
  UTF8Name.swift
  Varint.swift
  Version.swift
  WeakLinkageSupport.swift
  WireFormat.swift
  WireFormatReader.swift
  wrappers.pb.swift
  ZigZag.swift)
set_target_properties(SwiftProtobuf PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

target_compile_options(SwiftProtobuf PRIVATE
    "SHELL:-package-name SwiftProtobuf"
    -DBinaryDelimitedStreams
    -DFieldMaskUtilities)


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
