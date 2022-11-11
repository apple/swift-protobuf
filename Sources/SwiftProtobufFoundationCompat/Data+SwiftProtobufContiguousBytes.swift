// Sources/SwiftProtobufFoundationCompat/Data+SwiftProtobufContiguousBytes.swift
//
// Copyright (c) 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Conforms ``Foundation/Data`` to ``SwiftProtobufCore/SwiftProtobufContiguousBytes``.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufCore

// TODO: Uncomment once `Data` is unused in all of `SwiftProtobufCore`
// This is currently necessary because `Data` is still used in some places in
// `SwiftProtobufCore`, such as all of the serialization path for JSON/binary.
// Until all of the `Data` usages in `SwiftProtobufCore` are removed, the
// conformance must live here, as we would otherwise have a circular dependency
// between the modules.
//extension Data: SwiftProtobufContiguousBytes {}
