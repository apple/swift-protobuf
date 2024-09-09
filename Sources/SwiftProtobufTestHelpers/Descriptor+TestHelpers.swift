// Sources/protoc-gen-swift/Descriptor+TestHelpers.swift - Additions to Descriptors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf

extension Google_Protobuf_FileDescriptorProto {
    public init(name: String, dependencies: [String] = [], publicDependencies: [Int32] = [], package: String = "") {
        for idx in publicDependencies { precondition(Int(idx) <= dependencies.count) }
        self.init()
        self.name = name
        self.dependency = dependencies
        self.publicDependency = publicDependencies
        self.package = package
    }
    public init(textFormatStrings: [String]) throws {
        let s = textFormatStrings.joined(separator: "\n") + "\n"
        try self.init(textFormatString: s)
    }
}

extension Google_Protobuf_FileDescriptorSet {
    public init(files: [Google_Protobuf_FileDescriptorProto]) {
        self.init()
        self.file = files
    }
    public init(file: Google_Protobuf_FileDescriptorProto) {
        self.init()
        self.file = [file]
    }
}

extension Google_Protobuf_EnumValueDescriptorProto {
    public init(name: String, number: Int32) {
        self.init()
        self.name = name
        self.number = number
    }
}
