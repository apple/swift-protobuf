// Sources/protoc-gen-swift/OneofGenerator.swift - Oneof handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This class represents a single Oneof in the proto and generates an efficient
/// algebraic enum to store it in memory.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_OneofDescriptorProto {
    var swiftFieldName: String {
        return toLowerCamelCase(name)
    }
    var swiftStorageFieldName: String {
        return "_" + toLowerCamelCase(name)
    }
    var swiftRelativeType: String {
        return "OneOf_" + toUpperCamelCase(name)
    }
}

class OneofGenerator {
    let descriptor: Google_Protobuf_OneofDescriptorProto
    let path: [Int32]
    let generatorOptions: GeneratorOptions
    let fields: [MessageFieldGenerator]
    let fieldsSortedByNumber: [MessageFieldGenerator]
    let swiftRelativeName: String
    let swiftFullName: String
    let isProto3: Bool
    let comments: String

    init(descriptor: Google_Protobuf_OneofDescriptorProto, path: [Int32], file: FileGenerator, generatorOptions: GeneratorOptions, fields: [MessageFieldGenerator], swiftMessageFullName: String) {
        self.descriptor = descriptor
        self.path = path
        self.generatorOptions = generatorOptions
        self.fields = fields
        self.fieldsSortedByNumber = fields.sorted {$0.number < $1.number}
        self.isProto3 = file.isProto3
        self.swiftRelativeName = sanitizeOneofTypeName(descriptor.swiftRelativeType)
        self.swiftFullName = swiftMessageFullName + "." + swiftRelativeName
        self.comments = file.commentsFor(path: path)
    }

    func generateMainEnum(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)enum \(swiftRelativeName): Equatable {\n")
        p.indent()

        // Oneof case for each ivar
        for f in fields {
            p.print("case \(f.swiftName)(\(f.swiftBaseType))\n")
        }

        // Equatable conformance
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {\n")
        p.indent()
        p.print("switch (lhs, rhs) {\n")
        for f in fields {
            p.print("case (.\(f.swiftName)(let l), .\(f.swiftName)(let r)): return l == r\n")
        }
        if fields.count > 1 {
            // A tricky edge case: If the oneof only has a single case, then
            // the case pattern generated above is exhaustive and generating a
            // default produces a compiler error. If there is more than one
            // case, then the case patterns are not exhaustive (because we
            // don't compare mismatched pairs), and we have to include a
            // default.
            p.print("default: return false\n")
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateRuntimeSupport(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("extension \(swiftFullName) {\n")
        p.indent()

        // Decode one of our members
        p.print("fileprivate init?<T: SwiftProtobuf.Decoder>(byDecodingFrom decoder: inout T, fieldNumber: Int) throws {\n")
        p.indent()
        p.print("switch fieldNumber {\n")
        for f in fieldsSortedByNumber {
            let modifier = "Singular"
            let special = f.isGroup ? "Group"
                        : f.isMessage ? "Message"
                        : f.isEnum ? "Enum"
                        : f.protoTypeName
            let decoderMethod = "decode\(modifier)\(special)Field"

            p.print("case \(f.number):\n")
            p.indent()
            if isProto3 && !f.isMessage && !f.isGroup {
                // Proto3 has non-optional fields, so this is simpler
                p.print("var value = \(f.swiftStorageType)()\n")
                p.print("try decoder.\(decoderMethod)(value: &value)\n")
                p.print("self = .\(f.swiftName)(value)\n")
                p.print("return\n")
            } else {
                p.print("var value: \(f.swiftStorageType)\n")
                p.print("try decoder.\(decoderMethod)(value: &value)\n")
                p.print("if let value = value {\n")
                p.print("  self = .\(f.swiftName)(value)\n")
                p.print("  return\n")
                p.print("}\n")
            }
            p.outdent()
        }
        p.print("default:\n")
        p.indent()
        p.print("break\n")
        p.outdent()
        p.print("}\n")
        p.print("return nil\n")
        p.outdent()
        p.print("}\n")

        // Traverse the current value
        p.print("\n")
        p.print("fileprivate func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V, start: Int, end: Int) throws {\n")
        p.indent()
        p.print("switch self {\n")
        for f in fieldsSortedByNumber {
            p.print("case .\(f.swiftName)(let v):\n")
            p.indent()
            p.print("if start <= \(f.number) && \(f.number) < end {\n")
            p.indent()
            let special = f.isGroup ? "Group" : f.isMessage ? "Message" : f.isEnum ? "Enum" : f.protoTypeName;
            let visitorMethod = "visitSingular\(special)Field"
            p.print("try visitor.\(visitorMethod)(value: v, fieldNumber: \(f.number))\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateProxyIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if !comments.isEmpty {
            p.print(comments)
        }
        p.print("\(generatorOptions.visibilitySourceSnippet)var \(descriptor.swiftFieldName): \(swiftRelativeName)? {\n")
        p.indent()
        p.print("get {return _storage.\(descriptor.swiftStorageFieldName)}\n")
        p.print("set {_uniqueStorage().\(descriptor.swiftStorageFieldName) = newValue}\n")
        p.outdent()
        p.print("}\n")
    }

    func generateTopIvar(printer p: inout CodePrinter) {
        p.print("\n")
        if !comments.isEmpty {
            p.print(comments)
        }
        p.print("\(generatorOptions.visibilitySourceSnippet)var \(descriptor.swiftFieldName): \(swiftFullName)? = nil\n")
    }
}
