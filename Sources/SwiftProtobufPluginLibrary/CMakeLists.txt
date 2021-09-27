add_library(SwiftProtobufPluginLibrary
  Array+Extensions.swift
  CodePrinter.swift
  Descriptor+Extensions.swift
  Descriptor.swift
  FieldNumbers.swift
  Google_Protobuf_Compiler_CodeGeneratorResponse+Extensions.swift
  Google_Protobuf_SourceCodeInfo+Extensions.swift
  NamingUtils.swift
  plugin.pb.swift
  ProtoFileToModuleMappings.swift
  ProvidesLocationPath.swift
  ProvidesSourceCodeLocation.swift
  SwiftLanguage.swift
  SwiftProtobufInfo.swift
  SwiftProtobufNamer.swift
  swift_protobuf_module_mappings.pb.swift
  UnicodeScalar+Extensions.swift)
target_link_libraries(SwiftProtobufPluginLibrary PUBLIC
  SwiftProtobuf)


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
