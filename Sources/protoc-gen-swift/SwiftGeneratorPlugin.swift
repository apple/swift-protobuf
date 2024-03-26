// Sources/protoc-gen-swift/SwiftGeneratorPlugin.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A protoc plugin is a code generator that accepts a protobuf-encoded
/// request on stdin and writes the protobuf-encoded response to stdout.
/// When protoc sees a command-line option of the form `--foo_out=<path>`,
/// it will run a program called `protoc-gen-foo` as the corresponding
/// plugin.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

@main
struct SwiftGeneratorPlugin: CodeGenerator {

  func generate(
    files: [SwiftProtobufPluginLibrary.FileDescriptor],
    parameter: any CodeGeneratorParameter,
    protoCompilerContext: any SwiftProtobufPluginLibrary.ProtoCompilerContext,
    generatorOutputs: any SwiftProtobufPluginLibrary.GeneratorOutputs
  ) throws {
    let options = try GeneratorOptions(parameter: parameter)

    auditProtoCVersion(context: protoCompilerContext)
    var errorString: String? = nil
    for fileDescriptor in files {
      let fileGenerator = FileGenerator(fileDescriptor: fileDescriptor, generatorOptions: options)
      var printer = CodePrinter(addNewlines: true)
      fileGenerator.generateOutputFile(printer: &printer, errorString: &errorString)
      if let errorString = errorString {
        // If generating multiple files, scope the message with the file that triggered it.
        let fullError = files.count > 1 ? "\(fileDescriptor.name): \(errorString)" : errorString
        throw GenerationError.message(message: fullError)
      }
      try generatorOutputs.add(fileName: fileGenerator.outputFilename, contents: printer.content)
    }
  }

  var supportedFeatures: [SwiftProtobufPluginLibrary.Google_Protobuf_Compiler_CodeGeneratorResponse.Feature] = [
    .proto3Optional, .supportsEditions
  ]

  var supportedEditionRange: ClosedRange<Google_Protobuf_Edition> {
    Google_Protobuf_Edition.proto2...Google_Protobuf_Edition.edition2023
  }

  var version: String? { return "\(SwiftProtobuf.Version.versionString)" }
  var copyrightLine: String? { return "\(Version.copyright)" }
  var projectURL: String? { return "https://github.com/apple/swift-protobuf" }

  private func auditProtoCVersion(context: any SwiftProtobufPluginLibrary.ProtoCompilerContext) {
    guard context.version != nil else {
      Stderr.print("WARNING: unknown version of protoc, use 3.2.x or later to ensure JSON support is correct.")
      return
    }
    // 3.2.x is what added the compiler_version, so there is no need to
    // ensure that the version of protoc being used is newer, if the field
    // is there, the JSON support should be good.
  }

  // Provide an expanded version of help.
  func printHelp() {
    print("""
      \(CommandLine.programName): Convert parsed proto definitions into Swift

      \(Version.copyright)

      Note:  This is a plugin for protoc and should not normally be run
      directly.

      If you invoke a recent version of protoc with the --swift_out=<dir>
      option, then protoc will search the current PATH for protoc-gen-swift
      and use it to generate Swift output.

      In particular, if you have renamed this program, you will need to
      adjust the protoc command-line option accordingly.

      The generated Swift output requires the SwiftProtobuf \(version!)
      library be included in your project.

      If you use `swift build` to compile your project, add this to
      Package.swift:

         dependencies: [
           .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "\(version!)"),
         ]

      Usage: \(CommandLine.programName) [options] [filename...]

        -h|--help:  Print this help message
        --version:  Print the program version

      """)
  }

}
