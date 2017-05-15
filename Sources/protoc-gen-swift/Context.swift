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
  private let options: GeneratorOptions
  private let descriptorSet: DescriptorSet

  init(request: CodeGeneratorRequest) throws {
    if request.hasCompilerVersion {
      let compilerVersion = request.compilerVersion;
      // Expect 3.1.x or 3.3.x - Yes we have to rev this with new release, but
      // that seems like the best thing at the moment.
      let isExpectedVersion = (compilerVersion.major == 3) &&
        (compilerVersion.minor >= 1) &&
        (compilerVersion.minor <= 3)
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

  func generateResponse() -> CodeGeneratorResponse {
    var response = CodeGeneratorResponse()

    for name in request.fileToGenerate {
      let fileDescriptor = descriptorSet.lookupFileDescriptor(protoName: name)
      let fileGenerator = FileGenerator(fileDescriptor: fileDescriptor, generatorOptions: options)
      var printer = CodePrinter()
      // TODO(thomasvl): Go to a model where this can throw or return an error which can be
      // sent back in the response's error (including the input file name that caused it).
      fileGenerator.generateOutputFile(printer: &printer)
      response.file.append(CodeGeneratorResponse.File(name: fileGenerator.outputFilename,
                                                      content: printer.content))
    }
    return response
  }
}
