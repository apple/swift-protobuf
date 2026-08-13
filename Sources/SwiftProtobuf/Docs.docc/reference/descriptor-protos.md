# Descriptor protos

Swift representations of `descriptor.proto` and `type.proto`, Google's own schema for describing proto files, messages, and services. Most code doesn't need these directly — for a richer, friendlier object model built on top of them, see `SwiftProtobufPluginLibrary`'s `Descriptor` family.

## Topics

### descriptor.proto messages

- ``Google_Protobuf_FileDescriptorSet``
- ``Google_Protobuf_FileDescriptorProto``
- ``Google_Protobuf_DescriptorProto``
- ``Google_Protobuf_FieldDescriptorProto``
- ``Google_Protobuf_OneofDescriptorProto``
- ``Google_Protobuf_EnumDescriptorProto``
- ``Google_Protobuf_EnumValueDescriptorProto``
- ``Google_Protobuf_ServiceDescriptorProto``
- ``Google_Protobuf_MethodDescriptorProto``
- ``Google_Protobuf_SourceCodeInfo``
- ``Google_Protobuf_GeneratedCodeInfo``
- ``Google_Protobuf_UninterpretedOption``

### descriptor.proto options

- ``Google_Protobuf_FileOptions``
- ``Google_Protobuf_MessageOptions``
- ``Google_Protobuf_FieldOptions``
- ``Google_Protobuf_OneofOptions``
- ``Google_Protobuf_EnumOptions``
- ``Google_Protobuf_EnumValueOptions``
- ``Google_Protobuf_ServiceOptions``
- ``Google_Protobuf_MethodOptions``
- ``Google_Protobuf_ExtensionRangeOptions``

### Feature editions

- ``Google_Protobuf_Edition``
- ``Google_Protobuf_FeatureSet``
- ``Google_Protobuf_FeatureSetDefaults``
- ``Google_Protobuf_SymbolVisibility``

### type.proto messages

- ``Google_Protobuf_Type``
- ``Google_Protobuf_Field``
- ``Google_Protobuf_Enum``
- ``Google_Protobuf_EnumValue``
- ``Google_Protobuf_Option``
- ``Google_Protobuf_Api``
- ``Google_Protobuf_Method``
- ``Google_Protobuf_Mixin``
- ``Google_Protobuf_SourceContext``
- ``Google_Protobuf_Syntax``
