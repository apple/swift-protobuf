// Sources/protoc-gen-swift/OneofGenerator.swift - Oneof handling
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
    let generatorOptions: GeneratorOptions
    let fields: [MessageFieldGenerator]
    let swiftRelativeName: String
    let swiftFullName: String
    let isProto3: Bool

    init(descriptor: Google_Protobuf_OneofDescriptorProto, generatorOptions: GeneratorOptions, fields: [MessageFieldGenerator], swiftMessageFullName: String, isProto3: Bool) {
        self.descriptor = descriptor
        self.generatorOptions = generatorOptions
        self.fields = fields
        self.isProto3 = isProto3
        self.swiftRelativeName = sanitizeOneofTypeName(descriptor.swiftRelativeType)
        self.swiftFullName = swiftMessageFullName + "." + swiftRelativeName
    }

    func generateNested(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)enum \(swiftRelativeName): ExpressibleByNilLiteral, SwiftProtobuf.OneofEnum {\n")
        p.indent()

        // Oneof case for each ivar
        for f in fields {
            p.print("case \(f.swiftName)(\(f.swiftBaseType))\n")
        }
        p.print("case None\n")

        // Equatable conformance
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {\n")
        p.indent()
        p.print("switch (lhs, rhs) {\n")
        for f in fields {
            p.print("case (.\(f.swiftName)(let l), .\(f.swiftName)(let r)): return l == r\n")
        }
        p.print("case (.None, .None): return true\n")
        p.print("default: return false\n")
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        // ExpressibleByNilLiteral conformance
        p.print("\n")
        p.print("public init(nilLiteral: ()) {\n")
        p.print("  self = .None\n")
        p.print("}\n")

        // Basic init
        p.print("\n")
        p.print("public init() {\n")
        p.print("  self = .None\n")
        p.print("}\n")

        // Decode one of our members
        p.print("\n")
        p.print("public mutating func decodeField(setter: inout SwiftProtobuf.FieldDecoder, protoFieldNumber: Int) throws {\n")
        p.indent()
        p.print("if self != .None && setter.rejectConflictingOneof {\n")
        p.print("  throw SwiftProtobuf.DecodingError.duplicatedOneOf\n")
        p.print("}\n")
        p.print("switch protoFieldNumber {\n")
        for f in fields.sorted(by: {$0.number < $1.number}) {
            p.print("case \(f.number):\n")
            p.indent()
            if isProto3 && !f.isMessage && !f.isGroup {
                // Proto3 can use a more streamlined structure here
                p.print("var value = \(f.swiftStorageType)()\n")
                p.print("try setter.decodeSingularField(fieldType: \(f.traitsType).self, value: &value)\n")
                p.print("self = .\(f.swiftName)(value)\n")
            } else {
                p.print("var value: \(f.swiftStorageType)\n")
                let special = f.isGroup ? "Group" : f.isMessage ? "Message" : "";
                let modifier = "Singular"
                let decoderMethod = "decode\(modifier)\(special)Field"
                p.print("try setter.\(decoderMethod)(fieldType: \(f.traitsType).self, value: &value)\n")
                p.print("if let value = value {\n")
                p.print("  self = .\(f.swiftName)(value)\n")
                p.print("}\n")
            }
            p.outdent()
        }
        p.print("default:\n")
        p.indent()
        p.print("self = .None\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        // Traverse the current value
        p.print("\n")
        p.print("public func traverse(visitor: inout SwiftProtobuf.Visitor, start: Int, end: Int) throws {\n")
        p.indent()
        p.print("switch self {\n")
        for f in fields.sorted(by: {$0.number < $1.number}) {
            p.print("case .\(f.swiftName)(let v):\n")
            p.indent()
            p.print("if start <= \(f.number) && \(f.number) < end {\n")
            p.indent()
            let special = f.isGroup ? "Group" : f.isMessage ? "Message" : "";
            let visitorMethod = "visitSingular\(special)Field"
            let fieldClause = (f.isGroup || f.isMessage) ? "" : "fieldType: \(f.traitsType).self, "
            p.print("try visitor.\(visitorMethod)(\(fieldClause)value: v, protoFieldNumber: \(f.number))\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
        }
        p.print("case .None:\n")
        p.print("  break\n")
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateProxyIvar(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("public var \(descriptor.swiftFieldName): \(swiftRelativeName) {\n")
        p.indent()
        p.print("get {return _storage.\(descriptor.swiftStorageFieldName)}\n")
        p.print("set {\n")
        p.indent()
        p.print("_uniqueStorage().\(descriptor.swiftStorageFieldName) = newValue\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")
    }

    func generateTopIvar(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("public var \(descriptor.swiftFieldName): \(swiftFullName) = .None\n")
    }
}
