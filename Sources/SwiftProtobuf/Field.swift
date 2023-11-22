//
//  Field.swift
//  
//
//  Created by Max Rabiciuc on 11/14/23.
//

import Foundation

/// Represents a field on a given `Message` type
///
/// Used to enable `Visitor` traversal of messages
public struct Field<M: Message> {

    private let field: any FieldItem<M>
    private let fieldNumber: Int
    private let isDefault: (M) -> Bool
    
    /// Traveses the given message instance using the given visitor
    internal func traverse<V: Visitor>(message: M, visitor: inout V) throws {
        if !isDefault(message) {
            try field.traverse(message: message, fieldNumber: fieldNumber, visitor: &visitor)
        }
    }
    
    public static func singularFloat(_ getValue: @escaping (M) -> Float, fieldNumber: Int, defaultValue: Float = 0) -> Self {
        Self(field: SingularFloatField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularFloat(_ getValue: @escaping (M) -> Float, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularFloatField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularDouble(_ getValue: @escaping (M) -> Double, fieldNumber: Int, defaultValue: Double = 0) -> Self {
        Self(field: SingularDoubleField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularDouble(_ getValue: @escaping (M) -> Double, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularDoubleField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularInt32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, defaultValue: Int32 = 0) -> Self {
        Self(field: SingularInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularInt32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularInt64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, defaultValue: Int64 = 0) -> Self {
        Self(field: SingularInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularInt64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularUInt32(_ getValue: @escaping (M) -> UInt32, fieldNumber: Int, defaultValue: UInt32 = 0) -> Self {
        Self(field: SingularUInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularUInt32(_ getValue: @escaping (M) -> UInt32, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularUInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularUInt64(_ getValue: @escaping (M) -> UInt64, fieldNumber: Int, defaultValue: UInt64 = 0) -> Self {
        Self(field: SingularUInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularUInt64(_ getValue: @escaping (M) -> UInt64, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularUInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularSInt32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, defaultValue: Int32 = 0) -> Self {
        Self(field: SingularSInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularSInt32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularSInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularSInt64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, defaultValue: Int64 = 0) -> Self {
        Self(field: SingularSInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularSInt64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularSInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularFixed32(_ getValue: @escaping (M) -> UInt32, fieldNumber: Int, defaultValue: UInt32 = 0) -> Self {
        Self(field: SingularFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularFixed32(_ getValue: @escaping (M) -> UInt32, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularFixed64(_ getValue: @escaping (M) -> UInt64, fieldNumber: Int, defaultValue: UInt64 = 0) -> Self {
        Self(field: SingularFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularFixed64(_ getValue: @escaping (M) -> UInt64, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularSFixed32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, defaultValue: Int32 = 0) -> Self {
        Self(field: SingularSFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularSFixed32(_ getValue: @escaping (M) -> Int32, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularSFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularSFixed64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, defaultValue: Int64 = 0) -> Self {
        Self(field: SingularSFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularSFixed64(_ getValue: @escaping (M) -> Int64, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularSFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularBool(_ getValue: @escaping (M) -> Bool, fieldNumber: Int, defaultValue: Bool = false) -> Self {
        Self(field: SingularBoolField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularBool(_ getValue: @escaping (M) -> Bool, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularBoolField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularString(_ getValue: @escaping (M) -> String, fieldNumber: Int, defaultValue: String = "") -> Self {
        Self(field: SingularStringField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularString(_ getValue: @escaping (M) -> String, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularStringField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    public static func singularBytes(_ getValue: @escaping (M) -> Data, fieldNumber: Int, defaultValue: Data = Data()) -> Self {
        Self(field: SingularBytesField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularBytes(_ getValue: @escaping (M) -> Data, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularBytesField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }

    public static func repeatedFloat(_ getValue: @escaping (M) -> [Float], fieldNumber: Int) -> Self {
        Self(field: RepeatedFloatField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedDouble(_ getValue: @escaping (M) -> [Double], fieldNumber: Int) -> Self {
        Self(field: RepeatedDoubleField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedInt32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: RepeatedInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedInt64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: RepeatedInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedUInt32(_ getValue: @escaping (M) -> [UInt32], fieldNumber: Int) -> Self {
        Self(field: RepeatedUInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedUInt64(_ getValue: @escaping (M) -> [UInt64], fieldNumber: Int) -> Self {
        Self(field: RepeatedUInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedSInt32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: RepeatedSInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedSInt64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: RepeatedSInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedFixed32(_ getValue: @escaping (M) -> [UInt32], fieldNumber: Int) -> Self {
        Self(field: RepeatedFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedFixed64(_ getValue: @escaping (M) -> [UInt64], fieldNumber: Int) -> Self {
        Self(field: RepeatedFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedSFixed32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: RepeatedSFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedSFixed64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: RepeatedSFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedBool(_ getValue: @escaping (M) -> [Bool], fieldNumber: Int) -> Self {
        Self(field: RepeatedBoolField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedString(_ getValue: @escaping (M) -> [String], fieldNumber: Int) -> Self {
        Self(field: RepeatedStringField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedBytes(_ getValue: @escaping (M) -> [Data], fieldNumber: Int) -> Self {
        Self(field: RepeatedBytesField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedFloat(_ getValue: @escaping (M) -> [Float], fieldNumber: Int) -> Self {
        Self(field: PackedFloatField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedDouble(_ getValue: @escaping (M) -> [Double], fieldNumber: Int) -> Self {
        Self(field: PackedDoubleField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedInt32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: PackedInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedInt64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: PackedInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedUInt32(_ getValue: @escaping (M) -> [UInt32], fieldNumber: Int) -> Self {
        Self(field: PackedUInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedUInt64(_ getValue: @escaping (M) -> [UInt64], fieldNumber: Int) -> Self {
        Self(field: PackedUInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedSInt32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: PackedSInt32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedSInt64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: PackedSInt64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedFixed32(_ getValue: @escaping (M) -> [UInt32], fieldNumber: Int) -> Self {
        Self(field: PackedFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedFixed64(_ getValue: @escaping (M) -> [UInt64], fieldNumber: Int) -> Self {
        Self(field: PackedFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedSFixed32(_ getValue: @escaping (M) -> [Int32], fieldNumber: Int) -> Self {
        Self(field: PackedSFixed32Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedSFixed64(_ getValue: @escaping (M) -> [Int64], fieldNumber: Int) -> Self {
        Self(field: PackedSFixed64Field(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedBool(_ getValue: @escaping (M) -> [Bool], fieldNumber: Int) -> Self {
        Self(field: PackedBoolField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func singularEnum<E: Enum>(_ getValue: @escaping (M) -> E, fieldNumber: Int, defaultValue: E) -> Self {
        Self(field: SingularEnumField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0) == defaultValue })
    }

    public static func singularEnum<E: Enum>(_ getValue: @escaping (M) -> E, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularEnumField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }

    public static func singularMessage<MessageType: Message>(_ getValue: @escaping (M) -> MessageType, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularMessageField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }
    
    public static func singularGroup<MessageType: Message>(_ getValue: @escaping (M) -> MessageType, fieldNumber: Int, isUnset: @escaping (M) -> Bool) -> Self {
        Self(field: SingularGroupField(getValue: getValue), fieldNumber: fieldNumber, isDefault: isUnset)
    }

    public static func repeatedEnum<E: Enum>(_ getValue: @escaping (M) -> [E], fieldNumber: Int) -> Self {
        Self(field: RepeatedEnumField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func packedEnum<E: Enum>(_ getValue: @escaping (M) -> [E], fieldNumber: Int) -> Self {
        Self(field: PackedEnumField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }

    public static func repeatedMessage<MessageType: Message>(_ getValue: @escaping (M) -> [MessageType], fieldNumber: Int) -> Self {
        Self(field: RepeatedMessageField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func repeatedGroup<MessageType: Message>(_ getValue: @escaping (M) -> [MessageType], fieldNumber: Int) -> Self {
        Self(field: RepeatedGroupField(getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func map<KeyType, ValueType: MapValueType>(type: _ProtobufMap<KeyType, ValueType>.Type, _ getValue: @escaping (M) -> [KeyType.BaseType: ValueType.BaseType], fieldNumber: Int) -> Self {
        Self(field: MapField(fieldType: type, getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func map<KeyType, ValueType: Enum>(type: _ProtobufEnumMap<KeyType, ValueType>.Type, _ getValue: @escaping (M) -> [KeyType.BaseType: ValueType], fieldNumber: Int) -> Self where ValueType.RawValue == Int {
        Self(field: EnumMapField(fieldType: type, getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func map<KeyType, ValueType: Message & Hashable>(type: _ProtobufMessageMap<KeyType, ValueType>.Type, _ getValue: @escaping (M) -> [KeyType.BaseType: ValueType], fieldNumber: Int) -> Self {
        Self(field: MessageMapField(fieldType: type, getValue: getValue), fieldNumber: fieldNumber, isDefault: { getValue($0).isEmpty })
    }
    
    public static func oneOf<T>(_ getValue: @escaping (M) -> T?, toConcrete: @escaping (T) -> Field<M>?) -> Self {
        Self(field: OneOfField(getValue: getValue, toConcrete: toConcrete), fieldNumber: .max, isDefault: { getValue($0) == nil })
    }
    
    public static func extensionFields(_ getValue: @escaping (M) -> ExtensionFieldValueSet, start: Int, end: Int) -> Self {
        Self(field: ExtensionFieldsItem(getValue: getValue, start: start, end: end), fieldNumber: .max, isDefault: { _ in false })
    }
    
    public static func extensionFieldsAsMessageSet(_ getValue: @escaping (M) -> ExtensionFieldValueSet, start: Int, end: Int) -> Self {
        Self(field: ExtensionFieldsAsMessageSetItem(getValue: getValue, start: start, end: end), fieldNumber: .max, isDefault: { _ in false })
    }
}

private protocol FieldItem<M> {
    associatedtype M: Message
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws
}

fileprivate struct ExtensionFieldsItem<M: Message>: FieldItem {
    let getValue: (M) -> ExtensionFieldValueSet
    let start: Int
    let end: Int

    func traverse<V>(message: M, fieldNumber: Int, visitor: inout V) throws where V : Visitor {
        try visitor.visitExtensionFields(fields: getValue(message), start: start, end: end)
    }
}

fileprivate struct ExtensionFieldsAsMessageSetItem<M: Message>: FieldItem {
    let getValue: (M) -> ExtensionFieldValueSet
    let start: Int
    let end: Int

    func traverse<V>(message: M, fieldNumber: Int, visitor: inout V) throws where V : Visitor {
        try visitor.visitExtensionFieldsAsMessageSet(fields: getValue(message), start: start, end: end)
    }
}

fileprivate struct OneOfField<M: Message, T>: FieldItem {
    let getValue: (M) -> T?
    let toConcrete: (T) -> Field<M>?
    
    func traverse<V>(message: M, fieldNumber: Int, visitor: inout V) throws where V : Visitor {
        guard let value = getValue(message) else {
            return
        }
        try toConcrete(value)?.traverse(message: message, visitor: &visitor)
    }
}

fileprivate struct MapField<M: Message, KeyType: MapKeyType, ValueType: MapValueType>: FieldItem {
    let fieldType: _ProtobufMap<KeyType, ValueType>.Type
    let getValue: (M) -> [KeyType.BaseType: ValueType.BaseType]

    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitMapField(fieldType: fieldType, value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct EnumMapField<M: Message, KeyType: MapKeyType, ValueType: Enum>: FieldItem where ValueType.RawValue == Int {
    let fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type
    let getValue: (M) -> [KeyType.BaseType: ValueType]

    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitMapField(fieldType: fieldType, value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct MessageMapField<M: Message, KeyType: MapKeyType, ValueType: Message & Hashable>: FieldItem {
    let fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type
    let getValue: (M) -> [KeyType.BaseType: ValueType]

    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitMapField(fieldType: fieldType, value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct SingularFloatField<M: Message>: FieldItem {
    let getValue: (M) -> Float
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularFloatField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularDoubleField<M: Message>: FieldItem {
    let getValue: (M) -> Double
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularDoubleField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> Int32
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> Int64
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularUInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> UInt32
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularUInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularUInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> UInt64
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularUInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularSInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> Int32
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularSInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularSInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> Int64
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularSInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> UInt32
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> UInt64
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularSFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> Int32
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularSFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularSFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> Int64
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularSFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularBoolField<M: Message>: FieldItem {
    let getValue: (M) -> Bool
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularBoolField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularStringField<M: Message>: FieldItem {
    let getValue: (M) -> String
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularStringField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct SingularBytesField<M: Message>: FieldItem {
    let getValue: (M) -> Data
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularBytesField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedFloatField<M: Message>: FieldItem {
    let getValue: (M) -> [Float]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedFloatField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedDoubleField<M: Message>: FieldItem {
    let getValue: (M) -> [Double]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedDoubleField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedUInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedUInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedUInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedUInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedSInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedSInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedSInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedSInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedSFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedSFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedSFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedSFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedBoolField<M: Message>: FieldItem {
    let getValue: (M) -> [Bool]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedBoolField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedStringField<M: Message>: FieldItem {
    let getValue: (M) -> [String]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedStringField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct RepeatedBytesField<M: Message>: FieldItem {
    let getValue: (M) -> [Data]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedBytesField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
fileprivate struct PackedFloatField<M: Message>: FieldItem {
    let getValue: (M) -> [Float]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedFloatField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedDoubleField<M: Message>: FieldItem {
    let getValue: (M) -> [Double]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedDoubleField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedUInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedUInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedUInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedUInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedSInt32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedSInt32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedSInt64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedSInt64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> [UInt64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedSFixed32Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int32]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedSFixed32Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedSFixed64Field<M: Message>: FieldItem {
    let getValue: (M) -> [Int64]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedSFixed64Field(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedBoolField<M: Message>: FieldItem {
    let getValue: (M) -> [Bool]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedBoolField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct SingularMessageField<M: Message, F: Message>: FieldItem {
    let getValue: (M) -> F
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularMessageField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct SingularGroupField<M: Message, F: Message>: FieldItem {
    let getValue: (M) -> F
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularGroupField(value: getValue(message), fieldNumber: fieldNumber)
    }
}


fileprivate struct RepeatedMessageField<M: Message, F: Message>: FieldItem {
    let getValue: (M) -> [F]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedMessageField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct RepeatedGroupField<M: Message, F: Message>: FieldItem {
    let getValue: (M) -> [F]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedGroupField(value: getValue(message), fieldNumber: fieldNumber)
    }
}


fileprivate struct SingularEnumField<M: Message, F: Enum>: FieldItem {
    let getValue: (M) -> F
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitSingularEnumField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct RepeatedEnumField<M: Message, E: Enum>: FieldItem {
    let getValue: (M) -> [E]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitRepeatedEnumField(value: getValue(message), fieldNumber: fieldNumber)
    }
}

fileprivate struct PackedEnumField<M: Message, E: Enum>: FieldItem {
    let getValue: (M) -> [E]
    
    func traverse<V: Visitor>(message: M, fieldNumber: Int, visitor: inout V) throws {
        try visitor.visitPackedEnumField(value: getValue(message), fieldNumber: fieldNumber)
    }
}
