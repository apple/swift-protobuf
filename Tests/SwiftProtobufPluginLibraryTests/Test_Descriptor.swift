// Tests/SwiftProtobufPluginLibraryTests/Test_Descriptor.swift - Test Descriptor.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf
import XCTest

@testable import SwiftProtobufPluginLibrary

extension FileDescriptor {
    func extensionField(named: String) -> FieldDescriptor? {
        extensions.first { $0.name == named }
    }
}
extension Descriptor {
    func field(named: String) -> FieldDescriptor? {
        fields.first { $0.name == named }
    }
}

final class Test_Descriptor: XCTestCase {

    func testParsing() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

        let descriptorSet = DescriptorSet(proto: fileSet)
        XCTAssertEqual(descriptorSet.files.count, 7)
        // descriptor.proto documents the protoc will order the files based on the import
        // from plugin on descriptor.
        XCTAssertEqual(descriptorSet.files[0].name, "pluginlib_descriptor_test_import.proto")
        XCTAssertEqual(descriptorSet.files[1].name, "pluginlib_descriptor_test.proto")
        XCTAssertEqual(descriptorSet.files[2].name, "pluginlib_descriptor_test2.proto")
        XCTAssertEqual(descriptorSet.files[3].name, "pluginlib_descriptor_delimited.proto")
        XCTAssertEqual(descriptorSet.files[4].name, "unittest_delimited_import.proto")
        XCTAssertEqual(descriptorSet.files[5].name, "unittest_delimited.proto")
        XCTAssertEqual(descriptorSet.files[6].name, "swift_protobuf_module_mappings.proto")

        let importFileDescriptor = descriptorSet.files[0]

        XCTAssertEqual(importFileDescriptor.messages.count, 2)
        XCTAssertEqual(importFileDescriptor.messages[0].fullName, "swift_descriptor_test.import.Version")
        XCTAssertNil(importFileDescriptor.messages[0].containingType)
        XCTAssertEqual(importFileDescriptor.messages[0].messages.count, 0)
        XCTAssertEqual(importFileDescriptor.enums.count, 0)
        XCTAssertEqual(importFileDescriptor.extensions.count, 0)

        XCTAssertEqual(importFileDescriptor.messages[1].fullName, "swift_descriptor_test.import.ExtendableOne")
        XCTAssertNil(importFileDescriptor.messages[1].containingType)
        XCTAssertEqual(importFileDescriptor.messages[1].messages.count, 1)

        XCTAssertEqual(
            importFileDescriptor.messages[1].messages[0].fullName,
            "swift_descriptor_test.import.ExtendableOne.ExtendableTwo"
        )
        XCTAssertEqual(importFileDescriptor.messages[1].messages[0].messages.count, 0)

        let testFileDesciptor = descriptorSet.files[1]

        XCTAssertEqual(testFileDesciptor.enums.count, 1)
        XCTAssertEqual(testFileDesciptor.enums[0].fullName, "swift_descriptor_test.TopLevelEnum")
        XCTAssertNil(testFileDesciptor.enums[0].containingType)

        XCTAssertEqual(testFileDesciptor.messages[0].enums.count, 1)
        XCTAssertEqual(testFileDesciptor.messages[0].enums[0].fullName, "swift_descriptor_test.TopLevelMessage.SubEnum")
        XCTAssertTrue(testFileDesciptor.messages[0].enums[0].containingType === testFileDesciptor.messages[0])

        XCTAssertEqual(testFileDesciptor.messages[0].oneofs.count, 1)
        XCTAssertEqual(testFileDesciptor.messages[0].oneofs[0].name, "o")
        XCTAssertEqual(testFileDesciptor.messages[1].oneofs.count, 0)

        XCTAssertEqual(testFileDesciptor.extensions.count, 1)
        XCTAssertEqual(testFileDesciptor.extensions[0].name, "ext_str")
        XCTAssertEqual(testFileDesciptor.messages[3].extensions.count, 2)
        XCTAssertEqual(testFileDesciptor.messages[3].extensions[0].name, "ext_enum")
        XCTAssertEqual(testFileDesciptor.messages[3].extensions[1].name, "ext_msg")

        XCTAssertEqual(testFileDesciptor.services.count, 1)
        XCTAssertEqual(testFileDesciptor.services[0].fullName, "swift_descriptor_test.SomeService")
        XCTAssertEqual(testFileDesciptor.services[0].methods.count, 2)
        XCTAssertEqual(testFileDesciptor.services[0].methods[0].name, "Foo")
        XCTAssertEqual(testFileDesciptor.services[0].methods[1].name, "Bar")
    }

    func testLookup() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

        let descriptorSet = DescriptorSet(proto: fileSet)

        XCTAssertTrue(
            descriptorSet.fileDescriptor(named: "pluginlib_descriptor_test_import.proto") === descriptorSet.files[0]
        )

        XCTAssertTrue(
            descriptorSet.descriptor(named: "swift_descriptor_test.import.Version")
                === descriptorSet.files[0].messages[0]
        )
        XCTAssertTrue(
            descriptorSet.descriptor(named: "swift_descriptor_test.TopLevelMessage")
                === descriptorSet.files[1].messages[0]
        )
        XCTAssertTrue(
            descriptorSet.descriptor(named: "swift_descriptor_test.TopLevelMessage.SubMessage")
                === descriptorSet.files[1].messages[0].messages[0]
        )

        XCTAssertTrue(
            descriptorSet.enumDescriptor(named: "swift_descriptor_test.TopLevelEnum")
                === descriptorSet.files[1].enums[0]
        )
        XCTAssertTrue(
            descriptorSet.enumDescriptor(named: "swift_descriptor_test.TopLevelMessage.SubEnum")
                === descriptorSet.files[1].messages[0].enums[0]
        )

        XCTAssertTrue(
            descriptorSet.serviceDescriptor(named: "swift_descriptor_test.SomeService")
                === descriptorSet.files[1].services[0]
        )
    }

    func testParents() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

        let descriptorSet = DescriptorSet(proto: fileSet)

        let importVersion = descriptorSet.descriptor(named: "swift_descriptor_test.import.Version")!
        XCTAssertTrue(importVersion.containingType == nil)

        let importExtendOne = descriptorSet.descriptor(named: "swift_descriptor_test.import.ExtendableOne")!
        let importExtendTwo = descriptorSet.descriptor(
            named: "swift_descriptor_test.import.ExtendableOne.ExtendableTwo"
        )!
        XCTAssertTrue(importExtendTwo.containingType === importExtendOne)

        let testDescriptor = descriptorSet.descriptor(named: "swift_descriptor_test.TopLevelMessage")!
        let testEnum = descriptorSet.enumDescriptor(named: "swift_descriptor_test.TopLevelMessage.SubEnum")!
        XCTAssertTrue(testEnum.containingType === testDescriptor)

        let serviceDescProto = descriptorSet.serviceDescriptor(named: "swift_descriptor_test.SomeService")!
        let fooMethod = serviceDescProto.methods[0]
        XCTAssertTrue(fooMethod.service === serviceDescProto)
        let barMethod = serviceDescProto.methods[1]
        XCTAssertTrue(barMethod.service === serviceDescProto)

        let importFile = descriptorSet.files[0]
        let testFile = descriptorSet.files[1]

        XCTAssertTrue(importVersion.file === importFile)

        XCTAssertTrue(importExtendOne.file === importFile)
        XCTAssertTrue(importExtendTwo.file === importFile)

        XCTAssertTrue(testDescriptor.file === testFile)
        XCTAssertTrue(testEnum.file === testFile)
        XCTAssertTrue(serviceDescProto.file === testFile)
    }

    func testFields() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

        let descriptorSet = DescriptorSet(proto: fileSet)

        let topLevelEnum = descriptorSet.enumDescriptor(named: "swift_descriptor_test.TopLevelEnum")!
        let topLevelMessage = descriptorSet.descriptor(named: "swift_descriptor_test.TopLevelMessage")!
        let subEnum = topLevelMessage.enums[0]
        let subMessage = topLevelMessage.messages[0]
        let topLevelMessage2 = descriptorSet.descriptor(named: "swift_descriptor_test.TopLevelMessage2")!

        XCTAssertEqual(topLevelMessage.fields.count, 6)
        XCTAssertEqual(topLevelMessage.fields[0].name, "field1")
        XCTAssertEqual(topLevelMessage.fields[1].name, "field2")
        XCTAssertEqual(topLevelMessage.fields[2].name, "field3")
        XCTAssertEqual(topLevelMessage.fields[3].name, "field4")
        XCTAssertEqual(topLevelMessage.fields[4].name, "field5")
        XCTAssertEqual(topLevelMessage.fields[5].name, "field6")
        XCTAssertTrue(topLevelMessage.fields[2].enumType === topLevelEnum)
        XCTAssertTrue(topLevelMessage.fields[3].enumType === subEnum)
        XCTAssertTrue(topLevelMessage.fields[4].messageType === subMessage)
        XCTAssertTrue(topLevelMessage.fields[5].messageType === topLevelMessage2)

        let oneof = topLevelMessage.oneofs[0]
        XCTAssertTrue(oneof.containingType === topLevelMessage)
        XCTAssertEqual(oneof.fields.count, 4)
        XCTAssertTrue(oneof.fields[0] === topLevelMessage.fields[2])
        XCTAssertTrue(oneof.fields[1] === topLevelMessage.fields[3])
        XCTAssertTrue(oneof.fields[2] === topLevelMessage.fields[4])
        XCTAssertTrue(oneof.fields[3] === topLevelMessage.fields[5])

        XCTAssertEqual(topLevelMessage2.fields.count, 2)
        XCTAssertEqual(topLevelMessage2.fields[0].name, "left")
        XCTAssertEqual(topLevelMessage2.fields[1].name, "right")
        XCTAssertTrue(topLevelMessage2.fields[0].messageType === topLevelMessage)
        XCTAssertTrue(topLevelMessage2.fields[1].messageType === topLevelMessage2)

        let externalRefs = descriptorSet.descriptor(named: "swift_descriptor_test.ExternalRefs")!
        let extendOne = descriptorSet.descriptor(named: "swift_descriptor_test.import.ExtendableOne")!
        let testImportVersion = descriptorSet.descriptor(named: "swift_descriptor_test.import.Version")!

        XCTAssertEqual(externalRefs.fields.count, 2)
        XCTAssertEqual(externalRefs.fields[0].name, "one")
        XCTAssertEqual(externalRefs.fields[1].name, "ver")
        XCTAssertTrue(externalRefs.fields[0].messageType === extendOne)
        XCTAssertTrue(externalRefs.fields[1].messageType === testImportVersion)

        // Proto2 Presence

        let proto2ForPresence = descriptorSet.descriptor(named: "swift_descriptor_test.Proto2MessageForPresence")!

        XCTAssertEqual(proto2ForPresence.fields.count, 16)
        XCTAssertEqual(proto2ForPresence.fields[0].name, "req_str_field")
        XCTAssertEqual(proto2ForPresence.fields[1].name, "req_int32_field")
        XCTAssertEqual(proto2ForPresence.fields[2].name, "req_enum_field")
        XCTAssertEqual(proto2ForPresence.fields[3].name, "req_message_field")
        XCTAssertEqual(proto2ForPresence.fields[4].name, "opt_str_field")
        XCTAssertEqual(proto2ForPresence.fields[5].name, "opt_int32_field")
        XCTAssertEqual(proto2ForPresence.fields[6].name, "opt_enum_field")
        XCTAssertEqual(proto2ForPresence.fields[7].name, "opt_message_field")
        XCTAssertEqual(proto2ForPresence.fields[8].name, "repeat_str_field")
        XCTAssertEqual(proto2ForPresence.fields[9].name, "repeat_int32_field")
        XCTAssertEqual(proto2ForPresence.fields[10].name, "repeat_enum_field")
        XCTAssertEqual(proto2ForPresence.fields[11].name, "repeat_message_field")
        XCTAssertEqual(proto2ForPresence.fields[12].name, "oneof_str_field")
        XCTAssertEqual(proto2ForPresence.fields[13].name, "oneof_int32_field")
        XCTAssertEqual(proto2ForPresence.fields[14].name, "oneof_enum_field")
        XCTAssertEqual(proto2ForPresence.fields[15].name, "oneof_message_field")

        XCTAssertFalse(proto2ForPresence.fields[0]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[1]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[2]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[3]._hasOptionalKeyword)
        XCTAssertTrue(proto2ForPresence.fields[4]._hasOptionalKeyword)
        XCTAssertTrue(proto2ForPresence.fields[5]._hasOptionalKeyword)
        XCTAssertTrue(proto2ForPresence.fields[6]._hasOptionalKeyword)
        XCTAssertTrue(proto2ForPresence.fields[7]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[8]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[9]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[10]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[11]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[12]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[13]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[14]._hasOptionalKeyword)
        XCTAssertFalse(proto2ForPresence.fields[15]._hasOptionalKeyword)

        XCTAssertTrue(proto2ForPresence.fields[0].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[1].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[2].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[3].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[4].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[5].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[6].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[7].hasPresence)
        XCTAssertFalse(proto2ForPresence.fields[8].hasPresence)
        XCTAssertFalse(proto2ForPresence.fields[9].hasPresence)
        XCTAssertFalse(proto2ForPresence.fields[10].hasPresence)
        XCTAssertFalse(proto2ForPresence.fields[11].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[12].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[13].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[14].hasPresence)
        XCTAssertTrue(proto2ForPresence.fields[15].hasPresence)

        // No synthetic oneof in proto2 syntax, so the lists should be the same.
        XCTAssertEqual(proto2ForPresence.oneofs.count, proto2ForPresence.realOneofs.count)
        for (i, o) in proto2ForPresence.realOneofs.enumerated() {
            XCTAssert(o === proto2ForPresence.oneofs[i])
        }

        // Proto3 Presence

        let proto3ForPresence = descriptorSet.descriptor(named: "swift_descriptor_test.Proto3MessageForPresence")!
        XCTAssertEqual(proto3ForPresence.fields.count, 16)
        XCTAssertEqual(proto3ForPresence.fields[0].name, "str_field")
        XCTAssertEqual(proto3ForPresence.fields[1].name, "int32_field")
        XCTAssertEqual(proto3ForPresence.fields[2].name, "enum_field")
        XCTAssertEqual(proto3ForPresence.fields[3].name, "message_field")
        XCTAssertEqual(proto3ForPresence.fields[4].name, "opt_str_field")
        XCTAssertEqual(proto3ForPresence.fields[5].name, "opt_int32_field")
        XCTAssertEqual(proto3ForPresence.fields[6].name, "opt_enum_field")
        XCTAssertEqual(proto3ForPresence.fields[7].name, "opt_message_field")
        XCTAssertEqual(proto3ForPresence.fields[8].name, "repeat_str_field")
        XCTAssertEqual(proto3ForPresence.fields[9].name, "repeat_int32_field")
        XCTAssertEqual(proto3ForPresence.fields[10].name, "repeat_enum_field")
        XCTAssertEqual(proto3ForPresence.fields[11].name, "repeat_message_field")
        XCTAssertEqual(proto3ForPresence.fields[12].name, "oneof_str_field")
        XCTAssertEqual(proto3ForPresence.fields[13].name, "oneof_int32_field")
        XCTAssertEqual(proto3ForPresence.fields[14].name, "oneof_enum_field")
        XCTAssertEqual(proto3ForPresence.fields[15].name, "oneof_message_field")

        XCTAssertFalse(proto3ForPresence.fields[0]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[1]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[2]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[3]._hasOptionalKeyword)
        XCTAssertTrue(proto3ForPresence.fields[4]._hasOptionalKeyword)
        XCTAssertTrue(proto3ForPresence.fields[5]._hasOptionalKeyword)
        XCTAssertTrue(proto3ForPresence.fields[6]._hasOptionalKeyword)
        XCTAssertTrue(proto3ForPresence.fields[7]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[8]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[9]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[10]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[11]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[12]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[13]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[14]._hasOptionalKeyword)
        XCTAssertFalse(proto3ForPresence.fields[15]._hasOptionalKeyword)

        XCTAssertFalse(proto3ForPresence.fields[0].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[1].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[2].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[3].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[4].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[5].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[6].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[7].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[8].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[9].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[10].hasPresence)
        XCTAssertFalse(proto3ForPresence.fields[11].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[12].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[13].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[14].hasPresence)
        XCTAssertTrue(proto3ForPresence.fields[15].hasPresence)

        // Synthetic oneof in proto3 syntax for the 'optional' fields, so
        // the lists should NOTE be the same, `realOneofs` one should be a
        // prefix of `oneofs`.
        XCTAssertTrue(proto3ForPresence.oneofs.count > proto3ForPresence.realOneofs.count)
        for (i, o) in proto2ForPresence.realOneofs.enumerated() {
            XCTAssert(o === proto2ForPresence.oneofs[i])
        }
    }

    func testExtensions() throws {
        // Extensions are a little different in how they have extensionScope and
        // containingType, so they are split out to be a clear test of their behaviors.

        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)

        let descriptorSet = DescriptorSet(proto: fileSet)

        let extendOne = descriptorSet.descriptor(named: "swift_descriptor_test.import.ExtendableOne")!
        let extendTwo = descriptorSet.descriptor(named: "swift_descriptor_test.import.ExtendableOne.ExtendableTwo")!

        let descriptorTestFile = descriptorSet.files[1]

        let topLevelExt = descriptorTestFile.extensions[0]
        XCTAssertNil(topLevelExt.extensionScope)
        XCTAssertTrue(topLevelExt.containingType === extendOne)

        let extScoper = descriptorSet.descriptor(named: "swift_descriptor_test.ScoperForExt")!
        let nestedExt1 = descriptorTestFile.messages[3].extensions[0]
        let nestedExt2 = descriptorTestFile.messages[3].extensions[1]
        XCTAssertTrue(nestedExt1.extensionScope === extScoper)
        XCTAssertTrue(nestedExt1.containingType === extendTwo)
        XCTAssertTrue(nestedExt2.extensionScope === extScoper)
        XCTAssertTrue(nestedExt2.containingType === extendTwo)

        XCTAssertTrue(nestedExt1.enumType === descriptorTestFile.enums[0])
        XCTAssertTrue(nestedExt2.messageType === descriptorTestFile.messages[1])

        XCTAssertTrue(topLevelExt.file === descriptorTestFile)
        XCTAssertTrue(nestedExt1.file === descriptorTestFile)
        XCTAssertTrue(nestedExt2.file === descriptorTestFile)
    }

    func testDelimited() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(
            descriptorSet.descriptor(named: SwiftDescriptorTest_EditionsMessageForDelimited.protoMessageName)
        )

        XCTAssertEqual(try XCTUnwrap(msg.field(named: "scalar_field")).type, .int32)
        XCTAssertEqual(try XCTUnwrap(msg.field(named: "map_field")).type, .message)
        XCTAssertEqual(try XCTUnwrap(msg.field(named: "message_map_field")).type, .message)
        XCTAssertEqual(try XCTUnwrap(msg.field(named: "delimited_field")).type, .group)
        XCTAssertEqual(try XCTUnwrap(msg.field(named: "length_prefixed_field")).type, .message)
    }

    func testIsGroupLike_GroupLikeDelimited() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(descriptorSet.descriptor(named: EditionsUnittest_TestDelimited.protoMessageName))
        let file = try XCTUnwrap(msg.file)

        XCTAssertTrue(try XCTUnwrap(msg.field(named: "grouplike")).internal_isGroupLike)
        XCTAssertTrue(try XCTUnwrap(file.extensionField(named: "grouplikefilescope")).internal_isGroupLike)
    }

    func testIsGroupLike_GroupLikeNotDelimited() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(descriptorSet.descriptor(named: EditionsUnittest_TestDelimited.protoMessageName))
        let file = try XCTUnwrap(msg.file)

        XCTAssertFalse(try XCTUnwrap(msg.field(named: "lengthprefixed")).internal_isGroupLike)
        XCTAssertFalse(try XCTUnwrap(file.extensionField(named: "lengthprefixed")).internal_isGroupLike)
    }

    func testIsGroupLike_GroupLikeMismatchedName() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(descriptorSet.descriptor(named: EditionsUnittest_TestDelimited.protoMessageName))
        let file = try XCTUnwrap(msg.file)

        XCTAssertFalse(try XCTUnwrap(msg.field(named: "notgrouplike")).internal_isGroupLike)
        XCTAssertFalse(try XCTUnwrap(file.extensionField(named: "not_group_like_scope")).internal_isGroupLike)
    }

    func testIsGroupLike_GroupLikeMismatchedScope() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(descriptorSet.descriptor(named: EditionsUnittest_TestDelimited.protoMessageName))
        let file = try XCTUnwrap(msg.file)

        XCTAssertFalse(try XCTUnwrap(msg.field(named: "notgrouplikescope")).internal_isGroupLike)
        XCTAssertFalse(try XCTUnwrap(file.extensionField(named: "grouplike")).internal_isGroupLike)
    }

    func testIsGroupLike_GroupLikeMismatchedFile() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let msg = try XCTUnwrap(descriptorSet.descriptor(named: EditionsUnittest_TestDelimited.protoMessageName))
        let file = try XCTUnwrap(msg.file)

        XCTAssertFalse(try XCTUnwrap(msg.field(named: "messageimport")).internal_isGroupLike)
        XCTAssertFalse(try XCTUnwrap(file.extensionField(named: "messageimport")).internal_isGroupLike)
    }

    func testExtractProto_Options() throws {
        let fileSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: fileDescriptorSetBytes)
        let descriptorSet = DescriptorSet(proto: fileSet)

        let fileDescriptor = descriptorSet.fileDescriptor(named: "pluginlib_descriptor_test.proto")!

        // NOTE: There should be a full tests for ExtractProto that validates all the sub descriptor
        // protos. But for now, given the function's implementation, just test that the options are
        // honored correctly.

        // Default:
        // - includeSourceCodeInfo = false
        // - headerOnly = false
        do {
            let extract = fileDescriptor.extractProto()
            XCTAssertFalse(extract.hasSourceCodeInfo, "Included SourceCodeInfo?")
            XCTAssertFalse(extract.messageType.isEmpty, "Missing messages?")
            XCTAssertFalse(extract.enumType.isEmpty, "Missing enums?")
            XCTAssertFalse(extract.extension.isEmpty, "Missing extensions?")
            XCTAssertFalse(extract.service.isEmpty, "Missing services?")
        }

        var options = ExtractProtoOptions()
        options.includeSourceCodeInfo = true
        // - includeSourceCodeInfo = true
        // - headerOnly = false
        do {
            let extract = fileDescriptor.extractProto(options: options)
            XCTAssertTrue(extract.hasSourceCodeInfo, "Missing SourceCodeInfo?")
            XCTAssertFalse(extract.messageType.isEmpty, "Missing messages?")
            XCTAssertFalse(extract.enumType.isEmpty, "Missing enums?")
            XCTAssertFalse(extract.extension.isEmpty, "Missing extensions?")
            XCTAssertFalse(extract.service.isEmpty, "Missing services?")
        }

        options.headerOnly = true
        // - includeSourceCodeInfo = true
        // - headerOnly = true
        do {
            let extract = fileDescriptor.extractProto(options: options)
            XCTAssertTrue(extract.hasSourceCodeInfo, "Missing SourceCodeInfo?")
            XCTAssertTrue(extract.messageType.isEmpty, "Incuded messages?")
            XCTAssertTrue(extract.enumType.isEmpty, "Incuded enums?")
            XCTAssertTrue(extract.extension.isEmpty, "Missing extensions?")
            XCTAssertTrue(extract.service.isEmpty, "Missing services?")
        }

        options.includeSourceCodeInfo = false
        // - includeSourceCodeInfo = false
        // - headerOnly = false
        do {
            let extract = fileDescriptor.extractProto(options: options)
            XCTAssertFalse(extract.hasSourceCodeInfo, "Included SourceCodeInfo?")
            XCTAssertTrue(extract.messageType.isEmpty, "Incuded messages?")
            XCTAssertTrue(extract.enumType.isEmpty, "Incuded enums?")
            XCTAssertTrue(extract.extension.isEmpty, "Missing extensions?")
            XCTAssertTrue(extract.service.isEmpty, "Missing services?")
        }
    }
}
