// Sources/SwiftProtobuf/HashVisitor.swift - Hashing support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hashing is basically a serialization problem, so we can leverage the
/// generated traversal methods for that.
///
// -----------------------------------------------------------------------------

import Foundation

private let i_2166136261 = Int(bitPattern: 2_166_136_261)
private let i_16777619 = Int(16_777_619)

/// Computes the hash of a message by visiting its fields recursively.
///
/// Note that because this visits every field, it has the potential to be slow
/// for large or deeply nested messages. Users who need to use such messages as
/// dictionary keys or set members can use a wrapper struct around the message
/// and use a custom Hashable implementation that looks at the subset of the
/// message fields they want to include.
internal struct HashVisitor: Visitor {

    internal private(set) var hasher: Hasher

    init(_ hasher: Hasher) {
        self.hasher = hasher
    }

    mutating func visitUnknown(bytes: Data) throws {
        hasher.combine(bytes)
    }

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularEnumField<E: Enum>(
        value: E,
        fieldNumber: Int
    ) {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) {
        hasher.combine(fieldNumber)
        value.hash(into: &hasher)
    }

    mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        for v in value {
            v.hash(into: &hasher)
        }
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
        assert(!value.isEmpty)
        hasher.combine(fieldNumber)
        for v in value {
            v.hash(into: &hasher)
        }
    }

    mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where ValueType.RawValue == Int {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        hasher.combine(fieldNumber)
        hasher.combine(value)
    }
}
