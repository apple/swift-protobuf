// Sources/protoc-gen-swift/MessageStorageDecision.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

struct FilePrinter {
    var main: CodePrinter
    var hashable: CodePrinter
    var nameProviding: CodePrinter
    
    mutating func forEach(_ body: (_ p: inout CodePrinter) -> Void) {
        body(&main)
        forEachRuntimeExtension(body)
    }
    
    mutating func forEachRuntimeExtension(_ body: (_ p: inout CodePrinter) -> Void) {
        body(&hashable)
        body(&nameProviding)
    }
}
