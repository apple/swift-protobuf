// Tests/protoc-gen-swiftTests/Test_DescriptorExtensions.swift - Test Descriptor+Extenions.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf
import SwiftProtobufPluginLibrary
@testable import protoc_gen_swift

class Test_DescriptorExtensions: XCTestCase {

  func testExtensionRanges() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)

    let msgDescriptor = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrdering")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor.extensionRanges.count, 9)
    XCTAssertEqual(msgDescriptor.extensionRanges[0].start, 1)
    XCTAssertEqual(msgDescriptor.extensionRanges[1].start, 3)
    XCTAssertEqual(msgDescriptor.extensionRanges[2].start, 2)
    XCTAssertEqual(msgDescriptor.extensionRanges[3].start, 4)
    XCTAssertEqual(msgDescriptor.extensionRanges[4].start, 7)
    XCTAssertEqual(msgDescriptor.extensionRanges[5].start, 9)
    XCTAssertEqual(msgDescriptor.extensionRanges[6].start, 100)
    XCTAssertEqual(msgDescriptor.extensionRanges[7].start, 126)
    XCTAssertEqual(msgDescriptor.extensionRanges[8].start, 111)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges.count, 5)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[1].upperBound, 8)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[2].lowerBound, 9)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[2].upperBound, 10)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[3].lowerBound, 100)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[3].upperBound, 121)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[4].lowerBound, 126)
    XCTAssertEqual(msgDescriptor.normalizedExtensionRanges[4].upperBound, 131)


    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor.ambitiousExtensionRanges.count, 1)
    XCTAssertEqual(msgDescriptor.ambitiousExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor.ambitiousExtensionRanges[0].upperBound, 131)

    let msgDescriptor2 = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrderingWithFields")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor2.extensionRanges.count, 9)
    XCTAssertEqual(msgDescriptor2.extensionRanges[0].start, 1)
    XCTAssertEqual(msgDescriptor2.extensionRanges[1].start, 3)
    XCTAssertEqual(msgDescriptor2.extensionRanges[2].start, 2)
    XCTAssertEqual(msgDescriptor2.extensionRanges[3].start, 4)
    XCTAssertEqual(msgDescriptor2.extensionRanges[4].start, 7)
    XCTAssertEqual(msgDescriptor2.extensionRanges[5].start, 9)
    XCTAssertEqual(msgDescriptor2.extensionRanges[6].start, 100)
    XCTAssertEqual(msgDescriptor2.extensionRanges[7].start, 126)
    XCTAssertEqual(msgDescriptor2.extensionRanges[8].start, 111)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges.count, 5)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[1].upperBound, 8)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[2].lowerBound, 9)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[2].upperBound, 10)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[3].lowerBound, 100)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[3].upperBound, 121)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[4].lowerBound, 126)
    XCTAssertEqual(msgDescriptor2.normalizedExtensionRanges[4].upperBound, 131)


    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[0].lowerBound, 1)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[0].upperBound, 5)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[1].upperBound, 121)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[2].lowerBound, 126)
    XCTAssertEqual(msgDescriptor2.ambitiousExtensionRanges[2].upperBound, 131)

    let msgDescriptor3 = descriptorSet.descriptor(named: "swift_descriptor_test.MsgExtensionRangeOrderingNoMerging")!
    // Quick check of what should be in the proto file
    XCTAssertEqual(msgDescriptor3.extensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3.extensionRanges[0].start, 3)
    XCTAssertEqual(msgDescriptor3.extensionRanges[1].start, 7)
    XCTAssertEqual(msgDescriptor3.extensionRanges[2].start, 16)

    // Check sorting/merging
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[0].lowerBound, 3)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[0].upperBound, 6)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[1].upperBound, 13)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[2].lowerBound, 16)
    XCTAssertEqual(msgDescriptor3.normalizedExtensionRanges[2].upperBound, 21)

    // Check the "ambitious" merging.
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges.count, 3)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[0].lowerBound, 3)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[0].upperBound, 6)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[1].lowerBound, 7)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[1].upperBound, 13)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[2].lowerBound, 16)
    XCTAssertEqual(msgDescriptor3.ambitiousExtensionRanges[2].upperBound, 21)
  }

  func testEnumValueAliasing() throws {
    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"TestEnum\"",
      "  options {",
      "     allow_alias: true",
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_FOO\"",
      "    number: 0",  // Primary
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"TESTENUM_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_ALIAS\"",
      "    number: 0",  // Alias (unique name)
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
      fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let e = descriptorSet.enumDescriptor(named: "TestEnum")!
    let values = e.values
    XCTAssertEqual(values.count, 6)

    let aliasInfo = EnumDescriptor.ValueAliasInfo(enumDescriptor: e)

    // Check mainValues

    XCTAssertEqual(aliasInfo.mainValues.count, 2)
    XCTAssertIdentical(aliasInfo.mainValues[0], e.values[0])
    XCTAssertIdentical(aliasInfo.mainValues[1], e.values[1])

    // Check aliases(_:)

    XCTAssertEqual(aliasInfo.aliases(e.values[0])!.count, 4)
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![0], e.values[2])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![1], e.values[3])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![2], e.values[4])
    XCTAssertIdentical(aliasInfo.aliases(e.values[0])![3], e.values[5])
    XCTAssertNil(aliasInfo.aliases(e.values[1]))  // primary with no aliases
    XCTAssertNil(aliasInfo.aliases(e.values[2]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[3]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[4]))  // it itself is an alias
    XCTAssertNil(aliasInfo.aliases(e.values[5]))  // it itself is an alias

    // Check original(of:)

    XCTAssertNil(aliasInfo.original(of: e.values[0]))
    XCTAssertNil(aliasInfo.original(of: e.values[1]))
    XCTAssertIdentical(aliasInfo.original(of: e.values[2]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[3]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[4]), e.values[0])
    XCTAssertIdentical(aliasInfo.original(of: e.values[5]), e.values[0])
  }

}
