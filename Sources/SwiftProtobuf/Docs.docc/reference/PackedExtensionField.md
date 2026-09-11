# ``PackedExtensionField``

## Topics

### Reading and writing the value

- ``value``
- ``protobufExtension``

### Creating an extension field

- ``init(protobufExtension:value:)``
- ``init(protobufExtension:decoder:)``

### Decoding and traversing the field

- ``decodeExtensionField(decoder:)``
- ``traverse(visitor:)``

### Comparing and describing values

- ``isEqual(other:)``
- ``hash(into:)``
- ``debugDescription``
