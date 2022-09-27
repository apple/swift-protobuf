// Sources/protoc-gen-swift/GeneratorOptions.swift - Wrapper for generator options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

class GeneratorOptions {
  enum OutputNaming : String {
    case fullPath = "FullPath"
    case pathToUnderscores = "PathToUnderscores"
    case dropPath = "DropPath"
  }

  enum Visibility {
    case `internal`
    case `public`
    case spi(String)

    init?(rawValue: String) {
      if rawValue == "Internal" {
        self = .internal
      } else if rawValue == "Public" {
        self = .public
      } else if rawValue.hasPrefix("_SPI(") && rawValue.hasSuffix(")") {
        let identifier = String(rawValue.dropFirst(5).dropLast(1))
        self = .spi(identifier)
      } else {
        return nil
      }
    }

    var rawValue: String {
      switch self {
      case .internal:
        return "Internal"
      case .public:
        return "Public"
      case .spi(let identifier):
        return "_SPI(\(identifier))"
      }
    }
  }

  let outputNaming: OutputNaming
  let protoToModuleMappings: ProtoFileToModuleMappings
  let visibility: Visibility

  /// A string snippet to insert for the visibility
  let visibilitySourceSnippet: String

  init(parameter: String?) throws {
    var outputNaming: OutputNaming = .fullPath
    var moduleMapPath: String?
    var visibility: Visibility = .internal
    var swiftProtobufModuleName: String? = nil

    for pair in parseParameter(string:parameter) {
      switch pair.key {
      case "FileNaming":
        if let naming = OutputNaming(rawValue: pair.value) {
          outputNaming = naming
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "ProtoPathModuleMappings":
        if !pair.value.isEmpty {
          moduleMapPath = pair.value
        }
      case "Visibility":
        if let value = Visibility(rawValue: pair.value) {
          visibility = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "SwiftProtobufModuleName":
        // This option is not documented in PLUGIN.md, because it's a feature
        // that would ordinarily not be required for a given adopter.
        if isValidSwiftIdentifier(pair.value) {
          swiftProtobufModuleName = pair.value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      default:
        throw GenerationError.unknownParameter(name: pair.key)
      }
    }

    if let moduleMapPath = moduleMapPath {
      do {
        self.protoToModuleMappings = try ProtoFileToModuleMappings(path: moduleMapPath, swiftProtobufModuleName: swiftProtobufModuleName)
      } catch let e {
        throw GenerationError.wrappedError(
          message: "Parameter 'ProtoPathModuleMappings=\(moduleMapPath)'",
          error: e)
      }
    } else {
      self.protoToModuleMappings = ProtoFileToModuleMappings(swiftProtobufModuleName: swiftProtobufModuleName)
    }

    self.outputNaming = outputNaming
    self.visibility = visibility

    switch visibility {
    case .internal:
      visibilitySourceSnippet = ""
    case .public:
      visibilitySourceSnippet = "public "
    case .spi(let identifier):
      visibilitySourceSnippet = "@_spi(\(identifier)) public "
    }

  }
}
