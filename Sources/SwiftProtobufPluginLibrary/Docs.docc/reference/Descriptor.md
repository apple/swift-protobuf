# ``Descriptor``

## Topics

### Reading message identity

- ``name``
- ``fullName``
- ``typeName``
- ``index``
- ``file``
- ``containingType``

### Inspecting message contents

- ``fields``
- ``oneofs``
- ``realOneofs``
- ``enums``
- ``messages``
- ``extensions``
- ``reservedNames``
- ``reservedRanges``
- ``isDeprecated``

### Working with map entries

- ``mapKeyAndValue``
- ``isMapEntry``

### Working with extension ranges

- ``ExtensionRange``
- ``messageExtensionRanges``
- ``extensionRanges``
- ``normalizedExtensionRanges``
- ``ambitiousExtensionRanges``

### Identifying well-known types

- ``wellKnownType``
- ``WellKnownType``

### Reading source metadata

- ``options``
- ``features``
- ``sourceCodeInfoLocation``
- ``getLocationPath(path:)``
- ``protoSourceComments(commentPrefix:leadingDetachedPrefix:)``
- ``protoSourceCommentsWithDeprecation(commentPrefix:leadingDetachedPrefix:)``
- ``deprecationComment(commentPrefix:)``
- ``useMessageSetWireFormat``
- ``proto``
