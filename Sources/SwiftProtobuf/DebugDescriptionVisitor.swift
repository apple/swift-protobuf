// Sources/SwiftProtobuf/DebugDescriptionVisitor.swift - debugDescription support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// We treat the debugDescription as a serialization process, using the
/// same traversal machinery that is used by binary and JSON serialization.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that generates the debug description of a message.
///
/// TODO: Remove this and use text format instead.
final class DebugDescriptionVisitor: Visitor {

  var description = ""
  private var separator = ""

  private let nameResolver: (Int) -> String?

  /// Creates a new visitor that generates the debug description for the given
  /// message.
  init(message: Message) {
    self.nameResolver =
      ProtoNameResolvers.swiftFieldNameResolver(for: message)

    description.append(message.swiftClassName)
    description.append("(")
    do {
      try message.traverse(visitor: self)
    } catch let e {
      description.append("\(e)")
    }
    description.append(")")
  }

  func visitUnknown(bytes: Data) {}

  func visitSingularField<S: FieldType>(fieldType: S.Type,
                                        value: S.BaseType,
                                        fieldNumber: Int) throws {
    let swiftFieldName = self.swiftFieldName(for: fieldNumber)
    description.append(separator)
    separator = ","
    description.append(swiftFieldName + ":" + String(reflecting: value))
  }

  func visitRepeatedField<S: FieldType>(fieldType: S.Type,
                                        value: [S.BaseType],
                                        fieldNumber: Int) throws {
    let swiftFieldName = self.swiftFieldName(for: fieldNumber)
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

  func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let swiftFieldName = self.swiftFieldName(for: fieldNumber)
    description.append(separator)
    description.append(swiftFieldName)
    description.append(":")
    let messageDescription = DebugDescriptionVisitor(message: value).description
    description.append(messageDescription)
    separator = ","
  }

  func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
    let swiftFieldName = self.swiftFieldName(for: fieldNumber)
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

  func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: ProtobufMap<KeyType, ValueType>.Type,
    value: ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where KeyType.BaseType: Hashable {
    let swiftFieldName = self.swiftFieldName(for: fieldNumber)
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
  private func swiftFieldName(for number: Int) -> String {
    return nameResolver(number) ?? String(number)
  }
}
