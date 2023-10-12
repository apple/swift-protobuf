// Sources/SwiftProtobufPluginLibrary/CodeGenerator.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides the basic interface for writing a CodeGenerator.
///
// -----------------------------------------------------------------------------

import Foundation

/// A protocol that generator should conform to then get easy support for
/// being a protocol buffer compiler pluign.
public protocol CodeGenerator {
  init()

  /// Generates code for the given proto files.
  ///
  /// - Parameters:
  ///   - parameter: The parameter (or paramenters) passed for the generator.
  ///       This is for parameters specific to this generator,
  ///       `parse(parameter:)` (below) can be used to split back out
  ///       multiple parameters into the combined for the protocol buffer
  ///       compiler uses.
  ///   - protoCompilerContext: Context information about the protocol buffer
  ///       compiler being used.
  ///   - generatorOutputs: A object that can be used to send back the
  ///       generated outputs.
  ///
  /// - Throws: Can throw any `Error` to fail generate. `String(describing:)`
  ///       will be called on the error to provide the error string reported
  ///       to the user attempting to generate sources.
  func generate(
    files: [FileDescriptor],
    parameter: CodeGeneratorParameter,
    protoCompilerContext: ProtoCompilerContext,
    generatorOutputs: GeneratorOutputs) throws

  /// The list of features this CodeGenerator support to be reported back to
  /// the protocol buffer compiler.
  var supportedFeatures: [Google_Protobuf_Compiler_CodeGeneratorResponse.Feature] { get }

  /// If provided, the argument parsing will support `--version` and report
  /// this value.
  var version: String? { get }

  /// If provided and `printHelp` isn't provide, this value will be including in
  /// default output for the `--help` output.
  var projectURL: String? { get }

  /// If provided and `printHelp` isn't provide, this value will be including in
  /// default output for the `--help` output.
  var copyrightLine: String? { get }

  /// Will be called for `-h` or `--help`, should `print()` out whatever is
  /// desired; there is a default implementation that uses the above info
  /// when provided.
  func printHelp()
}

extension CodeGenerator {
  var programName: String {
    guard let name = CommandLine.arguments.first?.split(separator: "/").last else {
      return "<plugin>"
    }
    return String(name)
  }

  /// Runs as a protocol buffer compiler plugin based on the given arguments
  /// or falls back to `CommandLine.arguments`.
  public func main(_ args: [String]?) {
    let args = args ?? Array(CommandLine.arguments.dropFirst())

    for arg in args {
      if arg == "--version", let version = version {
        print("\(programName) \(version)")
        return
      }
      if arg == "-h" || arg == "--help" {
        printHelp()
        return
      }
      // Could look at bringing back the support for recorded requests, but
      // haven't needed it in a long time.
      var stderr = StandardErrorOutputStream()
      print("Unknown argument: \(arg)", to: &stderr)
      return
    }

    let response: Google_Protobuf_Compiler_CodeGeneratorResponse
    do {
      let request = try Google_Protobuf_Compiler_CodeGeneratorRequest(
        serializedData: FileHandle.standardInput.readDataToEndOfFile())
      response = generateCode(request: request, generator: self)
    } catch let e {
      response = Google_Protobuf_Compiler_CodeGeneratorResponse(
        error: "Received an unparsable request from the compiler: \(e)")
    }

    let serializedResponse: Data
    do {
      serializedResponse = try response.serializedData()
    } catch let e {
      var stderr = StandardErrorOutputStream()
      print("\(programName): Failure while serializing response: \(e)", to: &stderr)
      return
    }
    FileHandle.standardOutput.write(serializedResponse)
  }

  /// Runs as a protocol buffer compiler plugin; reading the generation request
  /// off stdin and sending the response on stdout.
  ///
  /// Instead of calling this, just add `@main` to your `CodeGenerator`.
  public static func main() {
    let generator = Self()
    generator.main(nil)
  }
}

// Provide default implementation for things so `CodeGenerator`s only have to
// provide them if they wish too.
extension CodeGenerator {
  public var version: String? { return nil }
  public var projectURL: String? { return nil }
  public var copyrightLine: String? { return nil }

  public func printHelp() {
    print("\(programName): A plugin for protoc and should not normally be run directly.")
    if let copyright = copyrightLine {
      print("\(copyright)")
    }
    if let projectURL = projectURL {
      print(
        """

        For more information on the usage of this plugin, please see:
          \(projectURL)

        """)
    }
  }
}

/// Uses the given `Google_Protobuf_Compiler_CodeGeneratorRequest` and
/// `CodeGenerator` to get code generated and create the
/// `Google_Protobuf_Compiler_CodeGeneratorResponse`. If there is a failure,
/// the failure will be used in the response to be returned to the protocol
/// buffer compiler to then be reported.
///
/// - Parameters:
///   - request: The request proto as generated by the protocol buffer compiler.
///   - geneator: The `CodeGenerator` to use for generation.
///
/// - Returns a filled out response with the success or failure of the
///    generation.
public func generateCode(
  request: Google_Protobuf_Compiler_CodeGeneratorRequest,
  generator: CodeGenerator
) -> Google_Protobuf_Compiler_CodeGeneratorResponse {
  // TODO: This will need update to support editions and language specific features.

  let descriptorSet = DescriptorSet(protos: request.protoFile)

  var files = [FileDescriptor]()
  for name in request.fileToGenerate {
    guard let fileDescriptor = descriptorSet.fileDescriptor(named: name) else {
      return Google_Protobuf_Compiler_CodeGeneratorResponse(
        error:
          "protoc asked plugin to generate a file but did not provide a descriptor for the file: \(name)"
      )
    }
    files.append(fileDescriptor)
  }

  let context = InternalProtoCompilerContext(request: request)
  let outputs = InternalGeneratorOutputs()
  let parameter = InternalCodeGeneratorParameter(request.parameter)

  do {
    try generator.generate(
      files: files, parameter: parameter, protoCompilerContext: context,
      generatorOutputs: outputs)
  } catch let e {
    return Google_Protobuf_Compiler_CodeGeneratorResponse(error: String(describing: e))
  }

  return Google_Protobuf_Compiler_CodeGeneratorResponse(
    files: outputs.files, supportedFeatures: generator.supportedFeatures)
}

// MARK: Internal supporting types

/// Internal implementation of `CodeGeneratorParameter` for
/// `generateCode(request:generator:)`
struct InternalCodeGeneratorParameter: CodeGeneratorParameter {
  let parameter: String

  init(_ parameter: String) {
    self.parameter = parameter
  }

  var parsedPairs: [(key: String, value: String)] {
    guard !parameter.isEmpty else {
      return []
    }
    let parts = parameter.components(separatedBy: ",")
    return parts.map { s -> (key: String, value: String) in
      guard let index = s.range(of: "=")?.lowerBound else {
        // Key only, no value ("baz" in example).
        return (trimWhitespace(s), "")
      }
      return (
        key: trimWhitespace(s[..<index]),
        value: trimWhitespace(s[s.index(after: index)...])
      )
    }
  }
}

/// Internal implementation of `ProtoCompilerContext` for
/// `generateCode(request:generator:)`
private struct InternalProtoCompilerContext: ProtoCompilerContext {
  let version: Google_Protobuf_Compiler_Version?

  init(request: Google_Protobuf_Compiler_CodeGeneratorRequest) {
    self.version = request.hasCompilerVersion ? request.compilerVersion : nil
  }
}

/// Internal implementation of `GeneratorOutputs` for
/// `generateCode(request:generator:)`
private final class InternalGeneratorOutputs: GeneratorOutputs {

  enum OutputError: Error, CustomStringConvertible {
    /// Attempt to add two files with the same name.
    case duplicateName(String)

    var description: String {
      switch self {
      case .duplicateName(let name):
        return "Generator tried to generate two files named \(name)."
      }
    }
  }

  var files: [Google_Protobuf_Compiler_CodeGeneratorResponse.File] = []
  private var fileNames: Set<String> = []

  func add(fileName: String, contents: String) throws {
    guard !fileNames.contains(fileName) else {
      throw OutputError.duplicateName(fileName)
    }
    fileNames.insert(fileName)
    files.append(
      Google_Protobuf_Compiler_CodeGeneratorResponse.File(
        name: fileName,
        content: contents))
  }
}
