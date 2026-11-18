// Tests/SwiftProtobufTests/Test_Oneof.swift - Copy-on-write tests for oneof fields
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

struct OneofCopyOnWriteTests: ~Copyable {
    // MARK: - Proto2

    @Test func `clearing oneof on a copied proto2 message preserves original scalar and enum values`() {
        var origInt = SwiftProtoTesting_Message2()
        origInt.oneofInt32 = 51
        var copyInt = origInt
        copyInt.o = nil

        #expect(copyInt.o == nil)
        #expect(copyInt.oneofInt32 == 100)
        #expect(origInt.o == .oneofInt32(51))
        #expect(origInt.oneofInt32 == 51)

        var origEnum = SwiftProtoTesting_Message2()
        origEnum.oneofEnum = .bar
        var copyEnum = origEnum
        copyEnum.o = nil

        #expect(copyEnum.o == nil)
        #expect(copyEnum.oneofEnum == .baz)
        #expect(origEnum.o == .oneofEnum(.bar))
        #expect(origEnum.oneofEnum == .bar)
    }

    @Test func `clearing oneof on a copied proto2 message preserves original string and bytes values`() {
        let longString = String(repeating: "proto2-oneof-string-", count: 8)
        var origString = SwiftProtoTesting_Message2()
        origString.oneofString = longString
        var copyString = origString
        copyString.o = nil

        #expect(copyString.o == nil)
        #expect(copyString.oneofString == "string")
        #expect(origString.o == .oneofString(longString))
        #expect(origString.oneofString == longString)

        copyString.oneofInt32 = 777
        #expect(origString.o == .oneofString(longString))
        #expect(origString.oneofString == longString)

        let largeBytes = Data(repeating: 0xAB, count: 64)
        var origBytes = SwiftProtoTesting_Message2()
        origBytes.oneofBytes = largeBytes
        var copyBytes = origBytes
        copyBytes.o = nil

        #expect(copyBytes.o == nil)
        #expect(copyBytes.oneofBytes == Data("data".utf8))
        #expect(origBytes.o == .oneofBytes(largeBytes))
        #expect(origBytes.oneofBytes == largeBytes)

        copyBytes.oneofInt32 = 888
        #expect(origBytes.o == .oneofBytes(largeBytes))
        #expect(origBytes.oneofBytes == largeBytes)
    }

    @Test func `clearing oneof on a copied proto2 message preserves original message and group values`() {
        let nestedString = String(repeating: "proto2-nested-", count: 8)
        var subMsg = SwiftProtoTesting_Message2()
        subMsg.optionalInt32 = 66
        subMsg.optionalString = nestedString

        var origMsg = SwiftProtoTesting_Message2()
        origMsg.oneofMessage = subMsg
        var copyMsg = origMsg
        copyMsg.o = nil

        #expect(copyMsg.o == nil)
        #expect(copyMsg.oneofMessage.hasOptionalInt32 == false)
        #expect(copyMsg.oneofMessage.optionalInt32 == 0)
        #expect(origMsg.o == .oneofMessage(subMsg))
        #expect(origMsg.oneofMessage.optionalInt32 == 66)
        #expect(origMsg.oneofMessage.optionalString == nestedString)

        var grp = SwiftProtoTesting_Message2.OneofGroup()
        grp.a = 66
        var origGroup = SwiftProtoTesting_Message2()
        origGroup.oneofGroup = grp
        var copyGroup = origGroup
        copyGroup.o = nil

        #expect(copyGroup.o == nil)
        #expect(copyGroup.oneofGroup.hasA == false)
        #expect(copyGroup.oneofGroup.a == 116)
        #expect(origGroup.o == .oneofGroup(grp))
        #expect(origGroup.oneofGroup.hasA == true)
        #expect(origGroup.oneofGroup.a == 66)
    }

    @Test func `clearing oneof on original proto2 message preserves snapshot copy`() {
        let longString = String(repeating: "proto2-snapshot-", count: 8)
        var orig = SwiftProtoTesting_Message2()
        orig.oneofString = longString
        let snapshot = orig
        orig.o = nil

        #expect(orig.o == nil)
        #expect(orig.oneofString == "string")
        #expect(snapshot.o == .oneofString(longString))
        #expect(snapshot.oneofString == longString)
    }

    // MARK: - Proto3

    @Test func `clearing oneof on a copied proto3 message preserves original scalar and enum values`() {
        var origInt = SwiftProtoTesting_Message3()
        origInt.oneofInt32 = 51
        var copyInt = origInt
        copyInt.o = nil

        #expect(copyInt.o == nil)
        #expect(copyInt.oneofInt32 == 0)
        #expect(origInt.o == .oneofInt32(51))
        #expect(origInt.oneofInt32 == 51)

        // Proto3 oneof members track explicit presence even for zero values.
        var origZero = SwiftProtoTesting_Message3()
        origZero.oneofInt32 = 0
        var copyZero = origZero
        copyZero.o = nil

        #expect(copyZero.o == nil)
        #expect(origZero.o == .oneofInt32(0))

        var origEnum = SwiftProtoTesting_Message3()
        origEnum.oneofEnum = .bar
        var copyEnum = origEnum
        copyEnum.o = nil

        #expect(copyEnum.o == nil)
        #expect(copyEnum.oneofEnum == .foo)
        #expect(origEnum.o == .oneofEnum(.bar))
        #expect(origEnum.oneofEnum == .bar)
    }

    @Test func `clearing oneof on a copied proto3 message preserves original string and bytes values`() {
        let longString = String(repeating: "proto3-oneof-string-", count: 8)
        var origString = SwiftProtoTesting_Message3()
        origString.oneofString = longString
        var copyString = origString
        copyString.o = nil

        #expect(copyString.o == nil)
        #expect(copyString.oneofString == "")
        #expect(origString.o == .oneofString(longString))
        #expect(origString.oneofString == longString)

        copyString.oneofInt32 = 777
        #expect(origString.o == .oneofString(longString))
        #expect(origString.oneofString == longString)

        let largeBytes = Data(repeating: 0xCD, count: 64)
        var origBytes = SwiftProtoTesting_Message3()
        origBytes.oneofBytes = largeBytes
        var copyBytes = origBytes
        copyBytes.o = nil

        #expect(copyBytes.o == nil)
        #expect(copyBytes.oneofBytes == Data())
        #expect(origBytes.o == .oneofBytes(largeBytes))
        #expect(origBytes.oneofBytes == largeBytes)

        copyBytes.oneofInt32 = 888
        #expect(origBytes.o == .oneofBytes(largeBytes))
        #expect(origBytes.oneofBytes == largeBytes)
    }

    @Test func `clearing oneof on a copied proto3 message preserves original message value`() {
        let nestedString = String(repeating: "proto3-nested-", count: 8)
        var subMsg = SwiftProtoTesting_Message3()
        subMsg.optionalInt32 = 77
        subMsg.optionalString = nestedString

        var orig = SwiftProtoTesting_Message3()
        orig.oneofMessage = subMsg
        var copy = orig
        copy.o = nil

        #expect(copy.o == nil)
        #expect(copy.oneofMessage.optionalInt32 == 0)
        #expect(copy.oneofMessage.optionalString == "")
        #expect(orig.o == .oneofMessage(subMsg))
        #expect(orig.oneofMessage.optionalInt32 == 77)
        #expect(orig.oneofMessage.optionalString == nestedString)
    }

    @Test func `clearing oneof on original proto3 message preserves snapshot copy`() {
        let nestedString = String(repeating: "proto3-snapshot-", count: 8)
        var subMsg = SwiftProtoTesting_Message3()
        subMsg.optionalInt32 = 88
        subMsg.optionalString = nestedString

        var orig = SwiftProtoTesting_Message3()
        orig.oneofMessage = subMsg
        let snapshot = orig
        orig.o = nil

        #expect(orig.o == nil)
        #expect(orig.oneofMessage.optionalInt32 == 0)
        #expect(snapshot.o == .oneofMessage(subMsg))
        #expect(snapshot.oneofMessage.optionalInt32 == 88)
        #expect(snapshot.oneofMessage.optionalString == nestedString)
    }

    // MARK: - Additional edge cases

    @Test func `clearing an already-nil oneof on a copied message keeps storage independent`() {
        let orig2 = SwiftProtoTesting_Message2()
        var copy2 = orig2
        copy2.o = nil
        copy2.oneofInt32 = 42
        #expect(orig2.o == nil)
        #expect(copy2.o == .oneofInt32(42))

        let orig3 = SwiftProtoTesting_Message3()
        var copy3 = orig3
        copy3.o = nil
        copy3.oneofInt32 = 42
        #expect(orig3.o == nil)
        #expect(copy3.o == .oneofInt32(42))
    }

    @Test func `clearing kind on a copied Google_Protobuf_Value preserves original value`() {
        let longString = String(repeating: "wkt-value-", count: 8)
        let origString = Google_Protobuf_Value(stringValue: longString)
        var copyString = origString
        copyString.kind = nil

        #expect(copyString.kind == nil)
        #expect(origString.kind == .stringValue(longString))

        let nestedStruct = Google_Protobuf_Struct(fields: ["key": Google_Protobuf_Value(stringValue: longString)])
        let origStruct = Google_Protobuf_Value(structValue: nestedStruct)
        var copyStruct = origStruct
        copyStruct.kind = nil

        #expect(copyStruct.kind == nil)
        #expect(origStruct.kind == .structValue(nestedStruct))
    }
}
