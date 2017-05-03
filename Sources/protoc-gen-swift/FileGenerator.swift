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
}

class FileGenerator {
    private let fileDescriptor: FileDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer = SwiftProtobufNamer()

    var outputFilename: String {
        let ext = ".pb.swift"
        let pathParts = splitPath(pathname: fileDescriptor.name)
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

    init(fileDescriptor: FileDescriptor,
         generatorOptions: GeneratorOptions) {
        self.fileDescriptor = fileDescriptor
        self.generatorOptions = generatorOptions
    }

    var protoPackageName: String {return fileDescriptor.package}
    var swiftPrefix: String {return namer.typePrefix(forFile: fileDescriptor)}
    var isProto3: Bool {return fileDescriptor.syntax == .proto3}
    private var isWellKnownType: Bool {return fileDescriptor.proto.isWellKnownType}
    private var baseFilename: String {return fileDescriptor.proto.baseFilename}

    func generateOutputFile(printer p: inout CodePrinter, context: Context) {
        p.print(
            "/*\n",
            " * DO NOT EDIT.\n",
            " *\n",
            " * Generated by the protocol buffer compiler.\n",
            " * Source: \(fileDescriptor.name)\n",
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
        let syntaxPath = IndexPath(index: Google_Protobuf_FileDescriptorProto.FieldNumbers.syntax)
        if let syntaxLocation = fileDescriptor.sourceCodeInfoLocation(path: syntaxPath) {
          let comments = syntaxLocation.asSourceComment(commentPrefix: "///",
                                                        leadingDetachedPrefix: "//")
          if !comments.isEmpty {
              p.print(comments)
              // If the was a leading or tailing comment it won't have a blank
              // line, after it, so ensure there is one.
              if !comments.hasSuffix("\n\n") {
                  p.print("\n")
              }
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

        let enums = fileDescriptor.enums.map {
            return EnumGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer)
        }

        var messages = [MessageGenerator]()
        for m in fileDescriptor.messages {
          messages.append(MessageGenerator(descriptor: m, generatorOptions: generatorOptions, namer: namer, parentSwiftName: nil, parentProtoPath: fileDescriptor.proto.protoPath, file: self, context: context))
        }

        var extensions = [ExtensionGenerator]()
        for e in fileDescriptor.extensions {
            extensions.append(ExtensionGenerator(descriptor: e, generatorOptions: generatorOptions, parentProtoPath: fileDescriptor.proto.protoPath, swiftDeclaringMessageName: nil, file: self, context: context))
        }

        for e in enums {
            e.generateMainEnum(printer: &p)
        }

        for m in messages {
            m.generateMainStruct(printer: &p, file: self, parent: nil)
        }

        var registry = [String]()
        for e in extensions {
            registry.append(e.swiftFullExtensionName)
        }
        for m in messages {
            m.registerExtensions(registry: &registry)
        }
        if !registry.isEmpty {
            let pathParts = splitPath(pathname: fileDescriptor.name)
            let filename = pathParts.base + pathParts.suffix
            p.print(
                "\n",
                "// MARK: - Extension support defined in \(filename).\n")

            // Generate the Swift Extensions on the Messages that provide the api
            // for using the protobuf extension.
            for e in extensions {
                e.generateMessageSwiftExtensionForProtobufExtensions(printer: &p)
            }
            for m in messages {
                m.generateMessageSwiftExtensionForProtobufExtensions(printer: &p)
            }

            // Generate a registry for the file.
            let filenameAsIdentifer = toUpperCamelCase(pathParts.base)
            p.print(
                "\n",
                "/// A `SwiftProtobuf.SimpleExtensionMap` that includes all of the extensions defined by\n",
                "/// this .proto file. It can be used any place an `SwiftProtobuf.ExtensionMap` is needed\n",
                "/// in parsing, or it can be combined with other `SwiftProtobuf.SimpleExtensionMap`s to create\n",
                "/// a larger `SwiftProtobuf.SimpleExtensionMap`.\n",
                "\(generatorOptions.visibilitySourceSnippet)let \(fileDescriptor.proto.swiftPrefix)\(filenameAsIdentifer)_Extensions: SwiftProtobuf.SimpleExtensionMap = [\n")
            p.indent()
            var separator = ""
            for e in registry {
                p.print(separator, e)
                separator = ",\n"
            }
            p.print("\n")
            p.outdent()
            p.print("]\n")

            // Generate the Extension's declarations (used by the two above things).
            // This is done after the other two as the only time developers will need
            // these symbols is if they are manually building their own ExtensionMap;
            // so the others are assumed more interesting.
            for e in extensions {
                p.print("\n")
                e.generateProtobufExtensionDeclarations(printer: &p)
            }
            for m in messages {
                m.generateProtobufExtensionDeclarations(printer: &p)
            }
        }

        let needsProtoPackage: Bool = !protoPackageName.isEmpty && !messages.isEmpty
        if needsProtoPackage || !enums.isEmpty || !messages.isEmpty {
            p.print(
                "\n",
                "// MARK: - Code below here is support for the SwiftProtobuf runtime.\n")
            if needsProtoPackage {
                p.print(
                    "\n",
                    "fileprivate let _protobuf_package = \"\(protoPackageName)\"\n")
            }
            for e in enums {
                e.generateRuntimeSupport(printer: &p)
            }
            for m in messages {
                m.generateRuntimeSupport(printer: &p, file: self, parent: nil)
            }
        }
    }

    private func generateVersionCheck(printer p: inout CodePrinter) {
        let v = Version.compatibilityVersion
        p.print(
            "// If the compiler emits an error on this type, it is because this file\n",
            "// was generated by a version of the `protoc` Swift plug-in that is\n",
            "// incompatible with the version of SwiftProtobuf to which you are linking.\n",
            "// Please ensure that your are building against the same version of the API\n",
            "// that was used to generate this file.\n",
            "fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {\n")
        p.indent()
        p.print(
            "struct _\(v): SwiftProtobuf.ProtobufAPIVersion_\(v) {}\n",
            "typealias Version = _\(v)\n")
        p.outdent()
        p.print("}\n")
    }
}
