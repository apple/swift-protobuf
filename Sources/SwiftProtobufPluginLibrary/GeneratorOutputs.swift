// Sources/SwiftProtobufPluginLibrary/GeneratorOutputs.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides the basic interface for providing the generation outputs.
///
// -----------------------------------------------------------------------------

import Foundation

/// Abstract interface for receiving generation outputs.
public protocol GeneratorOutputs {
  /// Add the a file with the given `name` and `contents` to the outputs.
  ///
  /// - Parameters:
  ///   - fileName: The name of the file.
  ///   - contents: The body of the file.
  ///
  /// - Throws May throw errors for duplicate file names or any other problem.
  ///     Generally `CodeGenerator`s do *not* need to catch these, and instead
  ///     they are ripple all the way out to the code calling the
  ///     `CodeGenerator`.
  func add(fileName: String, contents: String) throws

  // TODO: Consider adding apis to stream things like C++ protobuf does?
}
