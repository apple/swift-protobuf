// Tests/protoc-gen-swiftTests/Test_GeneratorOptions.swift - Test GeneratorOptions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary
import Testing
import protoc_gen_swift

private struct FakeParameter: CodeGeneratorParameter {
    let parameter: String = ""
    let parsedPairs: [(key: String, value: String)]

    init(pairs: [(key: String, value: String)]) {
        self.parsedPairs = pairs
    }
}

@Test func experimentalHiddenNames() throws {
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Fields")]))
        #expect(options.experimentalHiddenNames == .fields)
    }
    do {
        let options = try GeneratorOptions(
            parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "EnumValues")])
        )
        #expect(options.experimentalHiddenNames == .enumValues)
    }
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Types")]))
        #expect(options.experimentalHiddenNames == .types)
    }
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "All")]))
        #expect(options.experimentalHiddenNames == .all)
    }
    do {
        let options = try GeneratorOptions(
            parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Fields,Types")])
        )
        #expect(options.experimentalHiddenNames == [.fields, .types])
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "unknownFeature")]))
    }
}
