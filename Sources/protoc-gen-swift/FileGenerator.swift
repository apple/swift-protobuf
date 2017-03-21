// Sources/protoc-gen-swift/FileGenerator.swift - File-level generation logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
        if !package.isEmpty {
            base = "." + package
        } else {
            base = ""
        }
        for m in messageType {
            let messagePath = base + "." + m.name
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
        if !package.isEmpty {
            base = "." + package
        } else {
            base = ""
        }
        for m in messageType {
            let messagePath = base + "." + m.name
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name)
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
        if !package.isEmpty {
            base = "." + package
        } else {
            base = ""
        }
        for e in enumType {
            let enumPath = base + "." + e.name
            if enumPath == path {
                return sanitizeEnumTypeName(swiftPrefix + e.name)
            }
        }
        for m in messageType {
            let messagePath = base + "." + m.name
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name)
            if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String) -> String? {
        let base: String
        if !package.isEmpty {
            base = "." + package
        } else {
            base = ""
        }
        for e in enumType {
            let enumPath = base + "." + e.name
            if enumPath == path {
                let enumSwiftName = swiftPrefix + sanitizeEnumTypeName(e.name)
                return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
            }
        }
        for m in messageType {
            let messagePath = base + "." + m.name
            let messageSwiftPath = sanitizeMessageTypeName(swiftPrefix + m.name)
            if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    var isProto3: Bool {return syntax == "proto3"}

    var protoPath: String {
        if !package.isEmpty {
            return "." + package
        } else {
            return ""
        }
    }

    var baseFilename: String {
        return splitPath(pathname: name).base
    }

    var isWellKnownType : Bool {
      // descriptor.proto is also in the "google.protobuf" package, but it isn't
      // a well known type, so filter it out.
      return package == "google.protobuf" && baseFilename != "descriptor"
    }

    var swiftPrefix: String {
        if options.hasSwiftPrefix {
            return options.swiftPrefix
        }
        if !package.isEmpty {
            var makeUpper = true
            var prefix = ""
            for c in package.characters {
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
        if hasSourceCodeInfo {
            for l in sourceCodeInfo.location {
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
    let generatorOptions: GeneratorOptions

    init(descriptor: Google_Protobuf_FileDescriptorProto,
         generatorOptions: GeneratorOptions) {
        self.descriptor = descriptor
        self.generatorOptions = generatorOptions
    }

    func messageNameForPath(path: String) -> String? {
        let base: String
        if !descriptor.package.isEmpty {
            base = "." + descriptor.package
        } else {
            base = ""
        }
        for m in descriptor.messageType {
            let messagePath = base + "." + m.name
            if messagePath == path {
                let swiftName = swiftPrefix + m.name
                return swiftName
            }
        }
        Stderr.print("Unable to match \(path) within \(base)")
        assert(false)
        return nil
    }

    var protoPackageName: String {return descriptor.package}
    var swiftPrefix: String {return descriptor.swiftPrefix}
    var isProto3: Bool {return descriptor.isProto3}
    var isWellKnownType: Bool {return descriptor.isWellKnownType}
    var baseFilename: String {return descriptor.baseFilename}

    var outputFilename: String {
        let ext = ".pb.swift"
        let pathParts = splitPath(pathname: descriptor.name)
        switch generatorOptions.outputNaming {
        case .FullPath:
            return pathParts.dir + pathParts.base + ext
        case .PathToUnderscores:
            let dirWithUnderscores =
                pathParts.dir.replacingOccurrences(of: "/", with: "_")
            return dirWithUnderscores + pathParts.base + ext
        case .DropPath:
            return pathParts.base + ext
        }
    }

    func commentsFor(path: [Int32], includeLeadingDetached: Bool = false) -> String {
        func escapeMarkup(_ text: String) -> String {
            // Proto file comments don't really have any markup associated with
            // them.  Swift uses something like MarkDown:
            //   "Markup Formatting Reference"
            //   https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_markup_formatting_ref/index.html
            // Sadly that format doesn't really lend itself to any form of
            // escaping to ensure comments are interpreted markup when they
            // really aren't. About the only thing that could be done is to
            // try and escape some set of things that could start directives,
            // and that gets pretty chatty/ugly pretty quickly.
            return text
        }

        func prefixLines(text: String, prefix: String) -> String {
            var result = ""
            var lines = text.components(separatedBy: .newlines)
            // Trim any blank lines off the end.
            while !lines.isEmpty && trimWhitespace(lines.last!).isEmpty {
                lines.removeLast()
            }
            for line in lines {
                result.append(prefix + line + "\n")
            }
            return result
        }

        if let location = descriptor.locationFor(path: path) {
            var result = ""

            if includeLeadingDetached {
                for detached in location.leadingDetachedComments {
                    let comment = prefixLines(text: detached, prefix: "// ")
                    if !comment.isEmpty {
                        result += comment
                        // Detached comments have blank lines between then (and
                        // anything that follows them).
                        result += "\n"
                    }
                }
            }

            let comments = location.hasLeadingComments ? location.leadingComments : location.trailingComments
            result += prefixLines(text: escapeMarkup(comments), prefix: "///  ")
            return result
        }
        return ""
    }

    func generateOutputFile(printer p: inout CodePrinter, context: Context) {
        let inputFilename = descriptor.hasName ? descriptor.name : "<No name>"
        p.print(
            "/*\n",
            " * DO NOT EDIT.\n",
            " *\n",
            " * Generated by the protocol buffer compiler.\n",
            " * Source: \(inputFilename)\n",
            " *\n",
            " */\n",
            "\n")

        // Attempt to bring over the comments at the top of the .proto file as
        // they likely contain copyrights/preamble/etc.
        //
        // The C++ FileDescriptor::GetSourceLocation(), says the location for
        // the file is an empty path. That never seems to have comments on it.
        // https://github.com/google/protobuf/issues/2249 opened to figure out
        // the right way to do this since the syntax entry is optional.
        let comments = commentsFor(path: [Google_Protobuf_FileDescriptorProto.FieldNumbers.syntax],
                                   includeLeadingDetached: true)
        if !comments.isEmpty {
            p.print(comments)
            // If the was a leading or tailing comment it won't have a blank
            // line, after it, so ensure there is one.
            if !comments.hasSuffix("\n\n") {
                p.print("\n")
            }
        }

        p.print("import Foundation\n")
        if !isWellKnownType {
          // The well known types ship with the runtime, everything else needs
          // to import the runtime.
          p.print("import SwiftProtobuf\n")
        }

        p.print("\n")
        generateVersionCheck(printer: &p)

        if !protoPackageName.isEmpty {
            p.print("\n")
            p.print("fileprivate let _protobuf_package = \"\(protoPackageName)\"\n")
        }

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
            extensions.append(ExtensionGenerator(descriptor: e, path: extPath, parentProtoPath: descriptor.protoPath, swiftDeclaringMessageName: nil, file: self, context: context))
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
            p.print("\(generatorOptions.visibilitySourceSnippet)let \(descriptor.swiftPrefix)\(filename)_Extensions: SwiftProtobuf.SimpleExtensionMap = [\n")
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

    private func generateVersionCheck(printer p: inout CodePrinter) {
        let v = Version.compatibilityVersion
        p.print("// If the compiler emits an error on this type, it is because this file\n")
        p.print("// was generated by a version of the `protoc` Swift plug-in that is\n")
        p.print("// incompatible with the version of SwiftProtobuf to which you are linking.\n")
        p.print("// Please ensure that your are building against the same version of the API\n")
        p.print("// that was used to generate this file.\n")
        p.print("fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {\n")
        p.print("  struct _\(v): SwiftProtobuf.ProtobufAPIVersion_\(v) {}\n")
        p.print("  typealias Version = _\(v)\n")
        p.print("}\n")
    }
}
