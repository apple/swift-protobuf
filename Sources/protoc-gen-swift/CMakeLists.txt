add_executable(protoc-gen-swift
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
  main.swift
  MessageFieldGenerator.swift
  MessageGenerator.swift
  MessageStorageClassGenerator.swift
  MessageStorageDecision.swift
  OneofGenerator.swift
  Range+Extensions.swift
  StringUtils.swift
  Version.swift)
target_link_libraries(protoc-gen-swift PRIVATE
  SwiftProtobufPluginLibrary
  SwiftProtobuf)


install(TARGETS protoc-gen-swift
  DESTINATION bin)
set_property(GLOBAL APPEND PROPERTY Protobuf_EXPORTS protoc-gen-swift)
