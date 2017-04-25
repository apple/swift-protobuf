// Sources/protoc-gen-swift/GeneratorOptions.swift - Wrapper for generator options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

class GeneratorOptions {
  enum OutputNaming : String {
    case FullPath
    case PathToUnderscores
    case DropPath
  }

  enum Visibility : String {
    case Internal
    case Public
  }

  let outputNaming: OutputNaming
  let visibility: Visibility

  /// A string snippet to insert for the visibility
  private(set) lazy var visibilitySourceSnippet: String = {
    switch self.visibility {
    case .Internal:
      return ""
    case .Public:
      return "public "
    }
  }()

  init(parameter: String?) throws {
    var outputNaming: OutputNaming = .FullPath
    var visibility: Visibility = .Internal

    for pair in parseParameter(string:parameter) {
      switch pair.key {
      case "FileNaming":
        if let naming = OutputNaming(rawValue: pair.value) {
          outputNaming = naming
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "Visibility":
        if let value = Visibility(rawValue: pair.value) {
          visibility = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      default:
        throw GenerationError.unknownParameter(name: pair.key)
      }
    }

    self.outputNaming = outputNaming
    self.visibility = visibility
  }
}
