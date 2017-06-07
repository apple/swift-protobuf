// Sources/protoc-gen-swift/main.swift - Protoc plugin main
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A protoc plugin is a code generator that accepts a protobuf-encoded
/// request on stdin and writes the protobuf-encoded response to stdout.
/// When protoc sees a command-line option of the form --foo_out=<path>,
/// it will run a program called `protoc-gen-foo` as the corresponding
/// plugin.
///
/// The request contains FileDescriptors with the parsed proto files
/// to be processed and some additional processing information.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import PluginLibrary

extension Google_Protobuf_Compiler_Version {
  fileprivate var versionString: String {
    if !suffix.isEmpty {
      return "\(major).\(minor).\(patch).\(suffix)"
    }
    return "\(major).\(minor).\(patch)"
  }
}

struct GeneratorPlugin {
  private enum Mode {
    case showHelp
    case showVersion
    case generateFromStdin
    case generateFromFiles(paths: [String])
  }

  init() { }

  func run(args: [String]) -> Int32 {
    var result: Int32 = 0

    let mode = parseCommandLine(args: args)
    switch mode {
    case .showHelp:
      showHelp()
    case .showVersion:
      showVersion()
    case .generateFromStdin:
      result = generateFromStdin()
    case .generateFromFiles(let paths):
      result = generateFromFiles(paths)
    }

    return result
  }

  private func parseCommandLine(args: [String]) -> Mode {
    var paths: [String] = []
    for arg in args {
      switch arg {
      case "-h", "--help":
        return .showHelp
      case "--version":
        return .showVersion
      default:
        if arg.hasPrefix("-") {
          Stderr.print("Unknown argument: \"\(arg)\"")
          return .showHelp
        } else {
          paths.append(arg)
        }
      }
    }
    return paths.isEmpty ? .generateFromStdin : .generateFromFiles(paths: paths)
  }

  private func showHelp() {
    print("\(CommandLine.programName): Convert parsed proto definitions into Swift")
    print("")
    showVersion()
    print(Version.copyright)
    print("")

    let help = (
      "Note:  This is a plugin for protoc and should not normally be run\n"
        + "directly.\n"
        + "\n"
        + "If you invoke a recent version of protoc with the --swift_out=<dir>\n"
        + "option, then protoc will search the current PATH for protoc-gen-swift\n"
        + "and use it to generate Swift output.\n"
        + "\n"
        + "In particular, if you have renamed this program, you will need to\n"
        + "adjust the protoc command-line option accordingly.\n"
        + "\n"
        + "The generated Swift output requires the SwiftProtobuf \(SwiftProtobuf.Version.versionString)\n"
        + "library be included in your project.\n"
        + "\n"
        + "If you use `swift build` to compile your project, add this to\n"
        + "Package.swift:\n"
        + "\n"
        + "   dependencies: [\n"
        + "     .Package(url: \"https://github.com/apple/swift-protobuf\",\n"
        + "              Version(\(SwiftProtobuf.Version.versionString))\n"
        + "   ]\n"
        + "\n"
        + "\n"
        + "Usage: \(CommandLine.programName) [options] [filename...]\n"
        + "\n"
        + " -h|--help:  Print this help message\n"
        + " --version: Print the program version\n"
        + "\n"
        + "Filenames specified on the command line indicate binary-encoded\n"
        + "google.protobuf.compiler.CodeGeneratorRequest objects that will\n"
        + "be read and converted to Swift source code.  The source text will be\n"
        + "written directly to stdout.\n"
        + "\n"
        + "When invoked with no filenames, it will read a single binary-encoded\n"
        + "google.protobuf.compiler.CodeGeneratorRequest object from stdin and\n"
        + "emit the corresponding CodeGeneratorResponse object to stdout.\n")

    print(help)
  }

  private func showVersion() {
    print("\(CommandLine.programName) \(SwiftProtobuf.Version.versionString)")
  }

  private func generateFromStdin() -> Int32 {
    guard let requestData = Stdin.readall() else {
      Stderr.print("Failed to read request")
      return 1
    }

    let request: Google_Protobuf_Compiler_CodeGeneratorRequest
    do {
      request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: requestData)
    } catch let e {
      Stderr.print("Request failed to decode: \(e)")
      return 1
    }

    auditProtoCVersion(request: request)

    let response = generate(request: request)
    if !sendReply(response: response) {
      return 1
    }

    return 0
  }

  private func generateFromFiles(_ paths: [String]) -> Int32 {
    var result: Int32 = 0

    for p in paths {
      let requestData: Data
      do {
        requestData = try readFileData(filename: p)
      } catch let e {
        Stderr.print("Error reading from \(p) - \(e)")
        result = 1
        continue
      }
      Stderr.print("Read request: \(requestData.count) bytes from \(p)")

      let request: Google_Protobuf_Compiler_CodeGeneratorRequest
      do {
        request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: requestData)
      } catch let e {
        Stderr.print("Request failed to decode \(p): \(e)")
        result = 1
        continue
      }

      let response = generate(request: request)
      if response.hasError {
        Stderr.print("Error while generating from \(p) - \(response.error)")
        result = 1
      } else {
        for f in response.file {
          print("+++ Begin File: \(f.name) +++")
          print(!f.content.isEmpty ? f.content : "<No content>")
          print("+++ End File: \(f.name) +++")
        }
      }
    }

    return result
  }

  private func generate(
    request: Google_Protobuf_Compiler_CodeGeneratorRequest
  ) -> Google_Protobuf_Compiler_CodeGeneratorResponse {
    let options: GeneratorOptions
    do {
      options = try GeneratorOptions(parameter: request.parameter)
    } catch GenerationError.unknownParameter(let name) {
      return Google_Protobuf_Compiler_CodeGeneratorResponse(
        error: "Unknown generation parameter '\(name)'")
    } catch GenerationError.invalidParameterValue(let name, let value) {
      return Google_Protobuf_Compiler_CodeGeneratorResponse(
        error: "Unknown value for generation parameter '\(name)': '\(value)'")
    } catch GenerationError.wrappedError(let message, let e) {
      return Google_Protobuf_Compiler_CodeGeneratorResponse(error: "\(message): \(e)")
    } catch let e {
      return Google_Protobuf_Compiler_CodeGeneratorResponse(
        error: "Internal Error parsing request options: \(e)")
    }

    let descriptorSet = DescriptorSet(protos: request.protoFile)

    var responseFiles: [Google_Protobuf_Compiler_CodeGeneratorResponse.File] = []
    for name in request.fileToGenerate {
      let fileDescriptor = descriptorSet.lookupFileDescriptor(protoName: name)
      let fileGenerator = FileGenerator(fileDescriptor: fileDescriptor, generatorOptions: options)
      var printer = CodePrinter()
      // TODO(thomasvl): Go to a model where this can throw or return an error which can be
      // sent back in the response's error (including the input file name that caused it).
      fileGenerator.generateOutputFile(printer: &printer)
      responseFiles.append(
        Google_Protobuf_Compiler_CodeGeneratorResponse.File(name: fileGenerator.outputFilename,
                                                            content: printer.content))
    }
    return Google_Protobuf_Compiler_CodeGeneratorResponse(files: responseFiles)
  }

  private func auditProtoCVersion(request: Google_Protobuf_Compiler_CodeGeneratorRequest) {
    guard request.hasCompilerVersion else {
      Stderr.print("WARNING: unknown version of protoc, use 3.2.x or later to ensure JSON support is correct.")
      return
    }
    let compilerVersion = request.compilerVersion

    // Expect 3.1.x or 3.3.x - Yes we have to rev this with new release, but
    // that seems like the best thing at the moment.
    let isExpectedVersion = (compilerVersion.major == 3) &&
      (compilerVersion.minor >= 1) &&
      (compilerVersion.minor <= 3)
    if !isExpectedVersion {
      Stderr.print("WARNING: untested version of protoc (\(compilerVersion.versionString)).")
    }
  }

  private func sendReply(response: Google_Protobuf_Compiler_CodeGeneratorResponse) -> Bool {
    let serializedResponse: Data
    do {
      serializedResponse = try response.serializedData()
    } catch let e {
      Stderr.print("Failure while serializing response: \(e)")
      return false
    }
    Stdout.write(bytes: serializedResponse)
    return true
  }

}

// MARK: - Hand off to the GeneratorPlugin

// Drop the program name off to get the arguments only.
let args: [String] = [String](CommandLine.arguments.dropFirst(1))
let plugin = GeneratorPlugin()
let result = plugin.run(args: args)
exit(result)
