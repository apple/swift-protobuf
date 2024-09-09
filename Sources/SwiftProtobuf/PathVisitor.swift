// Sources/SwiftProtobuf/PathVisitor.swift - Path visitor
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor which captures a pair of paths and their values.
///
// -----------------------------------------------------------------------------

import Foundation

// Visitor captures all values of message with their paths
struct PathVisitor<T: Message>: Visitor {

    // The path contains parent components
    private let prevPath: String?

    // Captured values after visiting will be stored in this property
    private(set) var values: [String: Any] = [:]

    internal init(prevPath: String? = nil) {
        self.prevPath = prevPath
    }

    mutating private func visit(_ value: Any, fieldNumber: Int) {
        guard let name = T.name(for: fieldNumber) else {
            return
        }
        if let prevPath {
            values["\(prevPath).\(name)"] = value
        } else {
            values[name] = value
        }
    }

    mutating private func visitMessageField<M: Message>(
        _ value: M,
        fieldNumber: Int
    ) {
        guard var path = T.name(for: fieldNumber) else {
            return
        }
        if let prevPath {
            path = "\(prevPath).\(path)"
        }
        values[path] = value
        var visitor = PathVisitor<M>(prevPath: path)
        try? value.traverse(visitor: &visitor)
        values.merge(visitor.values) { _, new in
            new
        }
    }

    mutating func visitUnknown(bytes: Data) throws {}

    mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        visitMessageField(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
        visitMessageField(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedMessageField<M>(value: [M], fieldNumber: Int) throws where M: Message {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: MapValueType {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: Enum, ValueType.RawValue == Int {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: Hashable, ValueType: Message {
        visit(value, fieldNumber: fieldNumber)
    }
}
