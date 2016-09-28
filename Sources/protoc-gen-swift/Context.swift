// Sources/Context.swift - Overall code generation handling
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
/// The 'Context' wraps the CodeGeneratorRequest provided by protoc.  As such,
/// it is the only place that actually has access to all of the information provided
/// by protoc.
///
/// Much of protoc-gen-swift is based around two basic idioms:
///   - Each descriptor object is wrapped by a 'generator' that provides
///     additional data storage and logic
///   - Most methods are invoked with a reference to the Context class so
///     they can look up information about remote types.  Note that this
///     reference is never stored locally.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

/*
 * A tool for looking up information about various types within
 * the overall context.
 */

typealias CodeGeneratorRequest = Google_Protobuf_Compiler_CodeGeneratorRequest
typealias CodeGeneratorResponse = Google_Protobuf_Compiler_CodeGeneratorResponse

extension CodeGeneratorRequest {
    func getMessageForPath(path: String) -> Google_Protobuf_DescriptorProto? {
        for f in protoFile {
            if let m = f.getMessageForPath(path: path) {
                return m
            }
        }
        return nil
    }

    func getMessageNameForPath(path: String) -> String? {
        for f in protoFile {
            if let m = f.getMessageNameForPath(path: path) {
                return m
            }
        }
        return nil
    }

    func getEnumNameForPath(path: String) -> String? {
        for f in protoFile {
            if let m = f.getEnumNameForPath(path: path) {
                return m
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String) -> String {
        for f in protoFile {
            if let m = f.getSwiftNameForEnumCase(path: path, caseName: caseName) {
                return m
            }
        }
        fatalError("Unable to locate Enum case \(caseName) in path \(path)")
    }
}

class Context {
    var request: CodeGeneratorRequest

    private(set) var parent = [String:String]()
    private(set) var fileByProtoName = [String:Google_Protobuf_FileDescriptorProto]()
    private(set) var enumByProtoName = [String:Google_Protobuf_EnumDescriptorProto]()
    private(set) var messageByProtoName = [String:Google_Protobuf_DescriptorProto]()
    private(set) var protoNameIsGroup = Set<String>()

    func swiftNameForProtoName(protoName: String, appending: String? = nil, separator: String = ".") -> String {
        let p = parent[protoName]
        if let e = enumByProtoName[protoName] {
            return swiftNameForProtoName(protoName: p!, appending: e.name!, separator: separator)
        } else if let m = messageByProtoName[protoName] {
            let baseName: String
            if protoNameIsGroup.contains(protoName) {
                // TODO: Find a way to actually get to this line of code.
                // Then fix it to be whatever it should be.
                // If it can't be reached, assert an error in this case.
                baseName = "XXGROUPXX_" + m.name! + "_XXGROUPXX"
            } else {
                baseName = m.name!
            }
            let name: String
            if let a = appending {
                name = baseName + separator + a
            } else {
                name = baseName
            }
            return swiftNameForProtoName(protoName: p!, appending: name, separator: separator)
        } else if let f = fileByProtoName[protoName] {
            return f.swiftPrefix + (appending ?? "")
        }
        return ""
    }

    func getMessageForPath(path: String) -> Google_Protobuf_DescriptorProto? {
        return request.getMessageForPath(path: path)
    }

    func getMessageNameForPath(path: String) -> String? {
        return request.getMessageNameForPath(path: path)
    }

    func getEnumNameForPath(path: String) -> String? {
        return request.getEnumNameForPath(path: path)
    }

    init(request: CodeGeneratorRequest) throws {
        self.request = request
        for fileProto in request.protoFile {
            populateFrom(fileProto: fileProto)
        }
    }

    func populateFrom(fileProto: Google_Protobuf_FileDescriptorProto) {
        let prefix: String
        if let pkg = fileProto.package {
            prefix = "." + pkg
        } else {
            prefix = ""
        }
        fileByProtoName[prefix] = fileProto
        for e in fileProto.enumType {
            populateFrom(enumProto: e, prefix: prefix)
        }
        for m in fileProto.messageType {
            populateFrom(messageProto: m, prefix: prefix)
        }
        for f in fileProto.extension_p {
            if f.type! == .group {
                protoNameIsGroup.insert(f.typeName!)
            }
        }
    }

    func populateFrom(enumProto: Google_Protobuf_EnumDescriptorProto, prefix: String) {
        let name = prefix + "." + enumProto.name!
        enumByProtoName[name] = enumProto
        parent[name] = prefix
    }

    func populateFrom(messageProto: Google_Protobuf_DescriptorProto, prefix: String) {
        let name = prefix + "." + messageProto.name!
        parent[name] = prefix
        messageByProtoName[name] = messageProto
        for f in messageProto.field {
            if f.type! == .group {
                protoNameIsGroup.insert(f.typeName!)
            }
        }
        for f in messageProto.extension_p {
            if f.type! == .group {
                protoNameIsGroup.insert(f.typeName!)
            }
        }
        for e in messageProto.enumType {
            populateFrom(enumProto: e, prefix: name)
        }
        for m in messageProto.nestedType {
            populateFrom(messageProto: m, prefix: name)
        }
    }

    func getSwiftNameForEnumCase(path: String, caseName: String) -> String {
        return request.getSwiftNameForEnumCase(path: path, caseName: caseName)
    }

    func generateResponse() -> CodeGeneratorResponse {
        var response = CodeGeneratorResponse()
        let explicit = Set<String>(request.fileToGenerate)

        for fileProto in request.protoFile where explicit.contains(fileProto.name!) {
            var printer = CodePrinter()
            let file = FileGenerator(descriptor: fileProto)
            file.generateOutputFile(printer: &printer, context: self)
            let fileResponse = CodeGeneratorResponse.File(name: file.outputFilename, content: printer.content)
            response.file.append(fileResponse)
        }
        return response
    }
}
