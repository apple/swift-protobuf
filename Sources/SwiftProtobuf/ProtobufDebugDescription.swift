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

struct ProtobufDebugDescriptionVisitor: ProtobufVisitor {
    var description = ""
    private var separator = ""

    private let nameResolver: (Int) -> String?

    init(message: ProtobufMessageBase) {
        self.nameResolver =
            ProtoNameResolvers.swiftFieldNameResolver(for: message)

        description.append(message.swiftClassName)
        description.append("(")
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
        description.append(")")
    }

    mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws -> ()) {
        var visitor: ProtobufVisitor = self
        do {
            try clause(&visitor)
            description = (visitor as! ProtobufDebugDescriptionVisitor).description
        } catch let e {
            description = (visitor as! ProtobufDebugDescriptionVisitor).description
            description.append("\(e)")
        }
    }

    mutating func visitUnknown(bytes: Data) {}

    mutating func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
        description.append(separator)
        separator = ","
        description.append(swiftFieldName + ":" + String(reflecting: value))
    }

    mutating func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
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

    mutating func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
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

    mutating func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let messageDescription = ProtobufDebugDescriptionVisitor(message: value).description
        description.append(messageDescription)
        separator = ","
    }

    mutating func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
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


    mutating func visitSingularGroupField<G: ProtobufMessage>(value: G, protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":")
        let groupDescription = ProtobufDebugDescriptionVisitor(message: value).description
        description.append(groupDescription)
        separator = ","
    }

    mutating func visitRepeatedGroupField<G: ProtobufMessage>(value: [G], protoFieldNumber: Int) throws {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
        description.append(separator)
        description.append(swiftFieldName)
        description.append(":[")
        var arraySeparator = ""
        for v in value {
            description.append(arraySeparator)
            let groupDescription = ProtobufDebugDescriptionVisitor(message: v).description
            description.append(groupDescription)
            arraySeparator = ","
        }
        description.append("]")
        separator = ","
    }

    mutating func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int) throws where KeyType.BaseType: Hashable {
        let swiftFieldName = self.swiftFieldName(withNumber: protoFieldNumber)
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

    /// Helper function that stringifies the field number if the name could not
    /// be resolved.
    private func swiftFieldName(withNumber number: Int) -> String {
        return nameResolver(number) ?? String(number)
    }
}
