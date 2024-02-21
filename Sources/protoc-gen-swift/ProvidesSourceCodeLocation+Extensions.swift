// Sources/protoc-gen-swift/ProvidesDeprecationComment+Extensions.swift
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

import SwiftProtobufPluginLibrary

extension ProvidesDeprecationComment where Self: ProvidesSourceCodeLocation {
  func protoSourceCommentsWithDeprecation(
    generatorOptions: GeneratorOptions,
    commentPrefix: String = "///",
    leadingDetachedPrefix: String? = nil
  ) -> String {
    if generatorOptions.experimentalStripNonfunctionalCodegen {
      // Comments are inherently non-functional, and may change subtly on
      // transformations.
      return deprecationComment(commentPrefix: commentPrefix)
    }

    return protoSourceCommentsWithDeprecation(commentPrefix: commentPrefix,
                                              leadingDetachedPrefix: leadingDetachedPrefix)
  }
}
