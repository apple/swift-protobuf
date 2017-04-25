// Sources/protoc-gen-swift/Context.swift - Overall code generation handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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

extension Google_Protobuf_Compiler_Version {
  fileprivate var versionString: String {
    if !suffix.isEmpty {
      return "\(major).\(minor).\(patch).\(suffix)"
    }
    return "\(major).\(minor).\(patch)"
  }
}

class Context {
  private let request: CodeGeneratorRequest
  let options: GeneratorOptions
  private let descriptorSet: DescriptorSet

  // TODO(thomasvl): Revisit to use the Desciptor instead.
  func getMessageForPath(path: String) -> Google_Protobuf_DescriptorProto? {
    return descriptor(forProtoName: path).proto
  }

  func getMessageNameForPath(path: String) -> String? {
    return request.getMessageNameForPath(path: path)
  }

  func getEnumNameForPath(path: String) -> String? {
    return request.getEnumNameForPath(path: path)
  }

  init(request: CodeGeneratorRequest) throws {
    if request.hasCompilerVersion {
      let compilerVersion = request.compilerVersion;
      // Expect 3.1.x or 3.2.x - Yes we have to rev this with new release, but
      // that seems like the best thing at the moment.
      let isExpectedVersion = (compilerVersion.major == 3) &&
        (compilerVersion.minor >= 1) &&
        (compilerVersion.minor <= 2)
      if !isExpectedVersion {
        Stderr.print("WARNING: untested version of protoc (\(compilerVersion.versionString)).")
      }
    } else {
      Stderr.print("WARNING: unknown version of protoc, use 3.2.x or later to ensure JSON support is correct.")
    }

    self.request = request
    self.options = try GeneratorOptions(parameter: request.parameter)
    self.descriptorSet = DescriptorSet(protos: request.protoFile)
  }

  func descriptor(forProtoName name: String) -> Descriptor {
    return descriptorSet.lookupDescriptor(protoName: name)
  }

  func enumDescriptor(forProtoName name: String) -> EnumDescriptor {
    return descriptorSet.lookupEnumDescriptor(protoName: name)
  }

  func getSwiftNameForEnumCase(path: String, caseName: String) -> String {
    return request.getSwiftNameForEnumCase(path: path, caseName: caseName)
  }

  func generateResponse() -> CodeGeneratorResponse {
    var response = CodeGeneratorResponse()
    let explicit = Set<String>(request.fileToGenerate)

    for fileProto in request.protoFile where explicit.contains(fileProto.name) {
      var printer = CodePrinter()
      let file = FileGenerator(descriptor: fileProto, generatorOptions: options)
      file.generateOutputFile(printer: &printer, context: self)
      let fileResponse = CodeGeneratorResponse.File(name: file.outputFilename, content: printer.content)
      response.file.append(fileResponse)
    }
    return response
  }
}
