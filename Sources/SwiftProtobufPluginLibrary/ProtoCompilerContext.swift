// Sources/SwiftProtobufPluginLibrary/ProtoCompilerContext.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides some basic interface about the protocol buffer compiler
/// being used to generate.
///
// -----------------------------------------------------------------------------

import Foundation

/// Abstact interface to get information about the protocol buffer compiler
/// being used for generation.
public protocol ProtoCompilerContext {
    /// The version of the protocol buffer compiler (if it was provided in the
    /// generation request).
    var version: Google_Protobuf_Compiler_Version? { get }
}
