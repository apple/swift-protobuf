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
import protoc_gen_swift

final class Test_GeneratorOptions: XCTestCase {
    private struct FakeParameter: CodeGeneratorParameter {
        let parameter: String
        let parsedPairs: [(key: String, value: String)]

        init(pairs: [(key: String, value: String)]) {
            self.parameter = ""
            self.parsedPairs = pairs
        }
    }

    func testExperimentalHiddenNames() throws {
        do {
            let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Fields")]))
            XCTAssertEqual(options.experimentalHiddenNames, .fields)
        }
        do {
            let options = try GeneratorOptions(
                parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "EnumValues")])
            )
            XCTAssertEqual(options.experimentalHiddenNames, .enumValues)
        }
        do {
            let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Types")]))
            XCTAssertEqual(options.experimentalHiddenNames, .types)
        }
        do {
            let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "All")]))
            XCTAssertEqual(options.experimentalHiddenNames, .all)
        }
        do {
            let options = try GeneratorOptions(
                parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "Fields,Types")])
            )
            XCTAssertEqual(options.experimentalHiddenNames, [.fields, .types])
        }
        XCTAssertThrowsError(
            try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalHiddenNames", "unknownFeature")]))
        )
    }

    func testProtoPathModuleMappings() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let path1 = tempDir.appendingPathComponent("map1.asciipb").path
        let path2 = tempDir.appendingPathComponent("map2.asciipb").path

        let config1Text = """
        mapping { module_name: "Core", proto_file_path: "core.proto" }
        """
        let config2Text = """
        mapping { module_name: "Auth", proto_file_path: "auth.proto" }
        """

        try config1Text.write(toFile: path1, atomically: true, encoding: .utf8)
        try config2Text.write(toFile: path2, atomically: true, encoding: .utf8)

        let options = try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("ProtoPathModuleMappings", path1),
                ("ProtoPathModuleMappings", path2),
            ])
        )
        XCTAssertTrue(options.protoToModuleMappings.hasMappings)
        XCTAssertEqual(options.protoToModuleMappings.mappings["core.proto"], "Core")
        XCTAssertEqual(options.protoToModuleMappings.mappings["auth.proto"], "Auth")
    }
}

