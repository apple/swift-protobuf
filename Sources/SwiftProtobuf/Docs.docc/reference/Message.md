# ``Message``

## Topics

### Creating a message

- ``init()``
- ``with(_:)``
- ``init(unpackingAny:extensions:options:)``

### Implementing decoding and traversal

- ``decodeMessage(decoder:)``
- ``traverse(visitor:)``

### Decoding binary data

- ``init(contiguousBytes:extensions:partial:options:)``
- ``init(serializedBytes:extensions:partial:options:)-(RawSpan,_,_,_)``
- ``init(serializedBytes:extensions:partial:options:)-5hjsr``
- ``init(serializedBytes:extensions:partial:options:)-90c6l``
- ``init(serializedData:extensions:partial:options:)``
- ``merge(contiguousBytes:extensions:partial:options:)``
- ``merge(serializedBytes:extensions:partial:options:)-(RawSpan,_,_,_)``
- ``merge(serializedBytes:extensions:partial:options:)-6hzoh``
- ``merge(serializedBytes:extensions:partial:options:)-58wk3``
- ``merge(serializedData:extensions:partial:options:)``

### Serializing to binary data

- ``serializedBytes(partial:options:)``
- ``serializedData(partial:)``
- ``serializedData(partial:options:)``

### Decoding JSON

- ``init(jsonString:extensions:options:)``
- ``init(jsonString:options:)``
- ``init(jsonUTF8Bytes:extensions:options:)``
- ``init(jsonUTF8Bytes:options:)``
- ``init(jsonUTF8Data:extensions:options:)``
- ``init(jsonUTF8Data:options:)``

### Serializing to JSON

- ``jsonString(options:)``
- ``jsonUTF8Bytes(options:)``
- ``jsonUTF8Data(options:)``

### Decoding a JSON array of messages

- ``array(fromJSONString:extensions:options:)``
- ``array(fromJSONString:options:)``
- ``array(fromJSONUTF8Bytes:extensions:options:)``
- ``array(fromJSONUTF8Bytes:options:)``
- ``array(fromJSONUTF8Data:extensions:options:)``
- ``array(fromJSONUTF8Data:options:)``

### Encoding a JSON array of messages

- ``jsonString(from:options:)``
- ``jsonUTF8Bytes(from:options:)``
- ``jsonUTF8Data(from:options:)``

### Decoding text format

- ``init(textFormatString:extensions:)``
- ``init(textFormatString:options:extensions:)``

### Serializing to text format

- ``textFormatString()``
- ``textFormatString(options:)``

### Working with field masks

- ``merge(from:fieldMask:mergeOption:)``
- ``trim(keeping:)``
- ``isPathValid(_:)``

### Comparing and hashing messages

- ``isEqualTo(message:)``
- ``hash(into:)``

### Reading message metadata

- ``protoMessageName``
- ``isInitialized``
- ``unknownFields``
- ``UnknownStorage``
- ``debugDescription``
