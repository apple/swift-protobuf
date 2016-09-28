// Sources/EnumGenerator.swift - Enum logic
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
/// This file handles the generation of a Swift enum for each .proto enum.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

///
/// Extend the EnumValueDescriptorProto with some helper
/// logic.
///
extension Google_Protobuf_EnumValueDescriptorProto {
    func getSwiftName(stripLength: Int) -> String {
        return sanitizeEnumCase(getSwiftBareName(stripLength: stripLength))
    }

    func getSwiftDisplayName(stripLength: Int) -> String {
        return sanitizeDisplayEnumCase(getSwiftBareName(stripLength: stripLength))
    }

    func getSwiftBareName(stripLength: Int) -> String {
        let baseName = toLowerCamelCase(name!)
        let swiftName: String
        if stripLength == 0 {
            swiftName = baseName
        } else {
            var c = [Character](baseName.characters)
            c.removeFirst(stripLength)
            if c == [] {
                return baseName
            }
            c[0] = Character(String(c[0]).lowercased())
            swiftName = String(c)
        }
        return swiftName
    }
}

///
/// Extend the EnumValueDescriptorProto with some helper
/// logic.
///
extension Google_Protobuf_EnumDescriptorProto {
    var stripPrefixLength: Int {
        let enumName = toUpperCamelCase(name!).uppercased()
        for f in value {
            let fieldName = toUpperCamelCase(f.name!).uppercased()
#if os(Linux)
            let enumChars = [Character](enumName.characters)
            let fieldChars = [Character](fieldName.characters)
            if fieldChars.count <= enumChars.count {
                return 0
            }
            let fieldPrefix = fieldChars[0..<enumChars.count]
            let fieldPrefixString = String(fieldPrefix)
            if fieldPrefixString != enumName {
                return o
            }
#else
            if enumName.commonPrefix(with: fieldName) != enumName {
                return 0
            }
#endif
        }
        return enumName.characters.count
    }

    func getSwiftNameForEnumCase(caseName: String) -> String {
        let stripLength = stripPrefixLength
        for f in value {
            if f.name! == caseName {
                return f.getSwiftName(stripLength: stripLength)
            }
        }
        fatalError("Cannot find case `\(caseName)` in enum \(name!)")
    }
}

///
/// Generate output for a single enum case.
///
class EnumCaseGenerator {
    fileprivate let descriptor: Google_Protobuf_EnumValueDescriptorProto
    fileprivate var swiftDisplayName: String
    fileprivate var swiftName: String
    fileprivate var jsonName: String
    fileprivate var protoName: String {return descriptor.name!}
    fileprivate var number: Int {return Int(descriptor.number!)}
    fileprivate let path: [Int32]
    fileprivate let comments: String

    init(descriptor: Google_Protobuf_EnumValueDescriptorProto, path: [Int32], file: FileGenerator, stripLength: Int) {
       self.descriptor = descriptor
       self.swiftName = descriptor.getSwiftName(stripLength: stripLength)
       self.swiftDisplayName = descriptor.getSwiftDisplayName(stripLength: stripLength)
       self.jsonName = descriptor.name!
       self.path = path
       self.comments = file.commentsFor(path: path)
    }
    func generateCase(printer: inout CodePrinter) {
       if comments != "" {
           printer.print("\n")
           printer.print(comments)
       }
       printer.print("case \(swiftName) // = \(number)\n")
    }
}

///
///
class EnumGenerator {
    fileprivate let descriptor: Google_Protobuf_EnumDescriptorProto
    fileprivate let swiftRelativeName: String
    fileprivate let swiftFullName: String
    fileprivate let enumCases: [EnumCaseGenerator]
    fileprivate let defaultCase: EnumCaseGenerator
    fileprivate let path: [Int32]
    fileprivate let comments: String
    fileprivate let isProto3: Bool

    init(descriptor: Google_Protobuf_EnumDescriptorProto, path: [Int32], parentSwiftName: String?, file: FileGenerator) {
        self.descriptor = descriptor
        self.isProto3 = file.isProto3
        if parentSwiftName == nil {
            swiftRelativeName = sanitizeEnumTypeName(file.swiftPrefix + descriptor.name!)
            swiftFullName = swiftRelativeName
        } else {
            swiftRelativeName = sanitizeEnumTypeName(descriptor.name!)
            swiftFullName = parentSwiftName! + "." + swiftRelativeName
        }

        let stripLength: Int = descriptor.stripPrefixLength
        var i: Int32 = 0
        var enumCases = [EnumCaseGenerator]()
        for v in descriptor.value {
            var casePath = path
            casePath.append(2)
            casePath.append(i)
            i += 1
            enumCases.append(EnumCaseGenerator(descriptor: v, path: casePath, file: file, stripLength: stripLength))
        }
        self.enumCases = enumCases
        self.defaultCase = self.enumCases[0]
        self.path = path
        self.comments = file.commentsFor(path: path)
    }

    func generateNested(printer: inout CodePrinter) {
        printer.print("\n")
        printer.print(comments)
        printer.print("public enum \(swiftRelativeName): ProtobufEnum {\n")
        printer.indent()
        printer.print("public typealias RawValue = Int\n")

        // Cases
        for c in enumCases {
            c.generateCase(printer: &printer)
        }
        if isProto3 {
            printer.print("case UNRECOGNIZED(Int)\n")
        }

        // Default init
        printer.print("\n")
        printer.print("public init() {\n")
        printer.indent()
        printer.print("self = .\(defaultCase.swiftName)\n")
        printer.outdent()
        printer.print("}\n")

        // rawValue init
        printer.print("\n")
        printer.print("public init?(rawValue: Int) {\n")
        printer.indent()
        printer.print("switch rawValue {\n")
        var uniqueCaseNumbers = Set<Int>()
        for c in enumCases where !uniqueCaseNumbers.contains(c.number) {
            printer.print("case \(c.number): self = .\(c.swiftName)\n")
            uniqueCaseNumbers.insert(c.number)
        }
        if isProto3 {
            printer.print("default: self = .UNRECOGNIZED(rawValue)\n")
        } else {
            printer.print("default: return nil\n")
        }
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // Swift name init
        printer.print("\n")
        printer.print("public init?(name: String) {\n")
        printer.indent()
        printer.print("switch name {\n")
        for c in enumCases {
            printer.print("case \"\(c.swiftDisplayName)\": self = .\(c.swiftName)\n")
        }
        printer.print("default: return nil\n")
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // JSON name init
        printer.print("\n")
        printer.print("public init?(jsonName: String) {\n")
        printer.indent()
        printer.print("switch jsonName {\n")
        for c in enumCases {
            printer.print("case \"\(c.jsonName)\": self = .\(c.swiftName)\n")
        }
        printer.print("default: return nil\n")
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // Proto name init
        printer.print("\n")
        printer.print("public init?(protoName: String) {\n")
        printer.indent()
        printer.print("switch protoName {\n")
        for c in enumCases {
            printer.print("case \"\(c.protoName)\": self = .\(c.swiftName)\n")
        }
        printer.print("default: return nil\n")
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // rawValue property
        printer.print("\n")
        printer.print("public var rawValue: Int {\n")
        printer.indent()
        printer.print("get {\n")
        printer.indent()
        printer.print("switch self {\n")
        for c in enumCases {
            printer.print("case .\(c.swiftName): return \(c.number)\n")
        }
        if isProto3 {
            printer.print("case .UNRECOGNIZED(let i): return i\n")
        }
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // json property
        printer.print("\n")
        printer.print("public var json: String {\n")
        printer.indent()
        printer.print("get {\n")
        printer.indent()
        printer.print("switch self {\n")
        for c in enumCases {
            printer.print("case .\(c.swiftName): return \"\\\"\(c.jsonName)\\\"\"\n")
        }
        if isProto3 {
            printer.print("case .UNRECOGNIZED(let i): return String(i)\n")
        }
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")

        // hashValue property
        printer.print("\n")
        printer.print("public var hashValue: Int { return rawValue }\n")

        // debugDescription property
        printer.print("\n")
        printer.print("public var debugDescription: String {\n")
        printer.indent()
        printer.print("get {\n")
        printer.indent()
        printer.print("switch self {\n")
        for c in enumCases {
            printer.print("case .\(c.swiftName): return \".\(c.swiftDisplayName)\"\n")
        }
        if isProto3 {
            printer.print("case .UNRECOGNIZED(let v): return \".UNRECOGNIZED(\\(v))\"\n")
        }
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")
        printer.outdent()
        printer.print("}\n")


        printer.outdent()
        printer.print("\n")
        printer.print("}\n")
    }
}
