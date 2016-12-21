// Sources/protoc-gen-swift/MessageFieldGenerator.swift - Facts about a single message field
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

    var isRepeated: Bool {return label == .repeated}
    var isMessage: Bool {return type == .message}
    var isGroup: Bool {return type == .group}

    var isPackable: Bool {
        switch type {
        case .string,.bytes,.group,.message:
            return false
        default:
            return label == .repeated
        }
    }

    var bareTypeName: String {
        if typeName.hasPrefix(".") {
            var t = ""
            for c in typeName.characters {
                if c == "." {
                    t = ""
                } else {
                    t.append(c)
                }
            }
            return t
        } else {
            return typeName
        }
    }

    func getIsMap(context: Context) -> Bool {
        if type != .message {return false}
        let m = context.getMessageForPath(path: typeName)!
        return m.options.mapEntry
    }

    func getSwiftBaseType(context: Context) -> String {
        switch type {
        case .double: return "Double"
        case .float: return "Float"
        case .int64: return "Int64"
        case .uint64: return "UInt64"
        case .int32: return "Int32"
        case .fixed64: return "UInt64"
        case .fixed32: return "UInt32"
        case .bool: return "Bool"
        case .string: return "String"
        case .group: return context.getMessageNameForPath(path: typeName)!
        case .message: return context.getMessageNameForPath(path: typeName)!
        case .bytes: return "Data"
        case .uint32: return "UInt32"
        case .enum: return context.getEnumNameForPath(path: typeName)!
        case .sfixed32: return "Int32"
        case .sfixed64: return "Int64"
        case .sint32: return "Int32"
        case .sint64: return "Int64"
        }
    }

    func getSwiftApiType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
            let keyField = m.field[0]
            let keyType = keyField.getSwiftBaseType(context: context)
            let valueField = m.field[1]
            let valueType = valueField.getSwiftBaseType(context: context)
            return "Dictionary<" + keyType + "," + valueType + ">"
        }
        switch label {
        case .repeated: return "[" + getSwiftBaseType(context: context) + "]"
        case .required, .optional:
            return getSwiftBaseType(context: context)
        }
    }

    func getSwiftStorageType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
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
        } else {
            return getSwiftBaseType(context: context) + "?"
        }
    }

    func getSwiftStorageDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            return "[:]"
        } else if isRepeated {
            return "[]"
        } else if isMessage || isGroup || !isProto3 {
            return "nil"
        } else {
            return getSwiftDefaultValue(context: context, isProto3: isProto3)
        }
    }

    func getSwiftDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {return "[:]"}
        if isRepeated {return "[]"}
        if let d = getSwiftProto2DefaultValue(context: context) {
            return d
        }
        switch type {
        case .bool: return "false"
        case .string: return "\"\""
        case .bytes: return "Data()"
        case .group, .message:
            return context.getMessageNameForPath(path: typeName)! + "()"
        case .enum:
            let e = context.enumByProtoName[typeName]!
            if e.value.count == 0 {
                return ".None"
            } else {
                let defaultCase = e.value[0].name
                return context.getSwiftNameForEnumCase(path: typeName, caseName: defaultCase)
            }
        default: return "0"
        }
    }

    func getTraitsType(context: Context) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
            let keyField = m.field[0]
            let keyTraits = keyField.getTraitsType(context: context)
            let valueField = m.field[1]
            let valueTraits = valueField.getTraitsType(context: context)
            return "SwiftProtobuf.ProtobufMap<" + keyTraits + "," + valueTraits + ">"
        }
        switch type {
        case .double: return "SwiftProtobuf.ProtobufDouble"
        case .float: return "SwiftProtobuf.ProtobufFloat"
        case .int64: return "SwiftProtobuf.ProtobufInt64"
        case .uint64: return "SwiftProtobuf.ProtobufUInt64"
        case .int32: return "SwiftProtobuf.ProtobufInt32"
        case .fixed64: return "SwiftProtobuf.ProtobufFixed64"
        case .fixed32: return "SwiftProtobuf.ProtobufFixed32"
        case .bool: return "SwiftProtobuf.ProtobufBool"
        case .string: return "SwiftProtobuf.ProtobufString"
        case .group: return getSwiftBaseType(context: context)
        case .message: return getSwiftBaseType(context: context)
        case .bytes: return "SwiftProtobuf.ProtobufBytes"
        case .uint32: return "SwiftProtobuf.ProtobufUInt32"
        case .enum: return getSwiftBaseType(context: context)
        case .sfixed32: return "SwiftProtobuf.ProtobufSFixed32"
        case .sfixed64: return "SwiftProtobuf.ProtobufSFixed64"
        case .sint32: return "SwiftProtobuf.ProtobufSInt32"
        case .sint64: return "SwiftProtobuf.ProtobufSInt64"
        }
    }

    func getSwiftProto2DefaultValue(context: Context) -> String? {
        guard hasDefaultValue else {return nil}
        switch type {
        case .double:
           switch defaultValue {
           case "inf": return "Double.infinity"
           case "-inf": return "-Double.infinity"
           case "nan": return "Double.nan"
           default: return defaultValue
           }
        case .float:
           switch defaultValue {
           case "inf": return "Float.infinity"
           case "-inf": return "-Float.infinity"
           case "nan": return "Float.nan"
           default: return defaultValue
           }
        case .bool: return defaultValue
        case .string: return stringToEscapedStringLiteral(defaultValue)
        case .bytes: return escapedToDataLiteral(defaultValue)
        case .enum:
            return context.getSwiftNameForEnumCase(path: typeName, caseName: defaultValue)
        default: return defaultValue
        }
    }
}

struct MessageFieldGenerator {
    let descriptor: Google_Protobuf_FieldDescriptorProto
    let oneof: Google_Protobuf_OneofDescriptorProto?
    let messageDescriptor: Google_Protobuf_DescriptorProto
    let jsonName: String?
    let swiftName: String
    let swiftHasName: String
    let swiftClearName: String
    let swiftStorageName: String
    var protoName: String {return descriptor.name}
    var number: Int {return Int(descriptor.number)}
    let path: [Int32]
    let comments: String
    let isProto3: Bool
    let context: Context
    let generatorOptions: GeneratorOptions

    init(descriptor: Google_Protobuf_FieldDescriptorProto,
        path: [Int32],
        messageDescriptor: Google_Protobuf_DescriptorProto,
        file: FileGenerator,
        context: Context)
    {
        self.descriptor = descriptor
        self.jsonName = descriptor.jsonName
        if descriptor.type == .group {
            let g = context.getMessageForPath(path: descriptor.typeName)!
            self.swiftName = sanitizeFieldName(toLowerCamelCase(g.name))
            self.swiftHasName = sanitizeFieldName("has" + toUpperCamelCase(g.name))
            self.swiftClearName = sanitizeFieldName("clear" + toUpperCamelCase(g.name))
        } else {
            self.swiftName = sanitizeFieldName(toLowerCamelCase(descriptor.name))
            self.swiftHasName = sanitizeFieldName("has" + toUpperCamelCase(descriptor.name))
            self.swiftClearName = sanitizeFieldName("clear" + toUpperCamelCase(descriptor.name))
        }
        if descriptor.hasOneofIndex {
            self.oneof = messageDescriptor.oneofDecl[Int(descriptor.oneofIndex)]
        } else {
            self.oneof = nil
        }
        self.swiftStorageName = "_" + self.swiftName
        self.messageDescriptor = messageDescriptor
        self.path = path
        self.comments = file.commentsFor(path: path)
        self.isProto3 = file.isProto3
        self.context = context
        self.generatorOptions = file.generatorOptions
    }

    var fieldMapNames: String {
        // TODO: Add a check to see if the JSON name is just the text name
        // transformed with protoc's algorithm; if so, use a new case to ask
        // the runtime to do the same transformation instead of storing both
        // strings.

        // Protobuf Text uses the unqualified group name for the field
        // name instead of the field name provided by protoc.  As far
        // as I can tell, no one uses the fieldname provided by protoc,
        // so let's just put the field name that Protobuf Text
        // actually uses here.
        let protoName: String
        let jsonName: String
        if isGroup {
            protoName = descriptor.bareTypeName
        } else {
            protoName = self.protoName
        }
        jsonName = self.jsonName ?? protoName
        if jsonName != protoName {
            return ".unique(proto: \"\(protoName)\", json: \"\(jsonName)\", swift: \"\(swiftName)\")"
        } else {
            return ".same(proto: \"\(protoName)\", swift: \"\(swiftName)\")"
        }
    }

    var isGroup: Bool {return descriptor.isGroup}
    var isMap: Bool {return descriptor.getIsMap(context: context)}
    var isMessage: Bool {return descriptor.isMessage}
    var isPacked: Bool {return descriptor.isPackable &&
        (descriptor.options.hasPacked ? descriptor.options.packed : isProto3)}
    var isRepeated: Bool {return descriptor.isRepeated}

    var name: String {return descriptor.name}

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
                         : "Singular")
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

    var traitsType: String {return descriptor.getTraitsType(context: context)}

    func generateNotEqual(name: String, usesHeapStorage: Bool) -> String {
        if isProto3 || isRepeated {
            return "\(name) != other.\(name)"
        } else {
            var name = name
            if !usesHeapStorage {
                name = "_" + name
            }
            return "\(name) != other.\(name)"
        }
    }

    func generateTopIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        if let oneof = oneof {
            p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftApiType) {\n")
            p.indent()
            p.print("get {\n")
            p.indent()
            p.print("if case .\(swiftName)(let v) = \(oneof.swiftFieldName) {\n")
            p.indent()
            p.print("return v\n")
            p.outdent()
            p.print("}\n")
            p.print("return \(swiftDefaultValue)\n")
            p.outdent()
            p.print("}\n")
            p.print("set {\n")
            p.indent()
            p.print("\(oneof.swiftFieldName) = .\(swiftName)(newValue)\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
            p.print("}\n")
        } else if !isRepeated && !isMap && !isProto3 {
            p.print("private var \(swiftStorageName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
            p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftApiType) {\n")
            p.indent()
            p.print("get {return \(swiftStorageName) ?? \(swiftDefaultValue)}\n")
            p.print("set {\(swiftStorageName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
        }
    }

    func generateProxyIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftApiType) {\n")
        p.indent()
        if let oneof = oneof {
            p.print("get {\n")
            p.indent()
            p.print("if case .\(swiftName)(let v) = _storage.\(oneof.swiftStorageFieldName) {\n")
            p.indent()
            p.print("return v\n")
            p.outdent()
            p.print("}\n")
            p.print("return \(swiftDefaultValue)\n")
            p.outdent()
            p.print("}\n")
            p.print("set {\n")
            p.indent()
            p.print("_uniqueStorage().\(oneof.swiftStorageFieldName) = .\(swiftName)(newValue)\n")
            p.outdent()
            p.print("}\n")
        } else {
            let defaultClause: String
            if isMap || isRepeated {
                defaultClause = ""
            } else if isMessage || isGroup {
                defaultClause = " ?? " + swiftDefaultValue
            } else if let d = swiftProto2DefaultValue {
                defaultClause = " ?? " + d
            } else {
                defaultClause = isProto3 ? "" : " ?? " + swiftDefaultValue
            }
            p.print("get {return _storage.\(swiftStorageName)\(defaultClause)}\n")
            p.print("set {_uniqueStorage().\(swiftStorageName) = newValue}\n")
        }
        p.outdent()
        p.print("}\n")
    }

    func generateHasProperty(printer p: inout CodePrinter, usesHeapStorage: Bool) {
        if isRepeated || isMap || oneof != nil || (isProto3 && !isMessage) {
            return
        }
        let storagePrefix = usesHeapStorage ? "_storage." : ""
        p.print("public var \(swiftHasName): Bool {\n")
        p.indent()
        p.print("return \(storagePrefix)\(swiftStorageName) != nil\n")
        p.outdent()
        p.print("}\n")
    }

    func generateClearMethod(printer p: inout CodePrinter, usesHeapStorage: Bool) {
        if isRepeated || isMap || oneof != nil || (isProto3 && !isMessage) {
            return
        }
        let storagePrefix = usesHeapStorage ? "_storage." : ""
        p.print("public mutating func \(swiftClearName)() {\n")
        p.indent()
        p.print("return \(storagePrefix)\(swiftStorageName) = nil\n")
        p.outdent()
        p.print("}\n")
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter, prefix: String = "") {
        var prefix = prefix
        if prefix == "" && !isRepeated && !isMap && !isProto3 {
            prefix = "_"
        }
        p.print("case \(number): try setter.\(swiftDecoderMethod)(fieldType: \(traitsType).self, value: &\(prefix)\(swiftName))\n")
    }

    func generateTraverse(printer p: inout CodePrinter, prefix: String = "") {
        var prefix = prefix
        if prefix == "" && !isRepeated && !isMap && !isProto3 {
            prefix = "_"
        }

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

        let isOptional = !isProto3 && descriptor.label == .optional
        let varName: String
        let conditional: Bool
        if isRepeated {
            p.print("if !\(prefix)\(swiftName).isEmpty {\n")
            varName = prefix + swiftName
            conditional = true
        } else if isGroup || isMessage || !isProto3 && isOptional {
            p.print("if let v = \(prefix)\(swiftName) {\n")
            varName = "v"
            conditional = true
        } else if isProto3 {
            let def = swiftDefaultValue
            p.print("if \(prefix)\(swiftName) != \(def) {\n")
            varName = prefix + swiftName
            conditional = true
        } else {
            var value = prefix + swiftName
            conditional = false
            if !isProto3 && !isOptional {
                // Special handling for required fields to keep the tests
                // passing (that is, keep the existing behavior) since their
                // storage type has changed. This will be fixed in the future.
                let def = swiftDefaultValue
                value += " ?? " + def
            }
            varName = value
        }

        if conditional {
            p.indent()
        }
        p.print("try visitor.\(visitMethod)(\(fieldTypeArg)value: \(varName), fieldNumber: \(number))\n")
        if conditional {
            p.outdent()
            p.print("}\n")
        }
    }
}
