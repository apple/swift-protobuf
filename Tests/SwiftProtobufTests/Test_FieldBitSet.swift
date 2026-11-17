// Tests/SwiftProtobufTests/Test_FieldBitSet.swift - Tests for FieldBitSet and dense field indices
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import Testing

private func expectDecodingError<T>(
    _ expression: @autoclosure () throws -> T,
    code expectedCode: SwiftProtobufError.Code,
    messageContains expectedSubstring: String? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    do {
        _ = try expression()
        Issue.record("Expected \(expectedCode) error to be thrown", sourceLocation: sourceLocation)
    } catch let error as SwiftProtobufError {
        #expect(error.code == expectedCode, sourceLocation: sourceLocation)
        if let expectedSubstring {
            #expect(error.message.contains(expectedSubstring) == true, sourceLocation: sourceLocation)
        }
    } catch {
        Issue.record("Expected SwiftProtobufError, caught: \(error)", sourceLocation: sourceLocation)
    }
}

struct FieldBitSetTests: ~Copyable {
    struct NamedSchema: Sendable, CustomTestStringConvertible {
        let name: String
        let schema: MessageSchema

        var testDescription: String { name }
    }

    static let messageSchemas: [NamedSchema] = [
        NamedSchema(name: "Empty", schema: Google_Protobuf_Empty.messageSchema),
        NamedSchema(name: "Proto2TestAllTypes", schema: SwiftProtoTesting_TestAllTypes.messageSchema),
        NamedSchema(name: "Proto3TestAllTypes", schema: SwiftProtoTesting_Proto3_TestAllTypes.messageSchema),
        NamedSchema(name: "TestMap", schema: SwiftProtoTesting_TestMap.messageSchema),
        NamedSchema(
            name: "SwitchSplitMessage",
            schema: SwiftProtoTesting_SwitchSplit_SwitchSplitMessage.messageSchema
        ),
    ]

    static let mapFieldNumbers: [UInt32] = SwiftProtoTesting_TestMap.messageSchema.fields.map(\.fieldNumber)

    @Test(arguments: [0, 1, 62, 63, 64, 65, 126, 127])
    func `inline boundary bit insertion is isolated and avoids heap allocation`(index: Int) {
        var set = FieldBitSet()
        #expect(set.insert(fieldIndex: index) == true)
        #expect(set.insert(fieldIndex: index) == false)
        #expect(set.hasOverflowStorageForTesting == false)
        #expect(set.hasExtensionStorageForTesting == false)

        for neighbor in [index - 1, index + 1] where (0..<128).contains(neighbor) {
            #expect(set.insert(fieldIndex: neighbor) == true)
            #expect(set.insert(fieldIndex: neighbor) == false)
        }
        #expect(set.hasOverflowStorageForTesting == false)
        #expect(set.hasExtensionStorageForTesting == false)
    }

    @Test func `filling all 128 inline bits avoids overflow and extension allocation`() {
        var set = FieldBitSet()
        for index in 0..<128 {
            #expect(set.insert(fieldIndex: index) == true)
            #expect(set.insert(fieldIndex: index) == false)
        }
        #expect(set.hasOverflowStorageForTesting == false)
        #expect(set.hasExtensionStorageForTesting == false)
    }

    @Test(arguments: [128, 129, 190, 191, 192, 193, 254, 255, 256, 257, 511, 512, 513])
    func `overflow boundary bit insertion allocates overflow storage and isolates neighbors`(index: Int) {
        var set = FieldBitSet()
        #expect(set.insert(fieldIndex: index) == true)
        #expect(set.insert(fieldIndex: index) == false)
        #expect(set.hasOverflowStorageForTesting == true)
        #expect(set.hasExtensionStorageForTesting == false)

        #expect(set.insert(fieldIndex: index - 1) == true)
        #expect(set.insert(fieldIndex: index + 1) == true)
        #expect(set.insert(fieldIndex: index - 1) == false)
        #expect(set.insert(fieldIndex: index + 1) == false)
    }

    @Test func `sparse out-of-order overflow insertion preserves higher and lower words`() {
        var set = FieldBitSet()
        #expect(set.insert(fieldIndex: 320) == true)
        #expect(set.insert(fieldIndex: 128) == true)
        #expect(set.insert(fieldIndex: 512) == true)

        #expect(set.insert(fieldIndex: 320) == false)
        #expect(set.insert(fieldIndex: 128) == false)
        #expect(set.insert(fieldIndex: 512) == false)
        #expect(set.insert(fieldIndex: 129) == true)
        #expect(set.insert(fieldIndex: 319) == true)
    }

    @Test(arguments: [UInt32(1), 100, 536_870_911])
    func `extension field insertion allocates extension storage lazily`(fieldNumber: UInt32) {
        var set = FieldBitSet()
        #expect(set.hasExtensionStorageForTesting == false)

        #expect(set.insert(extensionFieldNumber: fieldNumber) == true)
        #expect(set.hasExtensionStorageForTesting == true)
        #expect(set.hasOverflowStorageForTesting == false)
        #expect(set.insert(extensionFieldNumber: fieldNumber) == false)
    }

    @Test func `extension field numbers do not collide with regular field indices`() {
        var set = FieldBitSet()
        #expect(set.insert(fieldIndex: 1) == true)
        #expect(set.insert(extensionFieldNumber: 1) == true)
        #expect(set.insert(extensionFieldNumber: 2) == true)
        #expect(set.insert(fieldIndex: 2) == true)
    }

    @Test func `copying FieldBitSet preserves inline bit value semantics`() {
        var original = FieldBitSet()
        #expect(original.insert(fieldIndex: 5) == true)
        #expect(original.insert(fieldIndex: 70) == true)

        var copy = original
        #expect(copy.insert(fieldIndex: 6) == true)
        #expect(copy.insert(fieldIndex: 71) == true)

        #expect(original.insert(fieldIndex: 6) == true)
        #expect(original.insert(fieldIndex: 71) == true)
        #expect(original.insert(fieldIndex: 5) == false)
        #expect(original.insert(fieldIndex: 70) == false)
        #expect(copy.insert(fieldIndex: 5) == false)
        #expect(copy.insert(fieldIndex: 70) == false)
    }

    @Test func `copying FieldBitSet preserves overflow bit value semantics`() {
        var original = FieldBitSet()
        #expect(original.insert(fieldIndex: 200) == true)

        var copy = original
        // Mutate both the existing overflow word and grow to a higher word on `copy`.
        #expect(copy.insert(fieldIndex: 201) == true)
        #expect(copy.insert(fieldIndex: 400) == true)

        #expect(original.insert(fieldIndex: 201) == true)
        #expect(original.insert(fieldIndex: 400) == true)
        #expect(original.insert(fieldIndex: 200) == false)
        #expect(copy.insert(fieldIndex: 200) == false)
    }

    @Test func `copying FieldBitSet preserves extension set value semantics`() {
        var original = FieldBitSet()
        #expect(original.insert(extensionFieldNumber: 1000) == true)

        var copy = original
        #expect(copy.insert(extensionFieldNumber: 1001) == true)

        #expect(original.insert(extensionFieldNumber: 1001) == true)
        #expect(original.insert(extensionFieldNumber: 1000) == false)
        #expect(copy.insert(extensionFieldNumber: 1000) == false)
    }

    @Test(arguments: messageSchemas)
    func `schema fieldIndex matches zero-based dense field order`(fixture: NamedSchema) throws {
        let schema = fixture.schema
        var count = 0
        for (expectedIndex, field) in schema.fields.enumerated() {
            #expect(schema.fieldIndex(of: field) == expectedIndex)
            let lookedUp = try #require(schema[fieldNumber: field.fieldNumber])
            #expect(schema.fieldIndex(of: lookedUp) == expectedIndex)
            count += 1
        }
        #expect(count == schema.fieldCount)
    }

    @Test(arguments: mapFieldNumbers)
    func `map entry subschema reports dense field indices zero and one`(fieldNumber: UInt32) throws {
        let mapOwnerSchema = SwiftProtoTesting_TestMap.messageSchema
        let mapField = try #require(mapOwnerSchema[fieldNumber: fieldNumber])
        let entrySchema = mapOwnerSchema.messageSchema(for: mapField)
        #expect(entrySchema.fieldCount == 2)

        let keyField = try #require(entrySchema[fieldNumber: 1])
        let valueField = try #require(entrySchema[fieldNumber: 2])
        #expect(entrySchema.fieldIndex(of: keyField) == 0)
        #expect(entrySchema.fieldIndex(of: valueField) == 1)
    }

    @Test(arguments: [
        "optional_int32: 0 optional_int32: 0",
        "optional_int32: 1 1: 2",
        "oneof_uint32: 0 oneof_uint32: 0",
    ])
    func `TextFormat rejects duplicate inline singular fields`(input: String) {
        expectDecodingError(
            try SwiftProtoTesting_Proto3_TestAllTypes(textFormatString: input),
            code: .textFormatDecodingError
        )
    }

    @Test func `TextFormat allows same field number and index in parent and nested submessage`() throws {
        typealias ParentMessage = SwiftProtoTesting_Proto3_TestAllTypes
        let parentField1 = try #require(ParentMessage.messageSchema[fieldNumber: 1])
        let childField1 = try #require(ParentMessage.NestedMessage.messageSchema[fieldNumber: 1])
        #expect(ParentMessage.messageSchema.fieldIndex(of: parentField1) == 0)
        #expect(ParentMessage.NestedMessage.messageSchema.fieldIndex(of: childField1) == 0)

        let decoded = try ParentMessage(
            textFormatString: "optional_int32: 10 optional_nested_message { bb: 20 }"
        )
        #expect(decoded.optionalInt32 == 10)
        #expect(decoded.optionalNestedMessage.bb == 20)
    }

    @Test func `TextFormat allows same fields across recursive submessage depths`() throws {
        let decoded = try SwiftProtoTesting_TestRecursiveMessage(
            textFormatString: "i: 1 a { i: 2 a { i: 3 } }"
        )
        #expect(decoded.i == 1)
        #expect(decoded.a.i == 2)
        #expect(decoded.a.a.i == 3)
    }

    @Test(arguments: [
        "optional_nested_message { bb: 1 bb: 2 }",
        "optional_int32: 10 optional_nested_message { bb: 0 bb: 0 }",
        "repeated_nested_message { bb: 1 } repeated_nested_message { bb: 2 bb: 3 }",
    ])
    func `TextFormat rejects duplicate fields inside nested submessages`(input: String) {
        expectDecodingError(
            try SwiftProtoTesting_Proto3_TestAllTypes(textFormatString: input),
            code: .textFormatDecodingError
        )
    }

    @Test(arguments: [
        "a { i: 1 i: 2 }",
        "i: 1 a { i: 2 a { i: 3 i: 4 } }",
    ])
    func `TextFormat rejects duplicate fields inside recursive submessages`(input: String) {
        expectDecodingError(
            try SwiftProtoTesting_TestRecursiveMessage(textFormatString: input),
            code: .textFormatDecodingError
        )
    }

    @Test func `TextFormat decodes non-duplicate fields above 128`() throws {
        typealias LargeMessage = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage
        #expect(LargeMessage.messageSchema.fieldCount > 128)

        let decoded = try LargeMessage(
            textFormatString: "regular_field_002: 2 regular_field_251: 251 regular_field_502: 502 field_500: 500"
        )
        #expect(decoded.regularField002 == 2)
        #expect(decoded.regularField251 == 251)
        #expect(decoded.regularField502 == 502)
        #expect(decoded.value == .field500(500))
    }

    @Test(arguments: [
        "regular_field_502: 0 regular_field_502: 0",
        "regular_field_502: 1 502: 2",
        "field_500: 0 field_500: 0",
    ])
    func `TextFormat rejects duplicate singular fields above 128`(input: String) {
        expectDecodingError(
            try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(textFormatString: input),
            code: .textFormatDecodingError
        )
    }

    @Test func `TextFormat reports conflicting oneof values for distinct members above 128`() {
        expectDecodingError(
            try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(textFormatString: "field_500: 0 field_501: 0"),
            code: .textFormatDecodingError,
            messageContains: "Conflicting oneof values"
        )
    }

    @Test func `TextFormat allows repeated extensions`() throws {
        let decoded = try SwiftProtoTesting_TestAllExtensions(
            textFormatString:
                "[swift_proto_testing.repeated_int32_extension]: 1 [swift_proto_testing.repeated_int32_extension]: 2",
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        #expect(decoded.SwiftProtoTesting_repeatedInt32Extension == [1, 2])
    }

    @Test func `TextFormat rejects duplicate singular extensions`() {
        expectDecodingError(
            try SwiftProtoTesting_TestAllExtensions(
                textFormatString:
                    "[swift_proto_testing.optional_int32_extension]: 1 [swift_proto_testing.optional_int32_extension]: 2",
                extensions: SwiftProtoTesting_Unittest_Extensions
            ),
            code: .textFormatDecodingError
        )
    }

    @Test(arguments: [
        "map_int32_int32 { key: 1 key: 2 value: 10 }",
        "map_int32_int32 { key: 1 value: 10 value: 20 }",
    ])
    func `TextFormat rejects duplicate key or value in map entry`(input: String) {
        expectDecodingError(
            try SwiftProtoTesting_TestMap(textFormatString: input),
            code: .textFormatDecodingError
        )
    }

    @Test(arguments: [
        #"{"optionalInt32": 0, "optionalInt32": 0}"#,
        #"{"optionalInt32": 1, "optional_int32": 2}"#,
        #"{"optionalInt32": null, "optionalInt32": null}"#,
        #"{"oneofString": "a", "oneofUint32": null, "oneofUint32": null}"#,
    ])
    func `JSON rejects duplicate inline singular fields`(json: String) {
        expectDecodingError(
            try SwiftProtoTesting_Proto3_TestAllTypes(jsonString: json),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test func `JSON allows same field number and index in parent and nested submessage`() throws {
        typealias ParentMessage = SwiftProtoTesting_Proto3_TestAllTypes
        let parentField1 = try #require(ParentMessage.messageSchema[fieldNumber: 1])
        let childField1 = try #require(ParentMessage.NestedMessage.messageSchema[fieldNumber: 1])
        #expect(ParentMessage.messageSchema.fieldIndex(of: parentField1) == 0)
        #expect(ParentMessage.NestedMessage.messageSchema.fieldIndex(of: childField1) == 0)

        let decoded = try ParentMessage(
            jsonString: #"{"optionalInt32": 10, "optionalNestedMessage": {"bb": 20}}"#
        )
        #expect(decoded.optionalInt32 == 10)
        #expect(decoded.optionalNestedMessage.bb == 20)
    }

    @Test func `JSON allows same fields across recursive submessage depths`() throws {
        let decoded = try SwiftProtoTesting_TestRecursiveMessage(
            jsonString: #"{"i": 1, "a": {"i": 2, "a": {"i": 3}}}"#
        )
        #expect(decoded.i == 1)
        #expect(decoded.a.i == 2)
        #expect(decoded.a.a.i == 3)
    }

    @Test(arguments: [
        #"{"optionalNestedMessage": {"bb": 1, "bb": 2}}"#,
        #"{"optionalInt32": 10, "optionalNestedMessage": {"bb": null, "bb": null}}"#,
        #"{"repeatedNestedMessage": [{"bb": 1}, {"bb": 2, "bb": 3}]}"#,
    ])
    func `JSON rejects duplicate fields inside nested submessages`(json: String) {
        expectDecodingError(
            try SwiftProtoTesting_Proto3_TestAllTypes(jsonString: json),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test(arguments: [
        #"{"a": {"i": 1, "i": 2}}"#,
        #"{"i": 1, "a": {"i": 2, "a": {"i": 3, "i": 4}}}"#,
    ])
    func `JSON rejects duplicate fields inside recursive submessages`(json: String) {
        expectDecodingError(
            try SwiftProtoTesting_TestRecursiveMessage(jsonString: json),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test func `JSON rejects duplicate repeated fields`() {
        expectDecodingError(
            try SwiftProtoTesting_Proto3_TestAllTypes(
                jsonString: #"{"repeatedInt32": [], "repeated_int32": []}"#
            ),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test func `JSON rejects duplicate map fields`() {
        expectDecodingError(
            try SwiftProtoTesting_TestMap(
                jsonString: #"{"mapInt32Int32": {}, "map_int32_int32": {}}"#
            ),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test func `JSON decodes non-duplicate fields above 128`() throws {
        typealias LargeMessage = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage
        #expect(LargeMessage.messageSchema.fieldCount > 128)

        let decoded = try LargeMessage(
            jsonString: #"{"regularField002": 2, "regularField251": 251, "regularField502": 502, "field500": 500}"#
        )
        #expect(decoded.regularField002 == 2)
        #expect(decoded.regularField251 == 251)
        #expect(decoded.regularField502 == 502)
        #expect(decoded.value == .field500(500))
    }

    @Test(arguments: [
        #"{"regularField502": 1, "regularField502": 2}"#,
        #"{"regularField502": 1, "regular_field_502": 2}"#,
        #"{"regularField502": null, "regularField502": null}"#,
        #"{"field500": 0, "field500": 0}"#,
    ])
    func `JSON rejects duplicate fields above 128`(json: String) {
        expectDecodingError(
            try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(jsonString: json),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }

    @Test(arguments: [
        #"{"[swift_proto_testing.optional_int32_extension]": 1, "[swift_proto_testing.optional_int32_extension]": 2}"#,
        #"{"[swift_proto_testing.optional_int32_extension]": null, "[swift_proto_testing.optional_int32_extension]": null}"#,
        #"{"[swift_proto_testing.repeated_int32_extension]": [1], "[swift_proto_testing.repeated_int32_extension]": [2]}"#,
    ])
    func `JSON rejects duplicate extensions`(json: String) {
        expectDecodingError(
            try SwiftProtoTesting_TestAllExtensions(
                jsonString: json,
                extensions: SwiftProtoTesting_Unittest_Extensions
            ),
            code: .jsonDecodingError,
            messageContains: "specified more than once"
        )
    }
}
