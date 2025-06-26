// Tests/SwiftProtobufTests/Test_NameMap_PublicAPI.swift - Test the public NameMap API
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

/// Tests for the public API added to _NameMap to allow external inspection
/// of name mapping metadata.
final class Test_NameMap_PublicAPI: XCTestCase {

    func testFieldInfoStructure() {
        // Test FieldInfo with same proto/JSON name
        let info1 = _NameMap.FieldInfo(number: 1, protoName: "field_one", jsonName: nil)
        XCTAssertEqual(info1.number, 1)
        XCTAssertEqual(info1.protoName, "field_one")
        XCTAssertNil(info1.jsonName)
        XCTAssertEqual(info1.effectiveJSONName, "field_one")
        XCTAssertFalse(info1.hasCustomJSONName)
        
        // Test FieldInfo with different JSON name
        let info2 = _NameMap.FieldInfo(number: 2, protoName: "field_two", jsonName: "fieldTwo")
        XCTAssertEqual(info2.number, 2)
        XCTAssertEqual(info2.protoName, "field_two")
        XCTAssertEqual(info2.jsonName, "fieldTwo")
        XCTAssertEqual(info2.effectiveJSONName, "fieldTwo")
        XCTAssertTrue(info2.hasCustomJSONName)
    }
    
    func testNameMapWithSameNaming() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .same(proto: "field_one")),
            (2, .same(proto: "field_two"))
        )
        
        // Test field info retrieval
        let info1 = nameMap.fieldInfo(for: 1)
        XCTAssertNotNil(info1)
        XCTAssertEqual(info1?.number, 1)
        XCTAssertEqual(info1?.protoName, "field_one")
        XCTAssertNil(info1?.jsonName)
        XCTAssertEqual(info1?.effectiveJSONName, "field_one")
        XCTAssertFalse(info1?.hasCustomJSONName ?? true)
        
        // Test field lookup by proto name
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_one"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_two"), 2)
        XCTAssertNil(nameMap.fieldNumber(forProtoName: "nonexistent"))
        
        // Test field lookup by JSON name (should work since proto name is accepted)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "field_one"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "field_two"), 2)
        XCTAssertNil(nameMap.fieldNumber(forJSONName: "nonexistent"))
        
        // Test enumeration
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 2])
        XCTAssertEqual(nameMap.allFields.count, 2)
        XCTAssertEqual(nameMap.allFields.map(\.number).sorted(), [1, 2])
    }
    
    func testNameMapWithStandardNaming() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .standard(proto: "field_one")),
            (2, .standard(proto: "field_two_test")),
            (3, .standard(proto: "another_field"))
        )
        
        // Test field info retrieval for standard naming (camelCase JSON)
        let info1 = nameMap.fieldInfo(for: 1)
        XCTAssertNotNil(info1)
        XCTAssertEqual(info1?.number, 1)
        XCTAssertEqual(info1?.protoName, "field_one")
        XCTAssertEqual(info1?.jsonName, "fieldOne")
        XCTAssertEqual(info1?.effectiveJSONName, "fieldOne")
        XCTAssertTrue(info1?.hasCustomJSONName ?? false)
        
        let info2 = nameMap.fieldInfo(for: 2)
        XCTAssertEqual(info2?.protoName, "field_two_test")
        XCTAssertEqual(info2?.jsonName, "fieldTwoTest")
        
        // Test lookups
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_one"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "fieldOne"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "field_one"), 1) // Proto name should also work
        
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_two_test"), 2)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "fieldTwoTest"), 2)
        
        // Test enumeration
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 2, 3])
    }
    
    func testNameMapWithUniqueNaming() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .unique(proto: "field_one", json: "customFieldOne")),
            (2, .unique(proto: "field_two", json: "anotherName"))
        )
        
        // Test field info retrieval for unique naming
        let info1 = nameMap.fieldInfo(for: 1)
        XCTAssertNotNil(info1)
        XCTAssertEqual(info1?.number, 1)
        XCTAssertEqual(info1?.protoName, "field_one")
        XCTAssertEqual(info1?.jsonName, "customFieldOne")
        XCTAssertEqual(info1?.effectiveJSONName, "customFieldOne")
        XCTAssertTrue(info1?.hasCustomJSONName ?? false)
        
        // Test lookups
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_one"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "customFieldOne"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "field_one"), 1) // Proto name should also work
        
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_two"), 2)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "anotherName"), 2)
    }
    
    func testNameMapWithAliasedNaming() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .aliased(proto: "ENUM_VALUE", aliases: ["ENUM_ALIAS", "ANOTHER_ALIAS"]))
        )
        
        // Test field info retrieval for aliased naming (enums)
        let info1 = nameMap.fieldInfo(for: 1)
        XCTAssertNotNil(info1)
        XCTAssertEqual(info1?.number, 1)
        XCTAssertEqual(info1?.protoName, "ENUM_VALUE")
        XCTAssertNil(info1?.jsonName) // Enums don't have separate JSON names
        XCTAssertEqual(info1?.effectiveJSONName, "ENUM_VALUE")
        XCTAssertFalse(info1?.hasCustomJSONName ?? true)
        
        // Test lookups - all aliases should work
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "ENUM_VALUE"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "ENUM_ALIAS"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "ANOTHER_ALIAS"), 1)
        
        // JSON lookups should also work (proto names accepted in JSON)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "ENUM_VALUE"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "ENUM_ALIAS"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "ANOTHER_ALIAS"), 1)
    }
    
    func testMixedNamingTypes() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .same(proto: "same_field")),
            (2, .standard(proto: "standard_field")),
            (3, .unique(proto: "unique_field", json: "customName")),
            (4, .aliased(proto: "ENUM_VALUE", aliases: ["ALIAS"]))
        )
        
        // Test that all fields are present
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 2, 3, 4])
        XCTAssertEqual(nameMap.allFields.count, 4)
        
        // Test each field type
        let allFields = nameMap.allFields
        let fieldsByNumber = Dictionary(uniqueKeysWithValues: allFields.map { ($0.number, $0) })
        
        XCTAssertEqual(fieldsByNumber[1]?.protoName, "same_field")
        XCTAssertNil(fieldsByNumber[1]?.jsonName)
        
        XCTAssertEqual(fieldsByNumber[2]?.protoName, "standard_field")
        XCTAssertEqual(fieldsByNumber[2]?.jsonName, "standardField")
        
        XCTAssertEqual(fieldsByNumber[3]?.protoName, "unique_field")
        XCTAssertEqual(fieldsByNumber[3]?.jsonName, "customName")
        
        XCTAssertEqual(fieldsByNumber[4]?.protoName, "ENUM_VALUE")
        XCTAssertNil(fieldsByNumber[4]?.jsonName)
    }
    
    func testReservedNamesAndNumbers() {
        let nameMap = _NameMap(
            reservedNames: ["reserved_name", "another_reserved"],
            reservedRanges: [2..<5, 10..<15],
            numberNameMappings: [
                1: .same(proto: "field_one"),
                6: .same(proto: "field_six")
            ]
        )
        
        // Test reserved name checking
        XCTAssertTrue(nameMap.isReservedName("reserved_name"))
        XCTAssertTrue(nameMap.isReservedName("another_reserved"))
        XCTAssertFalse(nameMap.isReservedName("field_one"))
        XCTAssertFalse(nameMap.isReservedName("nonexistent"))
        
        // Test reserved number checking (Int32)
        XCTAssertTrue(nameMap.isReservedNumber(Int32(2)))
        XCTAssertTrue(nameMap.isReservedNumber(Int32(4)))
        XCTAssertTrue(nameMap.isReservedNumber(Int32(10)))
        XCTAssertTrue(nameMap.isReservedNumber(Int32(14)))
        XCTAssertFalse(nameMap.isReservedNumber(Int32(1)))
        XCTAssertFalse(nameMap.isReservedNumber(Int32(5)))
        XCTAssertFalse(nameMap.isReservedNumber(Int32(6)))
        XCTAssertFalse(nameMap.isReservedNumber(Int32(15)))
        
        // Test reserved number checking (Int convenience method)
        XCTAssertTrue(nameMap.isReservedNumber(3))
        XCTAssertTrue(nameMap.isReservedNumber(12))
        XCTAssertFalse(nameMap.isReservedNumber(1))
        XCTAssertFalse(nameMap.isReservedNumber(6))
        
        // Test that regular fields still work
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 6])
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "field_one"), 1)
    }
    
    func testEmptyNameMap() {
        let nameMap = _NameMap()
        
        XCTAssertNil(nameMap.fieldInfo(for: 1))
        XCTAssertNil(nameMap.fieldNumber(forProtoName: "any_name"))
        XCTAssertNil(nameMap.fieldNumber(forJSONName: "any_name"))
        XCTAssertTrue(nameMap.fieldNumbers.isEmpty)
        XCTAssertTrue(nameMap.allFields.isEmpty)
        XCTAssertFalse(nameMap.isReservedName("any_name"))
        XCTAssertFalse(nameMap.isReservedNumber(1))
    }
    
    func testUnicodeNames() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .same(proto: "café_field")),
            (2, .standard(proto: "测试_field")),
            (3, .unique(proto: "مرحبا", json: "hello"))
        )
        
        // Test Unicode handling
        let info1 = nameMap.fieldInfo(for: 1)
        XCTAssertEqual(info1?.protoName, "café_field")
        
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "café_field"), 1)
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "测试_field"), 2)
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "مرحبا"), 3)
        XCTAssertEqual(nameMap.fieldNumber(forJSONName: "hello"), 3)
        
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 2, 3])
    }

    func testLargeNumbers() {
        let nameMap = _NameMap(dictionaryLiteral:
            (1, .same(proto: "small_field")),
            (536870911, .same(proto: "max_field")) // Maximum field number in protobuf
        )
        
        XCTAssertEqual(nameMap.fieldNumbers.sorted(), [1, 536870911])
        XCTAssertNotNil(nameMap.fieldInfo(for: 536870911))
        XCTAssertEqual(nameMap.fieldNumber(forProtoName: "max_field"), 536870911)
    }
}
