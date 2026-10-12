# ``Google_Protobuf_FieldMask``

## Topics

### Creating a default instance

- ``init()``

### Creating a field mask from paths

- ``init(protoPaths:)-(String...)``
- ``init(protoPaths:)-([String])``
- ``init(jsonPaths:)``

### Creating a field mask from a message type

- ``init(allFieldsOf:)``
- ``init(fieldNumbers:of:)``

### Modifying paths

- ``addPath(_:of:)``
- ``canonical``

### Combining and testing paths

- ``union(_:)``
- ``intersect(_:)``
- ``subtract(_:)``
- ``contains(_:)``
- ``isValid(for:)``
- ``paths``

### Merging messages

- ``MergeOptions``

### Handling unknown fields

- ``unknownFields``
