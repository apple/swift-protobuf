// Sources/protoc-gen-swift/GeneratorOptions.swift - Wrapper for generator options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

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
  
  enum MessageRuntimeConformance: String, CaseIterable {
    case Message, MessageImplementationBase, ProtoNameProviding
  }
  
  enum BooleanParameter: String {
    case Yes, No
  }
  
  let outputNaming: OutputNaming
  let protoToModuleMappings: ProtoFileToModuleMappings
  let visibility: Visibility
  
  /// A string snippet to insert for the visibility
  let visibilitySourceSnippet: String
  
  let messageRuntimeConformances: [MessageRuntimeConformance]
  
  let commentsReduced: BooleanParameter
  
  
  init(parameter: String?) throws {
    var outputNaming: OutputNaming = .FullPath
    var moduleMapPath: String?
    var visibility: Visibility = .Internal
    var swiftProtobufModuleName: String? = nil
    var messageRuntimeConformances = MessageRuntimeConformance.allCases
    var commentsReduced: BooleanParameter = .No
    
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
        case "MessageRuntimeConformances":
          messageRuntimeConformances = []
          for element in pair.value.components(separatedBy: "+").filter({ !$0.isEmpty }) {
            if let conformance = MessageRuntimeConformance(rawValue: element.trimmingCharacters(in: .whitespacesAndNewlines)) {
              messageRuntimeConformances.append(conformance)
            } else {
              throw GenerationError.invalidParameterValue(name: pair.key,
                                                          value: element)
            }
          }
        case "ReduceComments":
          if let value = BooleanParameter(rawValue: pair.value) {
            commentsReduced = value
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
    self.messageRuntimeConformances = messageRuntimeConformances
    self.commentsReduced = commentsReduced
    
    switch visibility {
      case .Internal:
        visibilitySourceSnippet = ""
      case .Public:
        visibilitySourceSnippet = "public "
    }
    
  }
}
