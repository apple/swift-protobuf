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

import SwiftProtobuf

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
    parameter: any CodeGeneratorParameter,
    protoCompilerContext: any ProtoCompilerContext,
    generatorOutputs: any GeneratorOutputs) throws

  /// The list of features this CodeGenerator support to be reported back to
  /// the protocol buffer compiler.
  var supportedFeatures: [Google_Protobuf_Compiler_CodeGeneratorResponse.Feature] { get }

  /// The Protobuf Edition range that this generator can handle. Attempting
  /// to generate for an Edition outside this range will cause protoc to
  /// error.
  var supportedEditionRange: ClosedRange<Google_Protobuf_Edition> { get }

  /// A list of extensions that define Custom Options
  /// (https://protobuf.dev/programming-guides/proto2/#customoptions) for this generator so
  /// they will be exposed on the `Descriptor` options.
  var customOptionExtensions: [any AnyMessageExtension] { get }

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

extension CommandLine {
  /// Get the command-line arguments passed to this process in a non mutable
  /// form. Idea from https://github.com/apple/swift/issues/66213
  ///
  /// - Returns: An array of command-line arguments.
  fileprivate static let safeArguments: [String] =
    UnsafeBufferPointer(start: unsafeArgv, count: Int(argc)).compactMap {
      String(validatingUTF8: $0!)
    }
}

extension CodeGenerator {
  var programName: String {
    guard let name = CommandLine.safeArguments.first?.split(separator: "/").last else {
      return "<plugin>"
    }
    return String(name)
  }

  /// Runs as a protocol buffer compiler plugin based on the given arguments
  /// or falls back to `CommandLine.arguments`.
  public func main(_ args: [String]?) {
    let args = args ?? Array(CommandLine.safeArguments.dropFirst())

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

    var extensionMap = SimpleExtensionMap()
    if !customOptionExtensions.isEmpty {
      for e in customOptionExtensions {
        // Don't include Google_Protobuf_FeatureSet, that will be handing via custom features.
        precondition(e.messageType == Google_Protobuf_EnumOptions.self ||
                     e.messageType == Google_Protobuf_EnumValueOptions.self ||
                     e.messageType == Google_Protobuf_ExtensionRangeOptions.self ||
                     e.messageType == Google_Protobuf_FieldOptions.self ||
                     e.messageType == Google_Protobuf_FileOptions.self ||
                     e.messageType == Google_Protobuf_MessageOptions.self ||
                     e.messageType == Google_Protobuf_MethodOptions.self ||
                     e.messageType == Google_Protobuf_OneofOptions.self ||
                     e.messageType == Google_Protobuf_ServiceOptions.self,
                     "CodeGenerator `customOptionExtensions` must only extend the descriptor.proto 'Options' messages \(e.messageType).")
      }
      extensionMap.insert(contentsOf: customOptionExtensions)
    }

    let response: Google_Protobuf_Compiler_CodeGeneratorResponse
    do {
      let request = try Google_Protobuf_Compiler_CodeGeneratorRequest(
        serializedBytes: FileHandle.standardInput.readDataToEndOfFile(),
        extensions: extensionMap
      )
      response = generateCode(request: request, generator: self)
    } catch let e {
      response = Google_Protobuf_Compiler_CodeGeneratorResponse(
        error: "Received an unparsable request from the compiler: \(e)")
    }

    let serializedResponse: Data
    do {
      serializedResponse = try response.serializedBytes()
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
  public var supportedEditionRange: ClosedRange<Google_Protobuf_Edition> {
    // Default impl of unknown so generator don't have to provide this until
    // they support editions.
    return Google_Protobuf_Edition.unknown...Google_Protobuf_Edition.unknown
  }
  public var customOptionExtensions: [any AnyMessageExtension] { return [] }
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
  generator: any CodeGenerator
) -> Google_Protobuf_Compiler_CodeGeneratorResponse {
  // TODO: This will need update to language specific features.

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

  var response = Google_Protobuf_Compiler_CodeGeneratorResponse()
  response.file = outputs.files

  // TODO: Could supportedFeatures be completely handled within library?
  // - The only "hard" part around hiding the proto3 optional support is making
  //   sure the oneof index related bits aren't leaked from FieldDescriptors.
  //   Otherwise the oneof related apis could likely take over the "realOneof"
  //   jobs and just never vend the synthetic information.
  // - The editions support bit likely could be computed based on the values
  //   `supportedEditionRange` having been overridden.
  let supportedFeatures = generator.supportedFeatures
  response.supportedFeatures = supportedFeatures.reduce(0) { $0 | UInt64($1.rawValue) }

  if supportedFeatures.contains(.supportsEditions) {
    let supportedEditions = generator.supportedEditionRange
    precondition(supportedEditions.upperBound != .unknown,
                 "For a CodeGenerator to support Editions, it must override `supportedEditionRange`")
    precondition(DescriptorSet.bundledEditionsSupport.contains(supportedEditions.lowerBound),
                 "A CodeGenerator can't claim to support an Edition before what the library supports: \(supportedEditions.lowerBound) vs \(DescriptorSet.bundledEditionsSupport)")
    precondition(DescriptorSet.bundledEditionsSupport.contains(supportedEditions.upperBound),
                 "A CodeGenerator can't claim to support an Edition after what the library supports: \(supportedEditions.upperBound) vs \(DescriptorSet.bundledEditionsSupport)")
    response.minimumEdition = Int32(supportedEditions.lowerBound.rawValue)
    response.maximumEdition = Int32(supportedEditions.upperBound.rawValue)
  }

  return response
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
