// ProtobufRuntime/Sources/Protobuf/ProtobufDebugDescription.swift - debugDescription support
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// We treat the debugDescription as a serialization process, using the
/// same traversal machinery that is used by binary and JSON serialization.
///
// -----------------------------------------------------------------------------

import Swift

public struct ProtobufDebugDescriptionVisitor: ProtobufVisitor {
    public var description = ""
    private var separator = ""

    public init() {}

    public init(message: ProtobufMessageBase) {
        description.append(message.swiftClassName)
        description.append("(")
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
        description.append(")")
    }

    public init(group: ProtobufGroupBase) {
        description.append(group.swiftClassName)
        description.append("(")
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try group.traverse(visitor: &visitor)
        }
        description.append(")")
    }

    public mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws -> ()) {
        var visitor: ProtobufVisitor = self
        do {
            try clause(&visitor)
            description = (visitor as! ProtobufDebugDescriptionVisitor).description
        } catch let e {
            description = (visitor as! ProtobufDebugDescriptionVisitor).description
            description.append("\(e)")
        }
    }

    mutating public func visitUnknown(bytes: [UInt8]) {}

    mutating public func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        separator = ","
        description.append(swiftFieldName + ":" + String(reflecting: value))
    }

    mutating public func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            arraySeparator = ","
            description.append(String(reflecting: v))
        }
        description.append("]")
        separator = ","
    }

    mutating public func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            arraySeparator = ","
            description.append(String(reflecting: v))
        }
        description.append("]")
        separator = ","
    }

    mutating public func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let messageDescription = ProtobufDebugDescriptionVisitor(message: value).description
        description.append(messageDescription)
        separator = ","
    }

    mutating public func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            let messageDescription = ProtobufDebugDescriptionVisitor(message: v).description
            description.append(messageDescription)
            arraySeparator = ","
        }
        description.append("]")
        separator = ","
   }


    mutating public func visitSingularGroupField<G: ProtobufGroup>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let groupDescription = ProtobufDebugDescriptionVisitor(group: value).description
        description.append(groupDescription)
        separator = ","
    }

    mutating public func visitRepeatedGroupField<G: ProtobufGroup>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            let groupDescription = ProtobufDebugDescriptionVisitor(group: v).description
            description.append(groupDescription)
            arraySeparator = ","
        }
        description.append("]")
        separator = ","
    }

    mutating public func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":{")
        var mapSeparator = ""
        for (k,v) in value {
            description.append(mapSeparator)
            description.append(String(reflecting: k))
            description.append(":")
            description.append(String(reflecting: v))
            mapSeparator = ","
        }
        description.append("}")
        separator = ","
    }
}
