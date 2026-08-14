# ``SwiftProtobufPluginLibrary``

A reusable framework for building `protoc` plugins in Swift.

## Overview

`protoc` runs the `protoc-gen-swift` program to generate Swift code
from the parsed proto data.
This library encapsulates many of the common elements needed to build
such programs.
It's separated out here so that other people can reuse it.

## Topics

### Essentials

- ``CodeGenerator``
- ``CodeGeneratorParameter``
- ``GeneratorOutputs``
- ``ProtoCompilerContext``
- ``generateCode(request:generator:)``

### Descriptors

- ``DescriptorSet``
- ``FileDescriptor``
- ``Descriptor``
- ``FieldDescriptor``
- ``OneofDescriptor``
- ``EnumDescriptor``
- ``EnumValueDescriptor``
- ``ServiceDescriptor``
- ``MethodDescriptor``

### Descriptor protocols

- ``ProvidesDeprecationComment``
- ``SimpleProvidesDeprecationComment``
- ``TypeOrFileProvidesDeprecationComment``
- ``ProvidesLocationPath``
- ``ProvidesSourceCodeLocation``

### Naming Swift identifiers

- ``SwiftProtobufNamer``
- ``NamingUtils``
- ``isValidSwiftIdentifier(_:allowQuoted:)``
- ``swiftCommonTypes``
- ``swiftKeywordsReservedInParticularContexts``
- ``swiftKeywordsUsedInDeclarations``
- ``swiftKeywordsUsedInExpressionsAndTypes``
- ``swiftKeywordsUsedInStatements``
- ``swiftKeywordsWithNumberSign``
- ``swiftSpecialVariables``

### Mapping proto files to Swift modules

- ``ProtoFileToModuleMappings``
- ``SwiftProtobuf_GenSwift_ModuleMappings``

### Generating source output

- ``CodePrinter``
- ``ExtractProtoOptions``
- ``SwiftProtobufInfo``

### Compiler plugin protocol types

- ``Google_Protobuf_Compiler_CodeGeneratorRequest``
- ``Google_Protobuf_Compiler_CodeGeneratorResponse``
- ``Google_Protobuf_Compiler_Version``
