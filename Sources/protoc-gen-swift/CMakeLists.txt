add_executable(protoc-gen-swift
  CommandLine+Extensions.swift
  Compression+Compressing.swift
  Descriptor+Extensions.swift
  EnumGenerator.swift
  EnumSchemaCalculator.swift
  ExtensionSetGenerator.swift
  FieldGenerator.swift
  FileGenerator.swift
  FileIo.swift
  GenerationError.swift
  GeneratorOptions.swift
  Google_Protobuf_FileDescriptorProto+Extensions.swift
  json_enumvalue_options.pb.swift
  json_options.pb.swift
  MapEntryGenerator.swift
  MessageFieldGenerator.swift
  MessageGenerator.swift
  MessageSchemaCalculator.swift
  OneofGenerator.swift
  ProvidesDeprecationComment+Extensions.swift
  ProvidesSourceCodeLocation+Extensions.swift
  Range+Extensions.swift
  ReflectionTableCalculator.swift
  SchemaWriter.swift
  StringUtils.swift
  SwiftGeneratorPlugin.swift
  SwiftProtobufNamer+Extensions.swift
  Version.swift)
target_link_libraries(protoc-gen-swift PRIVATE
  SwiftProtobufPluginLibrary
  SwiftProtobuf)

target_compile_options(protoc-gen-swift PRIVATE
    "SHELL:-package-name SwiftProtobuf")

install(TARGETS protoc-gen-swift
  DESTINATION bin)
set_property(GLOBAL APPEND PROPERTY Protobuf_EXPORTS protoc-gen-swift)
