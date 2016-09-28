// Sources/FileGenerator.swift - File-level generation logic
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
/// This provides the logic for each file that is stored in the plugin request.
/// In particular, generateOutputFile() actually builds a Swift source file
/// to represent a single .proto input.  Note that requests typically contain
/// a number of proto files that are not to be generated.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

///
/// Extend the FileDescriptorProto with some utility
/// methods for translating/reading/converting various
/// properties.
///
extension Google_Protobuf_FileDescriptorProto {
    func getMessageForPath(path: String) -> Google_Protobuf_DescriptorProto? {
        let base: String
        if let p = package {
            base = "." + p
        } else {
            base = ""
        }
        for m in messageType {
            let messagePath = base + "." + m.name!
            if messagePath == path {
                return m
            }
            if let n = m.getMessageForPath(path: path, parentPath: messagePath) {
                return n
            }
        }
        return nil
    }

    func getMessageNameForPath(path: String) -> String? {
        let base: String
        if let p = package {
            base = "." + p
        } else {
            base = ""
        }
        for m in messageType {
            let messagePath = base + "." + m.name!
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name!)
            if messagePath == path {
                return messageSwiftPath
            }
            if let n = m.getMessageNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getEnumNameForPath(path: String) -> String? {
        let base: String
        if let p = package {
            base = "." + p
        } else {
            base = ""
        }
        for e in enumType {
            let enumPath = base + "." + e.name!
            if enumPath == path {
                return sanitizeEnumTypeName(swiftPrefix + e.name!)
            }
        }
        for m in messageType {
            let messagePath = base + "." + m.name!
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name!)
            if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String) -> String? {
        let base: String
        if let p = package {
            base = "." + p
        } else {
            base = ""
        }
        for e in enumType {
            let enumPath = base + "." + e.name!
            if enumPath == path {
                let enumSwiftName = swiftPrefix + sanitizeEnumTypeName(e.name!)
                return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
            }
        }
        for m in messageType {
            let messagePath = base + "." + m.name!
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name!)
            if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    var isProto3: Bool {return syntax != nil && syntax! == "proto3"}

    var protoPath: String {
        if let pkg = package {
            return "." + pkg
        } else {
            return ""
        }
    }

    var swiftPrefix: String {
        if let p = options?.swiftPrefix {
            return p
        } else if let p = options?.appleSwiftPrefix {
            return p
        } else if let pkg = package, pkg != "" {
            var makeUpper = true
            var prefix = ""
            for c in pkg.characters {
                if c == "_" {
                    makeUpper = true
                } else if c == "." {
                    makeUpper = true
                    prefix += "_"
                } else if makeUpper {
                    prefix += String(c).uppercased()
                    makeUpper = false
                } else {
                    prefix += String(c)
                }
            }
            return prefix + "_"
        } else {
            return ""
        }
    }

    func locationFor(path: [Int32]) -> Google_Protobuf_SourceCodeInfo.Location? {
        if let codeInfo = sourceCodeInfo {
            for l in codeInfo.location {
                if l.path == path {
                    return l
                }
            }
        }
        return nil
    }
}

class FileGenerator {
    let descriptor: Google_Protobuf_FileDescriptorProto

    init(descriptor: Google_Protobuf_FileDescriptorProto) {
        self.descriptor = descriptor
    }

    func messageNameForPath(path: String) -> String? {
        let base: String
        if let p = descriptor.package {
            base = "." + p
        } else {
            base = ""
        }
        for m in descriptor.messageType {
            let messagePath = base + "." + m.name!
            if messagePath == path {
                let swiftName = swiftPrefix + m.name!
                return swiftName
            }
        }
        Stderr.print("Unable to match \(path) within \(base)")
        assert(false)
        return nil
    }

    var protoPackageName: String {return descriptor.package ?? ""}
    var swiftPrefix: String {return descriptor.swiftPrefix}
    var isProto3: Bool {return descriptor.isProto3}

    var baseFilename: String {
        return splitPath(pathname: descriptor.name ?? "").base
    }

    var outputFilename: String {
        return baseFilename + ".pb.swift"
    }

    func commentsFor(path: [Int32]) -> String {
        func addLinePrefix(text: String, prefix: String) -> String {
            var output = ""
            var atLineStart = true
            for c in text.characters {
                if atLineStart {
                    if output == "" {
                        output.append(prefix + " ")
                    } else {
                        output.append(prefix)
                    }
                }
                if c == "\n" {
                    output.append("\n")
                    atLineStart = true
                } else {
                    output.append(c);
                    atLineStart = false
                }
            }
            return output
        }

        if let location = descriptor.locationFor(path: path) {
            let leading = trimWhitespace(location.leadingDetachedComments.joined(separator: ""))
            let trimmed = trimWhitespace(location.leadingComments ?? location.trailingComments ?? "")

            let commentBlocks: [String] = [
                addLinePrefix(text: leading, prefix: "// "),
                addLinePrefix(text: trimmed, prefix: "///  ")
            ]
            let comments = commentBlocks.filter {$0 != ""}.joined(separator: "\n\n")
            if comments != "" {
                return comments + "\n"
            }
        }
        return ""
    }

    func generateOutputFile(printer p: inout CodePrinter, context: Context) {
        let inputFilename = descriptor.name ?? "<No name>";
        Stderr.print("Generating Swift for \(inputFilename)")
        p.print(
            "/*\n",
            " * DO NOT EDIT.\n",
            " *\n",
            " * Generated by the protocol buffer compiler.\n",
            " * Source: \(inputFilename)\n",
            " *\n",
            " */\n",
            "\n")

        // File header comments sometimes precede the 'syntax' field
        // Carry those through if we can.
        let comments = commentsFor(path: [12])
        if comments != "" {
            p.print(comments)
            p.print("\n")
        }

        p.print(
            "import Foundation\n",
            "import SwiftProtobuf\n",
            "\n")

        var enums = [EnumGenerator]()
        let path = [Int32]()
        var i: Int32 = 0
        for e in descriptor.enumType {
            let enumPath = path + [5, i]
            i += 1
            enums.append(EnumGenerator(descriptor: e, path: enumPath, parentSwiftName: nil, file: self))
        }

        var messages = [MessageGenerator]()
        i = 0
        for m in descriptor.messageType {
            let messagePath = path + [4, i]
            i += 1
            messages.append(MessageGenerator(descriptor: m, path: messagePath, parentSwiftName: nil, parentProtoPath: descriptor.protoPath, file: self, context: context))
        }

        var extensions = [ExtensionGenerator]()
        i = 0
        for e in descriptor.extension_p {
            let extPath = path + [7, i]
            i += 1
            extensions.append(ExtensionGenerator(descriptor: e, path: extPath, declaringMessageName: nil, file: self, context: context))
        }

        for e in enums {
            e.generateNested(printer: &p)
        }

        for m in messages {
            m.generateNested(printer: &p, file: self, parent: nil)
        }

        for e in extensions {
            e.generateNested(printer: &p)
        }

        for m in messages {
            m.generateTopLevel(printer: &p)
        }

        for e in extensions {
            e.generateTopLevel(printer: &p)
        }

        var registry = [String]()
        for e in extensions {
            registry.append(e.swiftFullExtensionName)
        }
        for m in messages {
            m.registerExtensions(registry: &registry)
        }
        if !registry.isEmpty {
            let filename = toUpperCamelCase(baseFilename)
            p.print("\n")
            p.print("public let \(descriptor.swiftPrefix)\(filename)_Extensions: ProtobufExtensionSet = [\n")
            p.indent()
            var separator = ""
            for e in registry {
                p.print(separator)
                p.print(e)
                separator = ",\n"
            }
            p.print("\n")
            p.outdent()
            p.print("]\n")
        }
    }
}
