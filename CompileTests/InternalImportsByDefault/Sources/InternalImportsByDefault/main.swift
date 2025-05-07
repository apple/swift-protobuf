// main.swift
//
// Copyright (c) 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt

// This test only makes sense for Swift 5.9+ because 5.8 doesn't support access
// level on imports.
private import Foundation

struct InternalImportsByDefault {
    static func main() {
        let protoWithBytes = SomeProtoWithBytes.with { proto in
            proto.someBytes = Data()
            proto.extStr = ""
        }
        blackhole(protoWithBytes)
    }
}

@inline(never)
func blackhole<T>(_: T) {}
