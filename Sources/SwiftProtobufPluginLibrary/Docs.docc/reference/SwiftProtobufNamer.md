# ``SwiftProtobufNamer``

## Topics

### Creating a namer

- ``init()``
- ``init(currentFile:protoFileToModuleMappings:)``
- ``mappings``
- ``targetModule``

### Naming Swift declarations

- ``fullName(message:)``
- ``fullName(enum:)``
- ``fullName(enumValue:)``
- ``fullName(oneof:)``
- ``fullName(extensionField:)``

### Naming relative Swift declarations

- ``relativeName(message:)``
- ``relativeName(enum:)``
- ``relativeName(enumValue:)``
- ``relativeName(oneof:)``
- ``relativeName(extensionField:)``
- ``dottedRelativeName(enumValue:)``

### Naming message properties

- ``messagePropertyNames(field:prefixed:includeHasAndClear:)``
- ``messagePropertyName(oneof:prefixed:)``
- ``messagePropertyNames(extensionField:)``
- ``MessageFieldNames``
- ``OneofFieldNames``
- ``MessageExtensionNames``

### Working with modules

- ``swiftProtobufModuleName``
- ``swiftProtobufModulePrefix``
- ``typePrefix(forFile:)``

### Ensuring unique enum names

- ``uniquelyNamedValues(enum:)``
