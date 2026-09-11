# ``FieldDescriptor``

## Topics

### Reading field identity

- ``name``
- ``fullName``
- ``jsonName``
- ``number``
- ``index``
- ``file``
- ``containingType``
- ``extensionScope``
- ``isExtension``

### Reading field type information

- ``type``
- ``messageType``
- ``enumType``
- ``isMap``
- ``isPackable``
- ``isPacked``
- ``requiresUTF8Validation``
- ``internal_isGroupLike``

### Describing field cardinality

- ``isRepeated``
- ``isRequired``
- ``hasPresence``
- ``isOptional``
- ``label``
- ``hasOptionalKeyword``

### Reading default values

- ``defaultValue``
- ``explicitDefaultValue``

### Working with oneofs

- ``containingOneof``
- ``realContainingOneof``
- ``oneofIndex``
- ``oneof``
- ``realOneof``

### Reading source metadata

- ``options``
- ``features``
- ``sourceCodeInfoLocation``
- ``getLocationPath(path:)``
- ``protoSourceComments(commentPrefix:leadingDetachedPrefix:)``
- ``protoSourceCommentsWithDeprecation(commentPrefix:leadingDetachedPrefix:)``
- ``deprecationComment(commentPrefix:)``
- ``proto``
