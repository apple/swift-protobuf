// Sources/SwiftProtobufPluginLibrary/CodeGeneratorParameter.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// This provides the basic interface for a CodeGeneratorParameter. This is
// passed to the `CodeGenerator` to get any command line options.
//
// -----------------------------------------------------------------------------

import Foundation

/// The generator-specific parameter that the protocol compiler invocation
/// passed.
///
/// The protocol buffer compiler supports providing parameters via the
/// `--[LANG]_out` or `--[LANG]_opt` command line flags. The compiler relays
/// those through as a parameter string.
public protocol CodeGeneratorParameter {
    /// The raw value from the compiler as a single string, joining multiple
    /// passed values into one.
    ///
    /// See `parsedPairs` as that is likely a better option for consuming the
    /// parameters.
    var parameter: String { get }

    /// Splits the parameter into its individual key/value arguments.
    ///
    /// The protocol buffer compiler combines multiple `--[LANG]_opt`
    /// directives into a "single" parameter by joining them with commas. For
    /// example, this parameter value:
    ///   "foo=bar,baz,mumble=blah"
    /// becomes:
    ///   [
    ///     (key: "foo", value: "bar"),
    ///     (key: "baz", value: ""),
    ///     (key: "mumble", value: "blah")
    ///   ]
    var parsedPairs: [(key: String, value: String)] { get }
}
