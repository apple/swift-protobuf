# ``Google_Protobuf_Value``

## Topics

### Creating a default instance

- ``init()``

### Creating a value from a literal

- ``init(integerLiteral:)``
- ``init(floatLiteral:)``
- ``init(booleanLiteral:)``
- ``init(stringLiteral:)``
- ``init(nilLiteral:)``

### Creating a value explicitly

- ``init(numberValue:)``
- ``init(stringValue:)``
- ``init(boolValue:)``
- ``init(structValue:)``
- ``init(listValue:)``

### Reading the value

- ``kind``
- ``OneOf_Kind``
- ``numberValue``
- ``stringValue``
- ``boolValue``
- ``structValue``
- ``listValue``
- ``nullValue``
- ``Google_Protobuf_NullValue``

### Satisfying literal-protocol requirements

- ``BooleanLiteralType``
- ``ExtendedGraphemeClusterLiteralType``
- ``FloatLiteralType``
- ``IntegerLiteralType``
- ``StringLiteralType``
- ``UnicodeScalarLiteralType``
- ``init(unicodeScalarLiteral:)``
- ``init(extendedGraphemeClusterLiteral:)``

### Handling unknown fields

- ``unknownFields``
