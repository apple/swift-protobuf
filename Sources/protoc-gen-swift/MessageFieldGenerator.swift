// Sources/MessageFieldGenerator.swift - Facts about a single message field
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
/// This code mostly handles the complex mapping between proto types and
/// the types provided by the Swift Protobuf Runtime.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_FieldDescriptorProto {

    var isRepeated: Bool {return label! == .repeated}
    var isOptional: Bool {return label! == .optional}
    var isRequired: Bool {return label! == .required}
    var isMessage: Bool {return type! == .message}
    var isGroup: Bool {return type! == .group}

    var isPackable: Bool {
        switch type! {
        case .string,.bytes,.group,.message:
            return false
        default:
            return label! == .repeated
        }
    }

    func getIsMap(context: Context) -> Bool {
        if type! != .message {return false}
        let m = context.getMessageForPath(path: typeName!)!
        return m.options?.mapEntry ?? false
    }

    func getSwiftBaseType(context: Context) -> String {
        switch type! {
        case .double: return "Double"
        case .float: return "Float"
        case .int64: return "Int64"
        case .uint64: return "UInt64"
        case .int32: return "Int32"
        case .fixed64: return "UInt64"
        case .fixed32: return "UInt32"
        case .bool: return "Bool"
        case .string: return "String"
        case .group: return context.getMessageNameForPath(path: typeName!)!
        case .message: return context.getMessageNameForPath(path: typeName!)!
        case .bytes: return "Data"
        case .uint32: return "UInt32"
        case .enum: return context.getEnumNameForPath(path: typeName!)!
        case .sfixed32: return "Int32"
        case .sfixed64: return "Int64"
        case .sint32: return "Int32"
        case .sint64: return "Int64"
        }
    }

    func getSwiftApiType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName!)!
            let keyField = m.field[0]
            let keyType = keyField.getSwiftBaseType(context: context)
            let valueField = m.field[1]
            let valueType = valueField.getSwiftBaseType(context: context)
            return "Dictionary<" + keyType + "," + valueType + ">"
        }
        switch label! {
        case .repeated: return "[" + getSwiftBaseType(context: context) + "]"
        case .required: return getSwiftBaseType(context: context)
        case .optional:
            if !isProto3 || oneofIndex != nil {
                return getSwiftBaseType(context: context) + "?"
            } else {
                return getSwiftBaseType(context: context)
            }
        }
    }

    func getSwiftStorageType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName!)!
            let keyField = m.field[0]
            let keyType = keyField.getSwiftBaseType(context: context)
            let valueField = m.field[1]
            let valueType = valueField.getSwiftBaseType(context: context)
            return "Dictionary<" + keyType + "," + valueType + ">"
        } else if isRepeated {
            return "[" + getSwiftBaseType(context: context) + "]"
        } else if isMessage || isGroup {
            return getSwiftBaseType(context: context) + "?"
        } else if isProto3 {
            return getSwiftBaseType(context: context)
        } else if isOptional {
            return getSwiftBaseType(context: context) + "?"
        } else {
            return getSwiftBaseType(context: context)
        }
    }

    func getSwiftStorageDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            return "[:]"
        } else if isRepeated {
            return "[]"
        } else if isMessage || isGroup {
            return "nil"
        } else if isProto3 || !isOptional {
            return getSwiftDefaultValue(context: context, isProto3: isProto3)
        } else {
            return "nil"
        }
    }

    func getSwiftDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {return "[:]"}
        if isRepeated {return "[]"}
        if let d = getSwiftProto2DefaultValue(context: context) {
            return d
        }
        switch type! {
        case .bool: return "false"
        case .string: return "\"\""
        case .bytes: return "Data()"
        case .group, .message:
            if isRequired || isProto3 {
                return context.getMessageNameForPath(path: typeName!)! + "()"
            } else {
                return "nil"
            }
        case .enum:
            let e = context.enumByProtoName[typeName!]!
            if e.value.count == 0 {
                return ".None"
            } else {
                let defaultCase = e.value[0].name!
                return context.getSwiftNameForEnumCase(path: typeName!, caseName: defaultCase)
            }
        default: return "0"
        }
    }

    func getTraitsType(context: Context) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName!)!
            let keyField = m.field[0]
            let keyTraits = keyField.getTraitsType(context: context)
            let valueField = m.field[1]
            let valueTraits = valueField.getTraitsType(context: context)
            return "ProtobufMap<" + keyTraits + "," + valueTraits + ">"
        }
        switch type! {
        case .double: return "ProtobufDouble"
        case .float: return "ProtobufFloat"
        case .int64: return "ProtobufInt64"
        case .uint64: return "ProtobufUInt64"
        case .int32: return "ProtobufInt32"
        case .fixed64: return "ProtobufFixed64"
        case .fixed32: return "ProtobufFixed32"
        case .bool: return "ProtobufBool"
        case .string: return "ProtobufString"
        case .group: return getSwiftBaseType(context: context)
        case .message: return getSwiftBaseType(context: context)
        case .bytes: return "ProtobufBytes"
        case .uint32: return "ProtobufUInt32"
        case .enum: return getSwiftBaseType(context: context)
        case .sfixed32: return "ProtobufSFixed32"
        case .sfixed64: return "ProtobufSFixed64"
        case .sint32: return "ProtobufSInt32"
        case .sint64: return "ProtobufSInt64"
        }
    }

    func getSwiftProto2DefaultValue(context: Context) -> String? {
        guard let valueText = defaultValue else {return nil}
        switch type! {
        case .double:
           switch valueText {
           case "inf": return "Double.infinity"
           case "-inf": return "-Double.infinity"
           case "nan": return "Double.nan"
           default: return valueText
           }
        case .float:
           switch valueText {
           case "inf": return "Float.infinity"
           case "-inf": return "-Float.infinity"
           case "nan": return "Float.nan"
           default: return valueText
           }
        case .bool: return valueText
        case .string: return stringToEscapedStringLiteral(valueText)
        case .bytes: return escapedToDataLiteral(valueText)
        case .enum:
            return context.getSwiftNameForEnumCase(path: typeName!, caseName: valueText)
        default: return valueText
        }
    }
}

struct MessageFieldGenerator {
    let descriptor: Google_Protobuf_FieldDescriptorProto
    let oneof: Google_Protobuf_OneofDescriptorProto?
    let messageDescriptor: Google_Protobuf_DescriptorProto
    let jsonName: String
    let swiftName: String
    let swiftStorageName: String
    var protoName: String {return descriptor.name!}
    var number: Int {return Int(descriptor.number!)}
    let path: [Int32]
    let comments: String
    let isProto3: Bool
    let context: Context

    init(descriptor: Google_Protobuf_FieldDescriptorProto,
        path: [Int32],
        messageDescriptor: Google_Protobuf_DescriptorProto,
        file: FileGenerator,
        context: Context)
    {
        self.descriptor = descriptor
        // Note: We would just use descriptor.jsonName provided by protoc, but:
        // 1. That only exists with protoc 3.0 and later
        // 2. It's broken in 3.0 beta 3
        // So we calculate the jsonName ourselves instead.
        // (Which sucks for conformance.)
        self.jsonName = toJsonFieldName(descriptor.name!)
        if descriptor.type! == .group {
            let g = context.getMessageForPath(path: descriptor.typeName!)!
            self.swiftName = sanitizeFieldName(toLowerCamelCase(g.name!))
        } else {
            self.swiftName = sanitizeFieldName(toLowerCamelCase(descriptor.name!))
        }
        if let oneofIndex = descriptor.oneofIndex {
            self.oneof = messageDescriptor.oneofDecl[Int(oneofIndex)]
        } else {
            self.oneof = nil
        }
        self.swiftStorageName = "_" + self.swiftName
        self.messageDescriptor = messageDescriptor
        self.path = path
        self.comments = file.commentsFor(path: path)
        self.isProto3 = file.isProto3
        self.context = context
    }

    var isGroup: Bool {return descriptor.isGroup}
    var isMap: Bool {return descriptor.getIsMap(context: context)}
    var isMessage: Bool {return descriptor.isMessage}
    var isOptional: Bool {return descriptor.isOptional}
    var isPacked: Bool {return descriptor.isPackable && (descriptor.options?.packed ?? isProto3)}
    var isRepeated: Bool {return descriptor.isRepeated}
    var isRequired: Bool {return descriptor.isRequired}

    var name: String {return descriptor.name!}

    var swiftBaseType: String {return descriptor.getSwiftBaseType(context: context)}
    var swiftApiType: String {return descriptor.getSwiftApiType(context: context, isProto3: isProto3)}

    var swiftDefaultValue: String {
        return descriptor.getSwiftDefaultValue(context: context, isProto3: isProto3)
    }

    var swiftProto2DefaultValue: String? {
        return descriptor.getSwiftProto2DefaultValue(context: context)
    }


    var swiftDecoderMethod: String {
        if isMap {
            return "decodeMapField"
        } else {
            let modifier = (isPacked ? "Packed"
                         : isRepeated ? "Repeated"
                         : isProto3 ? "Singular"
                         : isOptional ? "Optional"
                         : "Required")
            let special = isGroup ? "Group"
                         : isMessage ? "Message"
                         : ""
            return "decode\(modifier)\(special)Field"
        }
    }

    var swiftStorageType: String {
        return descriptor.getSwiftStorageType(context: context, isProto3: isProto3)
    }

    var swiftStorageDefaultValue: String {
        return descriptor.getSwiftStorageDefaultValue(context: context, isProto3: isProto3)
    }

    var convenienceInitType: String {
        // if map, return baseType
        if isMap {
            return swiftApiType
        } else if isRepeated {
            return "[\(swiftBaseType)]"
        } else if isProto3 {
            return swiftBaseType + "?"
        } else if isOptional || isGroup || isMessage {
            return swiftBaseType + "?"
        } else {
            return swiftBaseType
        }
    }

    var convenienceInitDefault: String {
        if isMap {
            return "[:]"
        } else if isRepeated {
            return "[]"
        } else if isProto3 || isOptional || isGroup || isMessage {
            return "nil"
        } else {
            return descriptor.getSwiftDefaultValue(context: context, isProto3: isProto3)
        }
    }

    var traitsType: String {return descriptor.getTraitsType(context: context)}

    func generateNotEqual(name: String) -> String {
        if isProto3 || isRepeated || !isOptional {
            return "\(name) != other.\(name)"
        } else if isGroup || isMessage {
            return "(((\(name) != nil && !\(name)!.isEmpty) || (other.\(name) != nil && !other.\(name)!.isEmpty)) && (\(name) == nil || other.\(name) == nil || \(name)! != other.\(name)!))"
        } else if let def = swiftProto2DefaultValue {
            return "(((\(name) != nil && \(name)! != \(def)) || (other.\(name) != nil && other.\(name)! != \(def))) && (\(name) == nil || other.\(name) == nil || \(name)! != other.\(name)!))"
        } else {
            return "((\(name) != nil || other.\(name) != nil) && (\(name) == nil || other.\(name) == nil || \(name)! != other.\(name)!))"
        }
    }

    func generateTopIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        if let oneof = oneof {
            p.print("public var \(swiftName): \(swiftApiType) {\n")
            p.indent()
            p.print("get {\n")
            p.indent()
            p.print("if case .\(swiftName)(let v) = \(oneof.swiftFieldName) {\n")
            p.indent()
            p.print("return v\n")
            p.outdent()
            p.print("}\n")
            p.print("return nil\n")
            p.outdent()
            p.print("}\n")
            p.print("set {\n")
            p.indent()
            p.print("if let newValue = newValue {\n")
            p.indent()
            p.print("\(oneof.swiftFieldName) = .\(swiftName)(newValue)\n")
            p.outdent()
            p.print("} else {\n")
            p.indent()
            p.print("\(oneof.swiftFieldName) = .None\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
            p.print("}\n")
        } else if let defaultClause = swiftProto2DefaultValue {
            p.print("private var \(swiftStorageName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
            p.print("public var \(swiftName): \(swiftApiType) {\n")
            p.indent()
            p.print("get {return \(swiftStorageName) ?? \(defaultClause)}\n")
            p.print("set {\(swiftStorageName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print("public var \(swiftName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
        }
    }

    func generateProxyIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        p.print("public var \(swiftName): \(swiftApiType) {\n")
        p.indent()
        if let oneof = oneof {
            p.print("get {\n")
            p.indent()
            p.print("if let storage = _storage {\n")
            p.indent()
            p.print("if case .\(swiftName)(let v) = storage.\(oneof.swiftStorageFieldName) {\n")
            p.indent()
            p.print("return v\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
            p.print("}\n")
            p.print("return nil\n")
            p.outdent()
            p.print("}\n")
            p.print("set {\n")
            p.indent()
            p.print("if let newValue = newValue {\n")
            p.indent()
            p.print("_uniqueStorage().\(oneof.swiftStorageFieldName) = .\(swiftName)(newValue)\n")
            p.outdent()
            p.print("} else {\n")
            p.indent()
            p.print("_uniqueStorage().\(oneof.swiftStorageFieldName) = .None\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
            p.print("}\n")
        } else {
            let defaultClause: String
            if isRequired {
                defaultClause = " ?? " + swiftDefaultValue
            } else if isMap {
                defaultClause = " ?? [:]"
            } else if isRepeated {
                defaultClause = " ?? []"
            } else if let d = swiftProto2DefaultValue {
                defaultClause = " ?? " + d
            } else if isProto3 {
                defaultClause = " ?? " + swiftDefaultValue
            } else {
                defaultClause = ""
            }
            p.print("get {return _storage?.\(swiftStorageName)\(defaultClause)}\n")
            p.print("set {_uniqueStorage().\(swiftStorageName) = newValue}\n")
        }
        p.outdent()
        p.print("}\n")
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter, prefix: String = "") {
        p.print("case \(number): handled = try setter.\(swiftDecoderMethod)(fieldType: \(traitsType).self, value: &\(prefix)\(swiftName))\n")
    }

    func isNotEmptyTest() -> String {
        if isRepeated {
            return "!\(swiftStorageName).isEmpty"
        } else if isProto3 {
            return "\(swiftStorageName) != \(swiftStorageDefaultValue)"
        } else if isOptional {
            if let def = swiftProto2DefaultValue {
                return "\(swiftStorageName) != nil && \(swiftStorageName)! != \(def)"
            } else {
                return "\(swiftStorageName) != nil"
            }
        } else {
            return "\(swiftStorageName) != \(swiftStorageDefaultValue)"
        }
    }

    func generateTraverse(printer p: inout CodePrinter, prefix: String = "") {
        let visitMethod: String
        if isMap {
            visitMethod = "visitMapField"
        } else {
            let modifier = (isPacked ? "Packed"
                         : isRepeated ? "Repeated"
                         : "Singular")
            let special = isGroup ? "Group"
                         : isMessage ? "Message"
                         : ""
            visitMethod = "visit\(modifier)\(special)Field"
        }

        let fieldTypeArg: String
        if isMap || (!isGroup && !isMessage) {
            fieldTypeArg = "fieldType: \(traitsType).self, "
        } else {
            fieldTypeArg = ""
        }

        let varName: String
        let conditional: Bool
        if isRepeated {
            p.print("if !\(prefix)\(swiftName).isEmpty {\n")
            varName = prefix + swiftName
            conditional = true
        } else if isGroup || isMessage || (isOptional && !isProto3) {
            p.print("if let v = \(prefix)\(swiftName) {\n")
            varName = "v"
            conditional = true
        } else if isOptional && isProto3 {
            let def = swiftDefaultValue
            p.print("if \(prefix)\(swiftName) != \(def) {\n")
            varName = prefix + swiftName
            conditional = true
        } else {
            varName = prefix + swiftName
            conditional = false
        }

        if conditional {
            p.indent()
        }
        p.print("try visitor.\(visitMethod)(\(fieldTypeArg)value: \(varName), protoFieldNumber: \(number), protoFieldName: \"\(protoName)\", jsonFieldName: \"\(jsonName)\", swiftFieldName: \"\(swiftName)\")\n")
        if conditional {
            p.outdent()
            p.print("}\n")
        }
    }
}
