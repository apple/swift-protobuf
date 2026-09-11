# ``Decoder``

## Topics

### Decoding singular integer fields

- ``decodeSingularInt32Field(value:)-(Int32)``
- ``decodeSingularInt32Field(value:)-3bm40``
- ``decodeSingularSInt32Field(value:)-(Int32)``
- ``decodeSingularSInt32Field(value:)-pxoj``
- ``decodeSingularSFixed32Field(value:)-(Int32)``
- ``decodeSingularSFixed32Field(value:)-558yh``
- ``decodeSingularUInt32Field(value:)-(UInt32)``
- ``decodeSingularUInt32Field(value:)-2mjsc``
- ``decodeSingularFixed32Field(value:)-(UInt32)``
- ``decodeSingularFixed32Field(value:)-78gu6``
- ``decodeSingularInt64Field(value:)-(Int64)``
- ``decodeSingularInt64Field(value:)-plbm``
- ``decodeSingularSInt64Field(value:)-(Int64)``
- ``decodeSingularSInt64Field(value:)-2c6w6``
- ``decodeSingularSFixed64Field(value:)-(Int64)``
- ``decodeSingularSFixed64Field(value:)-1oug4``
- ``decodeSingularUInt64Field(value:)-(UInt64)``
- ``decodeSingularUInt64Field(value:)-7rfdp``
- ``decodeSingularFixed64Field(value:)-(UInt64)``
- ``decodeSingularFixed64Field(value:)-1ih0j``

### Decoding singular boolean and floating-point fields

- ``decodeSingularBoolField(value:)-(Bool)``
- ``decodeSingularBoolField(value:)-6tpgm``
- ``decodeSingularFloatField(value:)-(Float)``
- ``decodeSingularFloatField(value:)-egdo``
- ``decodeSingularDoubleField(value:)-(Double)``
- ``decodeSingularDoubleField(value:)-6oix0``

### Decoding singular string and bytes fields

- ``decodeSingularStringField(value:)-(String)``
- ``decodeSingularStringField(value:)-bqhb``
- ``decodeSingularBytesField(value:)-(Data)``
- ``decodeSingularBytesField(value:)-3ijj3``

### Decoding singular enum, message, and group fields

- ``decodeSingularEnumField(value:)-(E)``
- ``decodeSingularEnumField(value:)-7m9pg``
- ``decodeSingularMessageField(value:)``
- ``decodeSingularGroupField(value:)``

### Decoding repeated integer fields

- ``decodeRepeatedInt32Field(value:)``
- ``decodeRepeatedSInt32Field(value:)``
- ``decodeRepeatedSFixed32Field(value:)``
- ``decodeRepeatedUInt32Field(value:)``
- ``decodeRepeatedFixed32Field(value:)``
- ``decodeRepeatedInt64Field(value:)``
- ``decodeRepeatedSInt64Field(value:)``
- ``decodeRepeatedSFixed64Field(value:)``
- ``decodeRepeatedUInt64Field(value:)``
- ``decodeRepeatedFixed64Field(value:)``

### Decoding repeated boolean and floating-point fields

- ``decodeRepeatedBoolField(value:)``
- ``decodeRepeatedFloatField(value:)``
- ``decodeRepeatedDoubleField(value:)``

### Decoding repeated string and bytes fields

- ``decodeRepeatedStringField(value:)``
- ``decodeRepeatedBytesField(value:)``

### Decoding repeated enum, message, and group fields

- ``decodeRepeatedEnumField(value:)``
- ``decodeRepeatedMessageField(value:)``
- ``decodeRepeatedGroupField(value:)``

### Decoding map fields

- ``decodeMapField(fieldType:value:)-(_ProtobufMap<KeyType,ValueType>.Type,_)``
- ``decodeMapField(fieldType:value:)-(_ProtobufEnumMap<KeyType,ValueType>.Type,_)``
- ``decodeMapField(fieldType:value:)-(_ProtobufMessageMap<KeyType,ValueType>.Type,_)``

### Decoding extension fields

- ``decodeExtensionField(values:messageType:fieldNumber:)``
- ``decodeExtensionFieldsAsMessageSet(values:messageType:)``
- ``decodeExtensionFieldsAsMessageSet(values:messageType:)-12gk0``

### Tracking decode state

- ``nextFieldNumber()``
- ``handleConflictingOneOf()``
