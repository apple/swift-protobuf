# ``Visitor``

## Topics

### Visiting singular integer fields

- ``visitSingularInt32Field(value:fieldNumber:)``
- ``visitSingularInt32Field(value:fieldNumber:)-53e5l``
- ``visitSingularSInt32Field(value:fieldNumber:)``
- ``visitSingularSInt32Field(value:fieldNumber:)-3o3kk``
- ``visitSingularSFixed32Field(value:fieldNumber:)``
- ``visitSingularSFixed32Field(value:fieldNumber:)-61ywg``
- ``visitSingularUInt32Field(value:fieldNumber:)``
- ``visitSingularUInt32Field(value:fieldNumber:)-444mp``
- ``visitSingularFixed32Field(value:fieldNumber:)``
- ``visitSingularFixed32Field(value:fieldNumber:)-9974s``
- ``visitSingularInt64Field(value:fieldNumber:)``
- ``visitSingularSInt64Field(value:fieldNumber:)``
- ``visitSingularSInt64Field(value:fieldNumber:)-770n``
- ``visitSingularSFixed64Field(value:fieldNumber:)``
- ``visitSingularSFixed64Field(value:fieldNumber:)-1iy3b``
- ``visitSingularUInt64Field(value:fieldNumber:)``
- ``visitSingularFixed64Field(value:fieldNumber:)``
- ``visitSingularFixed64Field(value:fieldNumber:)-8z0go``

### Visiting singular boolean and floating-point fields

- ``visitSingularBoolField(value:fieldNumber:)``
- ``visitSingularFloatField(value:fieldNumber:)``
- ``visitSingularFloatField(value:fieldNumber:)-807k``
- ``visitSingularDoubleField(value:fieldNumber:)``

### Visiting singular string and bytes fields

- ``visitSingularStringField(value:fieldNumber:)``
- ``visitSingularBytesField(value:fieldNumber:)``

### Visiting singular enum, message, and group fields

- ``visitSingularEnumField(value:fieldNumber:)``
- ``visitSingularMessageField(value:fieldNumber:)``
- ``visitSingularGroupField(value:fieldNumber:)``
- ``visitSingularGroupField(value:fieldNumber:)-477b7``

### Visiting repeated integer fields

- ``visitRepeatedInt32Field(value:fieldNumber:)``
- ``visitRepeatedInt32Field(value:fieldNumber:)-4bcup``
- ``visitRepeatedSInt32Field(value:fieldNumber:)``
- ``visitRepeatedSInt32Field(value:fieldNumber:)-36w8l``
- ``visitRepeatedSFixed32Field(value:fieldNumber:)``
- ``visitRepeatedSFixed32Field(value:fieldNumber:)-7ap6n``
- ``visitRepeatedUInt32Field(value:fieldNumber:)``
- ``visitRepeatedUInt32Field(value:fieldNumber:)-1hvt2``
- ``visitRepeatedFixed32Field(value:fieldNumber:)``
- ``visitRepeatedFixed32Field(value:fieldNumber:)-9vjyh``
- ``visitRepeatedInt64Field(value:fieldNumber:)``
- ``visitRepeatedInt64Field(value:fieldNumber:)-87a2b``
- ``visitRepeatedSInt64Field(value:fieldNumber:)``
- ``visitRepeatedSInt64Field(value:fieldNumber:)-5vlbc``
- ``visitRepeatedSFixed64Field(value:fieldNumber:)``
- ``visitRepeatedSFixed64Field(value:fieldNumber:)-2kceg``
- ``visitRepeatedUInt64Field(value:fieldNumber:)``
- ``visitRepeatedUInt64Field(value:fieldNumber:)-1298n``
- ``visitRepeatedFixed64Field(value:fieldNumber:)``
- ``visitRepeatedFixed64Field(value:fieldNumber:)-35ex2``

### Visiting repeated boolean and floating-point fields

- ``visitRepeatedBoolField(value:fieldNumber:)``
- ``visitRepeatedBoolField(value:fieldNumber:)-986u0``
- ``visitRepeatedFloatField(value:fieldNumber:)``
- ``visitRepeatedFloatField(value:fieldNumber:)-ffgs``
- ``visitRepeatedDoubleField(value:fieldNumber:)``
- ``visitRepeatedDoubleField(value:fieldNumber:)-2mgah``

### Visiting repeated string and bytes fields

- ``visitRepeatedStringField(value:fieldNumber:)``
- ``visitRepeatedStringField(value:fieldNumber:)-kope``
- ``visitRepeatedBytesField(value:fieldNumber:)``
- ``visitRepeatedBytesField(value:fieldNumber:)-40m51``

### Visiting repeated enum, message, and group fields

- ``visitRepeatedEnumField(value:fieldNumber:)``
- ``visitRepeatedEnumField(value:fieldNumber:)-33gkn``
- ``visitRepeatedMessageField(value:fieldNumber:)``
- ``visitRepeatedMessageField(value:fieldNumber:)-3awfz``
- ``visitRepeatedGroupField(value:fieldNumber:)``
- ``visitRepeatedGroupField(value:fieldNumber:)-7i05d``

### Visiting packed integer fields

- ``visitPackedInt32Field(value:fieldNumber:)``
- ``visitPackedInt32Field(value:fieldNumber:)-9ykrr``
- ``visitPackedSInt32Field(value:fieldNumber:)``
- ``visitPackedSInt32Field(value:fieldNumber:)-yqio``
- ``visitPackedSFixed32Field(value:fieldNumber:)``
- ``visitPackedSFixed32Field(value:fieldNumber:)-8mszm``
- ``visitPackedUInt32Field(value:fieldNumber:)``
- ``visitPackedUInt32Field(value:fieldNumber:)-2k0yl``
- ``visitPackedFixed32Field(value:fieldNumber:)``
- ``visitPackedFixed32Field(value:fieldNumber:)-8lc04``
- ``visitPackedInt64Field(value:fieldNumber:)``
- ``visitPackedInt64Field(value:fieldNumber:)-8ni1s``
- ``visitPackedSInt64Field(value:fieldNumber:)``
- ``visitPackedSInt64Field(value:fieldNumber:)-8sq10``
- ``visitPackedSFixed64Field(value:fieldNumber:)``
- ``visitPackedSFixed64Field(value:fieldNumber:)-43e6n``
- ``visitPackedUInt64Field(value:fieldNumber:)``
- ``visitPackedUInt64Field(value:fieldNumber:)-5a50w``
- ``visitPackedFixed64Field(value:fieldNumber:)``
- ``visitPackedFixed64Field(value:fieldNumber:)-h10r``

### Visiting packed boolean, floating-point, and enum fields

- ``visitPackedBoolField(value:fieldNumber:)``
- ``visitPackedBoolField(value:fieldNumber:)-3ww5v``
- ``visitPackedFloatField(value:fieldNumber:)``
- ``visitPackedFloatField(value:fieldNumber:)-6gj2b``
- ``visitPackedDoubleField(value:fieldNumber:)``
- ``visitPackedDoubleField(value:fieldNumber:)-3te12``
- ``visitPackedEnumField(value:fieldNumber:)``
- ``visitPackedEnumField(value:fieldNumber:)-2vm2n``

### Visiting map and extension fields

- ``visitMapField(fieldType:value:fieldNumber:)-(_ProtobufMap<KeyType,ValueType>.Type,_,_)``
- ``visitMapField(fieldType:value:fieldNumber:)-(_ProtobufEnumMap<KeyType,ValueType>.Type,_,_)``
- ``visitMapField(fieldType:value:fieldNumber:)-(_ProtobufMessageMap<KeyType,ValueType>.Type,_,_)``
- ``visitExtensionFields(fields:start:end:)``
- ``visitExtensionFields(fields:start:end:)-3bsug``
- ``visitExtensionFieldsAsMessageSet(fields:start:end:)``
- ``visitExtensionFieldsAsMessageSet(fields:start:end:)-4plt4``

### Visiting unknown fields

- ``visitUnknown(bytes:)``
