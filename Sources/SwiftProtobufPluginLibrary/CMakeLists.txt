add_library(SwiftProtobufPluginLibrary
  CodeGenerator.swift
  CodeGeneratorParameter.swift
  CodePrinter.swift
  Descriptor.swift
  Descriptor+Extensions.swift
  FeatureResolver.swift
  FieldNumbers.swift
  GeneratorOutputs.swift
  Google_Protobuf_Compiler_CodeGeneratorResponse+Extensions.swift
  Google_Protobuf_Edition+Extensions.swift
  Google_Protobuf_SourceCodeInfo+Extensions.swift
  NamingUtils.swift
  plugin.pb.swift
  PluginLibEditionDefaults.swift
  ProtoCompilerContext.swift
  ProtoFileToModuleMappings.swift
  ProvidesDeprecationComment.swift
  ProvidesLocationPath.swift
  ProvidesSourceCodeLocation.swift
  StandardErrorOutputStream.swift
  StringUtils.swift
  swift_protobuf_module_mappings.pb.swift
  SwiftLanguage.swift
  SwiftProtobufInfo.swift
  SwiftProtobufNamer.swift
  UnicodeScalar+Extensions.swift)
target_link_libraries(SwiftProtobufPluginLibrary PUBLIC
  SwiftProtobuf)

target_compile_options(SwiftProtobufPluginLibrary PRIVATE
    "SHELL:-package-name SwiftProtobuf"
    "SHELL:-module-name SwiftProtobufPluginLibrary")


install(TARGETS SwiftProtobufPluginLibrary
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
get_swift_host_arch(swift_arch)
install(FILES
  $<TARGET_PROPERTY:SwiftProtobufPluginLibrary,Swift_MODULE_DIRECTORY>/SwiftProtobufPluginLibrary.swiftdoc
  $<TARGET_PROPERTY:SwiftProtobufPluginLibrary,Swift_MODULE_DIRECTORY>/SwiftProtobufPluginLibrary.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
set_property(GLOBAL APPEND PROPERTY Protobuf_EXPORTS SwiftProtobufPluginLibrary)
