# ``Google_Protobuf_Any``

## Topics

### Creating a default instance

- ``init()``

### Packing a message

- ``init(message:partial:typePrefix:)``

### Decoding from text format

- ``init(textFormatString:extensions:)``
- ``init(textFormatString:options:extensions:)``

### Unpacking a message

- ``isA(_:)``
- ``typeURL``
- ``value``

### Registering message types

- ``register(messageType:)``
- ``messageType(forTypeURL:)``
- ``messageType(forMessageName:)``

### Handling unknown fields

- ``unknownFields``
