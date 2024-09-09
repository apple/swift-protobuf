// Sources/SwiftProtobufPluginLibrary/CodeGeneratorParameter.swift
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides the basic interface for a CodeGeneratorParameter. This is
/// passed to the `CodeGenerator` to get any command line options.
///
// -----------------------------------------------------------------------------

import Foundation

/// The the generator specific parameter that was passed to the protocol
/// compiler invocation. The protocol buffer compiler supports providing
/// parameters via the `--[LANG]_out` or `--[LANG]_opt` command line flags.
/// The compiler will relay those through as a _parameter_ string.
public protocol CodeGeneratorParameter {
    /// The raw value from the compiler as a single string, if multiple values
    /// were passed, they are joined into a single string. See `parsedPairs` as
    /// that is likely a better option for consuming the parameters.
    var parameter: String { get }

    /// The protocol buffer compiler will combine multiple `--[LANG]_opt`
    /// directives into a "single" parameter by joining them with commas. This
    /// vends the parameter split back back out into the individual arguments:
    /// i.e.,
    ///   "foo=bar,baz,mumble=blah"
    /// becomes:
    ///   [
    ///     (key: "foo", value: "bar"),
    ///     (key: "baz", value: ""),
    ///     (key: "mumble", value: "blah")
    ///   ]
    var parsedPairs: [(key: String, value: String)] { get }
}
