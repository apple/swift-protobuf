import SwiftProtobuf
import SwiftProtobufPluginLibrary
import Testing
import protoc_gen_swift

class DummyFieldGenerator: FieldGenerator {
    var number: Int
    var name: String
    var jsonName: String

    init(number: Int, name: String, jsonName: String) {
        self.number = number
        self.name = name
        self.jsonName = jsonName
    }

    var isRequired: Bool { false }
    var hasPresence: Bool { false }
    var rawFieldType: RawFieldType { .bool }
    var submessageOrEnumReference: SubmessageOrEnumReference? { nil }
    var fieldMode: FieldMode { .init(rawValue: 0) }
    var stableStride: Int { 0 }
    var oneofIndex: Int? { nil }
    var presence: FieldPresence = .hasBit(0)
    var storageOffsetOrIndex: Int = 0
    var needsIsInitializedGeneration: Bool { false }
    func generateInterface(printer: inout CodePrinter) {}
}

@Test func messageFields() throws {
    let field1 = DummyFieldGenerator(number: 1, name: "key", jsonName: "key")
    let field2 = DummyFieldGenerator(number: 2, name: "value", jsonName: "value")
    let field3 = DummyFieldGenerator(number: 3, name: "foo", jsonName: "bar")  // Distinct JSON name

    let fields = [field1, field2, field3]
    let calculator = ReflectionTableCalculator(fields: fields, reservedRanges: [], reservedNames: [])
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: fields.count, data: result)

    #expect(table.textName(forFieldNumber: 1)?.utf8CodeUnitsEqual("key") == true)
    #expect(table.jsonName(forFieldNumber: 1)?.utf8CodeUnitsEqual("key") == true)

    #expect(table.textName(forFieldNumber: 2)?.utf8CodeUnitsEqual("value") == true)
    #expect(table.jsonName(forFieldNumber: 2)?.utf8CodeUnitsEqual("value") == true)

    #expect(table.textName(forFieldNumber: 3)?.utf8CodeUnitsEqual("foo") == true)
    #expect(table.jsonName(forFieldNumber: 3)?.utf8CodeUnitsEqual("bar") == true)

    #expect(table.fieldNumber(forTextName: "key") == 1)
    #expect(table.fieldNumber(forJSONName: "key") == 1)

    #expect(table.fieldNumber(forTextName: "value") == 2)
    #expect(table.fieldNumber(forJSONName: "value") == 2)

    #expect(table.fieldNumber(forTextName: "foo") == 3)
    #expect(table.fieldNumber(forJSONName: "bar") == 3)
    #expect(table.fieldNumber(forJSONName: "foo") == 3)  // Fallback to text name

    #expect(table.textName(forFieldNumber: 4) == nil)
    #expect(table.fieldNumber(forTextName: "nonexistent") == nil)
}

@Test func enumCases() throws {
    let case1 = DummyFieldGenerator(number: 1, name: "FOO", jsonName: "FOO")
    let case2 = DummyFieldGenerator(number: 0xFFFF_FFFF, name: "BAR", jsonName: "BAR")  // -1 as Int32
    let case3 = DummyFieldGenerator(number: 100, name: "BAZ", jsonName: "BAZ")
    let case4 = DummyFieldGenerator(number: 0xFFFF_FF9C, name: "QUX", jsonName: "QUX")  // -100 as Int32

    let cases = [case1, case2, case3, case4]
    let calculator = ReflectionTableCalculator(fields: cases, reservedRanges: [], reservedNames: [])
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: cases.count, data: result)

    #expect(table.textName(forEnumCase: 1)?.utf8CodeUnitsEqual("FOO") == true)
    #expect(table.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("FOO") == true)

    #expect(table.textName(forEnumCase: -1)?.utf8CodeUnitsEqual("BAR") == true)
    #expect(table.jsonName(forEnumCase: -1)?.utf8CodeUnitsEqual("BAR") == true)

    #expect(table.textName(forEnumCase: 100)?.utf8CodeUnitsEqual("BAZ") == true)
    #expect(table.jsonName(forEnumCase: 100)?.utf8CodeUnitsEqual("BAZ") == true)

    #expect(table.textName(forEnumCase: -100)?.utf8CodeUnitsEqual("QUX") == true)
    #expect(table.jsonName(forEnumCase: -100)?.utf8CodeUnitsEqual("QUX") == true)

    #expect(table.enumCase(forTextName: "FOO") == 1)
    #expect(table.enumCase(forJSONName: "FOO") == 1)

    #expect(table.enumCase(forTextName: "BAR") == -1)
    #expect(table.enumCase(forJSONName: "BAR") == -1)

    #expect(table.enumCase(forTextName: "BAZ") == 100)
    #expect(table.enumCase(forJSONName: "BAZ") == 100)

    #expect(table.enumCase(forTextName: "QUX") == -100)
    #expect(table.enumCase(forJSONName: "QUX") == -100)
}

@Test func mapEntry() throws {
    let table = ReflectionTable.mapEntry

    // We don't care about the JSON names since they never get used.
    #expect(table.textName(forFieldNumber: 1)?.utf8CodeUnitsEqual("key") == true)
    #expect(table.textName(forFieldNumber: 2)?.utf8CodeUnitsEqual("value") == true)
    #expect(table.fieldNumber(forTextName: "key") == 1)
    #expect(table.fieldNumber(forTextName: "value") == 2)
}

@Test func reservedFields() throws {
    let field1 = DummyFieldGenerator(number: 1, name: "key", jsonName: "key")
    let fields = [field1]

    let calculator = ReflectionTableCalculator(
        fields: fields,
        reservedRanges: [10..<11, 20..<25],
        reservedNames: ["reserved1", "reserved2"]
    )
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: fields.count, data: result)

    // Verify reserved names.
    #expect(table.isNameReserved("reserved1") == true)
    #expect(table.isNameReserved("reserved2") == true)
    #expect(table.isNameReserved("key") == false)

    // Verify reserved names return nil from regular lookup.
    #expect(table.fieldNumber(forTextName: "reserved1") == nil)
    #expect(table.fieldNumber(forTextName: "reserved2") == nil)
    #expect(table.fieldNumber(forTextName: "key") == 1)

    // Verify reserved numbers.
    #expect(table.isNumberReserved(1) == false)
    #expect(table.isNumberReserved(10) == true)
    #expect(table.isNumberReserved(11) == false)
    #expect(table.isNumberReserved(20) == true)
    #expect(table.isNumberReserved(24) == true)
    #expect(table.isNumberReserved(25) == false)
}

@Test func reservedFieldsEmpty() throws {
    let field1 = DummyFieldGenerator(number: 1, name: "key", jsonName: "key")
    let fields = [field1]

    let calculator = ReflectionTableCalculator(
        fields: fields,
        reservedRanges: [],
        reservedNames: []
    )
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: fields.count, data: result)

    // Verify reserved names return false.
    #expect(table.isNameReserved("reserved1") == false)
    #expect(table.isNameReserved("key") == false)

    // Verify reserved numbers return false.
    #expect(table.isNumberReserved(10) == false)
    #expect(table.isNumberReserved(1) == false)
}

@Test func suppressedNames() throws {
    let field1 = DummyFieldGenerator(number: 1, name: "key", jsonName: "key")
    let field2 = DummyFieldGenerator(number: 2, name: "value", jsonName: "value")
    let field3 = DummyFieldGenerator(number: 3, name: "foo", jsonName: "bar")  // Distinct JSON name
    let fields = [field1, field2, field3]

    let calculator = ReflectionTableCalculator(
        fields: fields,
        reservedRanges: [10..<11],
        reservedNames: ["reserved1"],
        suppressNames: true
    )
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: fields.count, data: result)

    // Verify field names return nil when suppressed.
    #expect(table.textName(forFieldNumber: 1) == nil)
    #expect(table.jsonName(forFieldNumber: 1) == nil)
    #expect(table.textName(forFieldNumber: 2) == nil)
    #expect(table.jsonName(forFieldNumber: 2) == nil)
    #expect(table.textName(forFieldNumber: 3) == nil)
    #expect(table.jsonName(forFieldNumber: 3) == nil)

    // Verify lookup by name returns nil.
    #expect(table.fieldNumber(forTextName: "key") == nil)
    #expect(table.fieldNumber(forJSONName: "key") == nil)
    #expect(table.fieldNumber(forTextName: "value") == nil)
    #expect(table.fieldNumber(forJSONName: "value") == nil)
    #expect(table.fieldNumber(forTextName: "foo") == nil)
    #expect(table.fieldNumber(forJSONName: "bar") == nil)

    // Verify reserved names are not recognized (since they are suppressed/omitted).
    #expect(table.isNameReserved("reserved1") == false)

    // Verify reserved numbers still work.
    #expect(table.isNumberReserved(10) == true)
    #expect(table.isNumberReserved(1) == false)
}

private enum CustomEnumJSONOption {
    case omitted
    case emptyMessage
    case string(String)
}

private func makeEnumReflectionTable(
    allowAlias: Bool = false,
    values: [(name: String, number: Int32, jsonOption: CustomEnumJSONOption)]
) throws -> (table: ReflectionTable, distinctJSONNameCount: UInt16) {
    var enumProto = Google_Protobuf_EnumDescriptorProto()
    enumProto.name = "TestEnum"
    if allowAlias {
        enumProto.options.allowAlias = true
    }
    enumProto.value = values.map { entry in
        var valueProto = Google_Protobuf_EnumValueDescriptorProto()
        valueProto.name = entry.name
        valueProto.number = entry.number
        switch entry.jsonOption {
        case .omitted:
            break
        case .emptyMessage:
            valueProto.options.Pb_Enumvalue_json = Pb_Enumvalue_JsonEnumValueOptions()
        case .string(let value):
            valueProto.options.Pb_Enumvalue_json.string = value
        }
        return valueProto
    }
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "test.proto"
    fileProto.syntax = "editions"
    fileProto.edition = .edition2026
    fileProto.enumType = [enumProto]

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let enumDescriptor = try #require(descriptorSet.enumDescriptor(named: "TestEnum"))
    let aliasInfo = EnumDescriptor.ValueAliasInfo(enumDescriptor: enumDescriptor)
    let mainValues = aliasInfo.mainValues.sorted(by: { $0.number < $1.number })
    let calculator = ReflectionTableCalculator(enumValues: mainValues, aliasInfo: aliasInfo)
    let data = calculator.uncompressedData()
    let distinctJSONNameCount = UInt16(data[4]) | (UInt16(data[5]) << 8)
    let table = ReflectionTable(fieldCount: mainValues.count, data: data)
    return (table, distinctJSONNameCount)
}

@Test func enumCustomJSONEmptyOptionOnly() throws {
    let (table, distinctJSONNameCount) = try makeEnumReflectionTable(values: [
        ("ONLY_UNSPECIFIED", 0, .emptyMessage),
        ("ONLY_FOO", 1, .emptyMessage),
    ])

    #expect(distinctJSONNameCount == 0)
    #expect(table.textName(forEnumCase: 0)?.utf8CodeUnitsEqual("ONLY_UNSPECIFIED") == true)
    #expect(table.jsonName(forEnumCase: 0)?.utf8CodeUnitsEqual("ONLY_UNSPECIFIED") == true)
    #expect(table.textName(forEnumCase: 1)?.utf8CodeUnitsEqual("ONLY_FOO") == true)
    #expect(table.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("ONLY_FOO") == true)
    #expect(table.enumCase(forJSONName: "ONLY_UNSPECIFIED") == 0)
    #expect(table.enumCase(forJSONName: "ONLY_FOO") == 1)
    #expect(table.enumCase(forJSONName: "") == nil)
}

@Test func enumCustomJSONEmptyOptionBeforeAndAfterEmptyString() throws {
    let (beforeTable, beforeCount) = try makeEnumReflectionTable(values: [
        ("UNSPECIFIED", 0, .omitted),
        ("EMPTY_OPTION_FIRST", 1, .emptyMessage),
        ("EMPTY_STRING_SECOND", 2, .string("")),
    ])

    #expect(beforeCount == 1)
    #expect(beforeTable.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("EMPTY_OPTION_FIRST") == true)
    #expect(beforeTable.jsonName(forEnumCase: 2)?.utf8CodeUnitsEqual("") == true)
    #expect(beforeTable.enumCase(forJSONName: "EMPTY_OPTION_FIRST") == 1)
    #expect(beforeTable.enumCase(forJSONName: "EMPTY_STRING_SECOND") == 2)
    #expect(beforeTable.enumCase(forJSONName: "") == 2)

    let (afterTable, afterCount) = try makeEnumReflectionTable(values: [
        ("UNSPECIFIED", 0, .omitted),
        ("EMPTY_STRING_FIRST", 1, .string("")),
        ("EMPTY_OPTION_SECOND", 2, .emptyMessage),
    ])

    #expect(afterCount == 1)
    #expect(afterTable.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("") == true)
    #expect(afterTable.jsonName(forEnumCase: 2)?.utf8CodeUnitsEqual("EMPTY_OPTION_SECOND") == true)
    #expect(afterTable.enumCase(forJSONName: "EMPTY_STRING_FIRST") == 1)
    #expect(afterTable.enumCase(forJSONName: "EMPTY_OPTION_SECOND") == 2)
    #expect(afterTable.enumCase(forJSONName: "") == 1)
}

@Test func enumCustomJSONAliasedEmptyAndOmitted() throws {
    let (table, distinctJSONNameCount) = try makeEnumReflectionTable(
        allowAlias: true,
        values: [
            ("UNSPECIFIED", 0, .omitted),
            ("EMPTY_FIRST", 1, .emptyMessage),
            ("OMITTED_SECOND", 1, .omitted),
            ("OMITTED_FIRST", 2, .omitted),
            ("EMPTY_SECOND", 2, .emptyMessage),
        ]
    )

    #expect(distinctJSONNameCount == 0)
    #expect(table.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("EMPTY_FIRST") == true)
    #expect(table.jsonName(forEnumCase: 2)?.utf8CodeUnitsEqual("OMITTED_FIRST") == true)
    #expect(table.enumCase(forJSONName: "EMPTY_FIRST") == 1)
    #expect(table.enumCase(forJSONName: "OMITTED_SECOND") == 1)
    #expect(table.enumCase(forJSONName: "OMITTED_FIRST") == 2)
    #expect(table.enumCase(forJSONName: "EMPTY_SECOND") == 2)
    #expect(table.enumCase(forTextName: "OMITTED_SECOND") == 1)
    #expect(table.enumCase(forTextName: "EMPTY_SECOND") == 2)
    #expect(table.enumCase(forJSONName: "") == nil)
}

@Test func enumCustomJSONDeduplicatesSameAsPrimaryName() throws {
    let (table, distinctJSONNameCount) = try makeEnumReflectionTable(
        allowAlias: true,
        values: [
            ("UNSPECIFIED", 0, .omitted),
            ("SAME_AS_NAME", 1, .string("SAME_AS_NAME")),
            ("PRIMARY_NAME", 2, .string("ALIAS_NAME")),
            ("ALIAS_NAME", 2, .string("ALIAS_NAME")),
            // U+212A KELVIN SIGN is NFC-canonically equivalent to ASCII "K" in
            // Swift `String.==`, but has different UTF-8 bytes and must NOT be
            // deduplicated.
            ("K", 3, .string("\u{212A}")),
        ]
    )

    // Case 1 deduplicates because `.string` has identical UTF-8 bytes to
    // `primaryName`, while Case 2 retains its distinct JSON name (matching the
    // alias, not the primary name) and Case 3 retains its non-ASCII UTF-8 name.
    #expect(distinctJSONNameCount == 2)
    #expect(table.textName(forEnumCase: 1)?.utf8CodeUnitsEqual("SAME_AS_NAME") == true)
    #expect(table.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("SAME_AS_NAME") == true)
    #expect(table.enumCase(forJSONName: "SAME_AS_NAME") == 1)

    #expect(table.textName(forEnumCase: 2)?.utf8CodeUnitsEqual("PRIMARY_NAME") == true)
    #expect(table.jsonName(forEnumCase: 2)?.utf8CodeUnitsEqual("ALIAS_NAME") == true)
    #expect(table.enumCase(forJSONName: "ALIAS_NAME") == 2)
    #expect(table.enumCase(forJSONName: "PRIMARY_NAME") == 2)
    #expect(table.enumCase(forTextName: "PRIMARY_NAME") == 2)
    #expect(table.enumCase(forTextName: "ALIAS_NAME") == 2)

    #expect(table.textName(forEnumCase: 3)?.utf8CodeUnitsEqual("K") == true)
    #expect(table.jsonName(forEnumCase: 3)?.utf8CodeUnitsEqual("\u{212A}") == true)
    #expect(table.enumCase(forJSONName: "\u{212A}") == 3)
    #expect(table.enumCase(forJSONName: "K") == 3)
    #expect(table.enumCase(forTextName: "K") == 3)
    #expect(table.enumCase(forTextName: "\u{212A}") == nil)
}

@Test func enumCustomJSONNonNFCAndUTF8ByteOrdering() throws {
    // Non-NFC custom JSON names (e.g. U+212A KELVIN SIGN, NFD "e\u{0301}") have
    // different raw UTF-8 byte order than Swift's Unicode-NFC `String.<`.
    // Verify that `jsonOffsetToNumber` is sorted in raw UTF-8 byte order so
    // `ReflectionTable`'s UTF-8 binary search finds every entry reliably even
    // when exact-byte matches like `Z = "Z"` are deduplicated.
    let (table, distinctJSONNameCount) = try makeEnumReflectionTable(values: [
        ("UNSPECIFIED", 0, .omitted),
        ("K", 1, .string("\u{212A}")),
        ("M", 2, .string("m")),
        ("Z", 3, .string("Z")),
        ("E_NFC", 4, .string("\u{00E9}")),
        ("E_NFD", 5, .string("e\u{0301}")),
        ("F", 6, .string("f")),
    ])

    #expect(distinctJSONNameCount == 5)
    #expect(table.jsonName(forEnumCase: 1)?.utf8CodeUnitsEqual("\u{212A}") == true)
    #expect(table.jsonName(forEnumCase: 2)?.utf8CodeUnitsEqual("m") == true)
    #expect(table.jsonName(forEnumCase: 3)?.utf8CodeUnitsEqual("Z") == true)
    #expect(table.jsonName(forEnumCase: 4)?.utf8CodeUnitsEqual("\u{00E9}") == true)
    #expect(table.jsonName(forEnumCase: 5)?.utf8CodeUnitsEqual("e\u{0301}") == true)
    #expect(table.jsonName(forEnumCase: 6)?.utf8CodeUnitsEqual("f") == true)

    #expect(table.enumCase(forJSONName: "\u{212A}") == 1)
    #expect(table.enumCase(forJSONName: "K") == 1)
    #expect(table.enumCase(forJSONName: "m") == 2)
    #expect(table.enumCase(forJSONName: "M") == 2)
    #expect(table.enumCase(forJSONName: "Z") == 3)
    #expect(table.enumCase(forJSONName: "\u{00E9}") == 4)
    #expect(table.enumCase(forJSONName: "e\u{0301}") == 5)
    #expect(table.enumCase(forJSONName: "f") == 6)
    #expect(table.enumCase(forTextName: "\u{212A}") == nil)
    #expect(table.enumCase(forTextName: "\u{00E9}") == nil)
    #expect(table.enumCase(forTextName: "e\u{0301}") == nil)
}
