add_executable(protoc-gen-swift
  BytecodeWriter.swift
  CommandLine+Extensions.swift
  Descriptor+Extensions.swift
  EnumGenerator.swift
  ExtensionSetGenerator.swift
  FieldGenerator.swift
  FileGenerator.swift
  FileIo.swift
  GenerationError.swift
  GeneratorOptions.swift
  Google_Protobuf_FileDescriptorProto+Extensions.swift
  MessageFieldGenerator.swift
  MessageGenerator.swift
  MessageStorageClassGenerator.swift
  MessageStorageDecision.swift
  OneofGenerator.swift
  ProtoNameInstructionWriter.swift
  ProvidesDeprecationComment+Extensions.swift
  ProvidesSourceCodeLocation+Extensions.swift
  Range+Extensions.swift
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
