// Sources/SwiftProtobufPluginLibrary/ProtoCompilerContext.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// This provides some basic interface about the protocol buffer compiler
// that generates the code.
//
// -----------------------------------------------------------------------------

import Foundation

/// Abstact interface to get information about the protocol buffer compiler
/// that generates the code.
public protocol ProtoCompilerContext {
    /// The version of the protocol buffer compiler (if the generation request
    /// includes it).
    var version: Google_Protobuf_Compiler_Version? { get }
}
