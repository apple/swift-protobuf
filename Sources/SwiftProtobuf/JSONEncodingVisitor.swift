// Sources/SwiftProtobuf/JSONEncodingVisitor.swift - JSON encoding visitor
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor that writes a message in JSON format.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON format.
internal struct JSONEncodingVisitor: Visitor {

    private var encoder = JSONEncoder()
    private var nameMap: _NameMap
    private var extensions: ExtensionFieldValueSet?
    private let options: JSONEncodingOptions

    /// The JSON text produced by the visitor, as raw UTF8 bytes.
    var dataResult: [UInt8] {
        encoder.dataResult
    }

    /// The JSON text produced by the visitor, as a String.
    internal var stringResult: String {
        encoder.stringResult
    }

    /// Creates a new visitor for serializing a message of the given type to JSON
    /// format.
    init(type: any Message.Type, options: JSONEncodingOptions) throws {
        if let nameProviding = type as? any _ProtoNameProviding.Type {
            self.nameMap = nameProviding._protobuf_nameMap
        } else {
            throw JSONEncodingError.missingFieldNames
        }
        self.options = options
    }

    mutating func startArray() {
        encoder.startArray()
    }

    mutating func endArray() {
        encoder.endArray()
    }

    mutating func startObject(message: any Message) {
        self.extensions = (message as? (any ExtensibleMessage))?._protobuf_extensionFieldValues
        encoder.startObject()
    }

    mutating func startArrayObject(message: any Message) {
        self.extensions = (message as? (any ExtensibleMessage))?._protobuf_extensionFieldValues
        encoder.startArrayObject()
    }

    mutating func endObject() {
        encoder.endObject()
    }

    mutating func encodeField(name: String, stringValue value: String) {
        encoder.startField(name: name)
        encoder.putStringValue(value: value)
    }

    mutating func encodeField(name: String, jsonText text: String) {
        encoder.startField(name: name)
        encoder.append(text: text)
    }

    mutating func visitUnknown(bytes: Data) throws {
        // JSON encoding has no provision for carrying proto2 unknown fields.
    }

    mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putFloatValue(value: value)
    }

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putDoubleValue(value: value)
    }

    mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putNonQuotedInt32(value: value)
    }

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        options.alwaysPrintInt64sAsNumbers
            ? encoder.putNonQuotedInt64(value: value)
            : encoder.putQuotedInt64(value: value)
    }

    mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putNonQuotedUInt32(value: value)
    }

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        options.alwaysPrintInt64sAsNumbers
            ? encoder.putNonQuotedUInt64(value: value)
            : encoder.putQuotedUInt64(value: value)
    }

    mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putNonQuotedUInt32(value: value)
    }

    mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putNonQuotedInt32(value: value)
    }

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putNonQuotedBoolValue(value: value)
    }

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putStringValue(value: value)
    }

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        encoder.putBytesValue(value: value)
    }

    private mutating func _visitRepeated<T>(
        value: [T],
        fieldNumber: Int,
        encode: (inout JSONEncoder, T) throws -> Void
    ) throws {
        assert(!value.isEmpty)
        try startField(for: fieldNumber)
        var comma = false
        encoder.startArray()
        for v in value {
            if comma {
                encoder.comma()
            }
            comma = true
            try encode(&encoder, v)
        }
        encoder.endArray()
    }

    mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        if let e = value as? (any _CustomJSONCodable) {
            let json = try e.encodedJSONString(options: options)
            encoder.append(text: json)
        } else if !options.alwaysPrintEnumsAsInts, let n = value.name {
            encoder.appendQuoted(name: n)
        } else {
            encoder.putEnumInt(value: value.rawValue)
        }
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        try startField(for: fieldNumber)
        if let m = value as? (any _CustomJSONCodable) {
            let json = try m.encodedJSONString(options: options)
            encoder.append(text: json)
        } else if let newNameMap = (M.self as? any _ProtoNameProviding.Type)?._protobuf_nameMap {
            // Preserve outer object's name and extension maps; restore them before returning
            let oldNameMap = self.nameMap
            let oldExtensions = self.extensions
            // Install inner object's name and extension maps
            self.nameMap = newNameMap
            startObject(message: value)
            try value.traverse(visitor: &self)
            endObject()
            self.nameMap = oldNameMap
            self.extensions = oldExtensions
        } else {
            throw JSONEncodingError.missingFieldNames
        }
    }

    mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
        try visitSingularMessageField(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: Float) in
            encoder.putFloatValue(value: v)
        }
    }

    mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: Double) in
            encoder.putDoubleValue(value: v)
        }
    }

    mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: Int32) in
            encoder.putNonQuotedInt32(value: v)
        }
    }

    mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
        if options.alwaysPrintInt64sAsNumbers {
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: Int64) in
                encoder.putNonQuotedInt64(value: v)
            }
        } else {
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: Int64) in
                encoder.putQuotedInt64(value: v)
            }
        }
    }

    mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: UInt32) in
            encoder.putNonQuotedUInt32(value: v)
        }
    }

    mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        if options.alwaysPrintInt64sAsNumbers {
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: UInt64) in
                encoder.putNonQuotedUInt64(value: v)
            }
        } else {
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: UInt64) in
                encoder.putQuotedUInt64(value: v)
            }
        }
    }

    mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        try visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        try visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: Bool) in
            encoder.putNonQuotedBoolValue(value: v)
        }
    }

    mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: String) in
            encoder.putStringValue(value: v)
        }
    }

    mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
        try _visitRepeated(value: value, fieldNumber: fieldNumber) {
            (encoder: inout JSONEncoder, v: Data) in
            encoder.putBytesValue(value: v)
        }
    }

    mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        if let _ = E.self as? any _CustomJSONCodable.Type {
            let options = self.options
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: E) throws in
                let e = v as! (any _CustomJSONCodable)
                let json = try e.encodedJSONString(options: options)
                encoder.append(text: json)
            }
        } else {
            let alwaysPrintEnumsAsInts = options.alwaysPrintEnumsAsInts
            try _visitRepeated(value: value, fieldNumber: fieldNumber) {
                (encoder: inout JSONEncoder, v: E) throws in
                if !alwaysPrintEnumsAsInts, let n = v.name {
                    encoder.appendQuoted(name: n)
                } else {
                    encoder.putEnumInt(value: v.rawValue)
                }
            }
        }
    }

    mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        try startField(for: fieldNumber)
        var comma = false
        encoder.startArray()
        if let _ = M.self as? any _CustomJSONCodable.Type {
            for v in value {
                if comma {
                    encoder.comma()
                }
                comma = true
                let json = try v.jsonString(options: options)
                encoder.append(text: json)
            }
        } else if let newNameMap = (M.self as? any _ProtoNameProviding.Type)?._protobuf_nameMap {
            // Preserve name and extension maps for outer object
            let oldNameMap = self.nameMap
            let oldExtensions = self.extensions
            self.nameMap = newNameMap
            for v in value {
                startArrayObject(message: v)
                try v.traverse(visitor: &self)
                encoder.endObject()
            }
            // Restore outer object's name and extension maps before returning
            self.nameMap = oldNameMap
            self.extensions = oldExtensions
        } else {
            throw JSONEncodingError.missingFieldNames
        }
        encoder.endArray()
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
        try visitRepeatedMessageField(value: value, fieldNumber: fieldNumber)
    }

    // Packed fields are handled the same as non-packed fields, so JSON just
    // relies on the default implementations in Visitor.swift

    mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        try iterateAndEncode(map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan) {
            (visitor: inout JSONMapEncodingVisitor, key, value) throws -> Void in
            try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
            try ValueType.visitSingular(value: value, fieldNumber: 2, with: &visitor)
        }
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where ValueType.RawValue == Int {
        try iterateAndEncode(map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan) {
            (visitor: inout JSONMapEncodingVisitor, key, value) throws -> Void in
            try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
            try visitor.visitSingularEnumField(value: value, fieldNumber: 2)
        }
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        try iterateAndEncode(map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan) {
            (visitor: inout JSONMapEncodingVisitor, key, value) throws -> Void in
            try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
            try visitor.visitSingularMessageField(value: value, fieldNumber: 2)
        }
    }

    /// Helper to encapsulate the common structure of iterating over a map
    /// and encoding the keys and values.
    private mutating func iterateAndEncode<K, V>(
        map: [K: V],
        fieldNumber: Int,
        isOrderedBefore: (K, K) -> Bool,
        encode: (inout JSONMapEncodingVisitor, K, V) throws -> Void
    ) throws {
        try startField(for: fieldNumber)
        encoder.append(text: "{")
        var mapVisitor = JSONMapEncodingVisitor(encoder: JSONEncoder(), options: options)
        if options.useDeterministicOrdering {
            for (k, v) in map.sorted(by: { isOrderedBefore($0.0, $1.0) }) {
                try encode(&mapVisitor, k, v)
            }
        } else {
            for (k, v) in map {
                try encode(&mapVisitor, k, v)
            }
        }
        encoder.append(utf8Bytes: mapVisitor.bytesResult)
        encoder.append(text: "}")
    }

    /// Helper function that throws an error if the field number could not be
    /// resolved.
    private mutating func startField(for number: Int) throws {
        let name: _NameMap.Name?

        if options.preserveProtoFieldNames {
            name = nameMap.names(for: number)?.proto
        } else {
            name = nameMap.names(for: number)?.json
        }

        if let name = name {
            encoder.startField(name: name)
        } else if let name = extensions?[number]?.protobufExtension.fieldName {
            encoder.startExtensionField(name: name)
        } else {
            throw JSONEncodingError.missingFieldNames
        }
    }
}
