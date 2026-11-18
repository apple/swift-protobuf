// Tests/protoc-gen-swiftTests/Test_GeneratorOptions.swift - Test GeneratorOptions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf
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

@Test func experimentalWeakImports() throws {
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalWeakImports", "true")]))
        #expect(options.experimentalWeakImports)
    }
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalWeakImports", "")]))
        #expect(options.experimentalWeakImports)
    }
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalWeakImports", "false")]))
        #expect(!options.experimentalWeakImports)
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(parameter: FakeParameter(pairs: [("ExperimentalWeakImports", "invalid")]))
    }
}

@Test func enumGeneration() throws {
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: []))
        #expect(options.enumGeneration == .none)
        #expect(options.enumAnnotation == "")
    }
    do {
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: [("EnumGeneration", "None")]))
        #expect(options.enumGeneration == .none)
        #expect(options.enumAnnotation == "")
    }
    do {
        let options = try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("Visibility", "Public"),
                ("EnumGeneration", "NonExhaustive"),
            ])
        )
        #expect(options.enumGeneration == .nonexhaustive)
        #expect(options.enumAnnotation == "@nonexhaustive ")
    }
    do {
        let options = try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("Visibility", "Package"),
                ("EnumGeneration", "NonexhaustiveWarn"),
            ])
        )
        #expect(options.enumGeneration == .nonexhaustiveWarn)
        #expect(options.enumAnnotation == "@nonexhaustive(warn) ")
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(parameter: FakeParameter(pairs: [("EnumGeneration", "NonExhaustive")]))
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("Visibility", "Internal"),
                ("EnumGeneration", "NonexhaustiveWarn"),
            ])
        )
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("ImplementationOnlyImports", "true"),
                ("EnumGeneration", "NonExhaustive"),
            ])
        )
    }
    #expect(throws: (any Error).self) {
        try GeneratorOptions(
            parameter: FakeParameter(pairs: [
                ("Visibility", "Public"),
                ("EnumGeneration", "invalid"),
            ])
        )
    }
}

@Test func enumGenerationCodegen() throws {
    func generate(protoTextFormat: String, pairs: [(key: String, value: String)]) throws -> String {
        let fileProto = try Google_Protobuf_FileDescriptorProto(textFormatString: protoTextFormat)
        let descriptorSet = DescriptorSet(protos: [fileProto])
        let fileDescriptor = try #require(descriptorSet.files.first)
        let options = try GeneratorOptions(parameter: FakeParameter(pairs: pairs))
        let generator = FileGenerator(fileDescriptor: fileDescriptor, generatorOptions: options)
        var printer = CodePrinter(addNewlines: true)
        var errorString: String?
        generator.generateOutputFile(printer: &printer, errorString: &errorString)
        #expect(errorString == nil)
        return printer.content
    }

    let proto3Fixture = """
        name: "open_and_oneof.proto"
        syntax: "proto3"
        enum_type {
          name: "OpenEnum"
          value { name: "OPEN_ENUM_UNSPECIFIED" number: 0 }
        }
        message_type {
          name: "Holder"
          field {
            name: "text"
            number: 1
            label: LABEL_OPTIONAL
            type: TYPE_STRING
            oneof_index: 0
            json_name: "text"
          }
          oneof_decl { name: "payload" }
        }
        """

    let publicNonexhaustive = try generate(
        protoTextFormat: proto3Fixture,
        pairs: [("Visibility", "Public"), ("EnumGeneration", "NonExhaustive")]
    )
    #expect(publicNonexhaustive.contains("@nonexhaustive public nonisolated enum OpenEnum:"))
    #expect(publicNonexhaustive.contains("@nonexhaustive public nonisolated enum OneOf_Payload:"))

    let packageWarn = try generate(
        protoTextFormat: proto3Fixture,
        pairs: [("Visibility", "Package"), ("EnumGeneration", "NonexhaustiveWarn")]
    )
    #expect(packageWarn.contains("@nonexhaustive(warn) package nonisolated enum OpenEnum:"))
    #expect(packageWarn.contains("@nonexhaustive(warn) package nonisolated enum OneOf_Payload:"))

    let closedFixture = """
        name: "closed.proto"
        syntax: "proto2"
        enum_type {
          name: "ClosedEnum"
          value { name: "CLOSED_ZERO" number: 0 }
        }
        """
    let closedOutput = try generate(
        protoTextFormat: closedFixture,
        pairs: [("Visibility", "Public"), ("EnumGeneration", "NonExhaustive")]
    )
    #expect(closedOutput.contains("\npublic nonisolated enum ClosedEnum:"))
    #expect(!closedOutput.contains("@nonexhaustive"))

    // `swift_protobuf.ImplicitWeakEnum` is forced internal even under `Visibility=Public`,
    // so it must not receive `@nonexhaustive` (which Swift rejects on internal declarations).
    let implicitWeakFixture = """
        name: "implicit_weak_message.proto"
        package: "swift_protobuf"
        syntax: "editions"
        edition: EDITION_2023
        enum_type {
          name: "ImplicitWeakEnum"
          value { name: "ZERO" number: 0 }
        }
        """
    let implicitWeakOutput = try generate(
        protoTextFormat: implicitWeakFixture,
        pairs: [("Visibility", "Public"), ("EnumGeneration", "NonExhaustive")]
    )
    #expect(implicitWeakOutput.contains("\nnonisolated enum SwiftProtobuf_ImplicitWeakEnum:"))
    #expect(!implicitWeakOutput.contains("@nonexhaustive"))
}
