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
import XCTest
@testable import protoc_gen_swift

final class Test_GeneratorOptions: XCTestCase {
    private struct MockParameter: CodeGeneratorParameter {
        let parameter: String
        let parsedPairs: [(key: String, value: String)]

        init(pairs: [(key: String, value: String)]) {
            self.parameter = ""
            self.parsedPairs = pairs
        }
    }

    func testExperimentalHiddenNames() throws {
        do {
            let options = try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "fields")]))
            XCTAssertEqual(options.experimentalHiddenNames, .fields)
        }
        do {
            let options = try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "enumValues")]))
            XCTAssertEqual(options.experimentalHiddenNames, .enumValues)
        }
        do {
            let options = try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "types")]))
            XCTAssertEqual(options.experimentalHiddenNames, .types)
        }
        do {
            let options = try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "all")]))
            XCTAssertEqual(options.experimentalHiddenNames, .all)
        }
        do {
            let options = try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "fields,types")]))
            XCTAssertEqual(options.experimentalHiddenNames, [.fields, .types])
        }
        XCTAssertThrowsError(
            try GeneratorOptions(parameter: MockParameter(pairs: [("ExperimentalHiddenNames", "unknownFeature")]))
        )
    }
}
