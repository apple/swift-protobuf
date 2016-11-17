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
import Foundation

struct DebugDescriptionVisitor: Visitor {
    var description = ""
    private var separator = ""

    init() {}

    init(message: Message) {
        description.append(message.swiftClassName)
        description.append("(")
        withAbstractVisitor {(visitor: inout Visitor) in
            try message.traverse(visitor: &visitor)
        }
        description.append(")")
    }

  mutating func withAbstractVisitor(clause: (inout Visitor) throws -> ()) {
        var visitor: Visitor = self
        do {
            try clause(&visitor)
            description = (visitor as! DebugDescriptionVisitor).description
        } catch let e {
            description = (visitor as! DebugDescriptionVisitor).description
            description.append("\(e)")
        }
    }

    mutating func visitUnknown(bytes: Data) {}

    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        separator = ","
        description.append(swiftFieldName + ":" + String(reflecting: value))
    }

    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
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

    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
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

    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let messageDescription = DebugDescriptionVisitor(message: value).description
        description.append(messageDescription)
        separator = ","
    }

    mutating func visitRepeatedMessageField<M: Message>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            let messageDescription = DebugDescriptionVisitor(message: v).description
            description.append(messageDescription)
            arraySeparator = ","
        }
        description.append("]")
        separator = ","
   }


    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let groupDescription = DebugDescriptionVisitor(message: value).description
        description.append(groupDescription)
        separator = ","
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            let groupDescription = DebugDescriptionVisitor(message: v).description
            description.append(groupDescription)
            arraySeparator = ","
        }
        description.append("]")
        separator = ","
    }

    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: Map<KeyType, ValueType>.Type, value: Map<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
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
