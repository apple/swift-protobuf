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
    var trampolineFieldKind: TrampolineFieldKind? { nil }
    var fieldMode: FieldMode { .init(rawValue: 0) }
    var storageKind: FieldStorageKind { .oneByteScalar }
    var oneofIndex: Int? { nil }
    var presence: FieldPresence = .hasBit(0)
    var storageOffsets: TargetSpecificValues<Int> = .init(forAllTargets: 0)
    var needsIsInitializedGeneration: Bool { false }
    func generateInterface(printer: inout CodePrinter) {}
}

@Test func messageFields() throws {
    let field1 = DummyFieldGenerator(number: 1, name: "key", jsonName: "key")
    let field2 = DummyFieldGenerator(number: 2, name: "value", jsonName: "value")
    let field3 = DummyFieldGenerator(number: 3, name: "foo", jsonName: "bar") // Distinct JSON name
    
    let fields = [field1, field2, field3]
    let calculator = ReflectionTableCalculator(fields: fields, reservedRanges: [], reservedNames: [])
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: fields.count, data: result)
    
    #expect(table.textName(forFieldNumber: 1) == "key")
    #expect(table.jsonName(forFieldNumber: 1) == "key")
    
    #expect(table.textName(forFieldNumber: 2) == "value")
    #expect(table.jsonName(forFieldNumber: 2) == "value")
    
    #expect(table.textName(forFieldNumber: 3) == "foo")
    #expect(table.jsonName(forFieldNumber: 3) == "bar")
    
    #expect(table.fieldNumber(forTextName: "key") == 1)
    #expect(table.fieldNumber(forJSONName: "key") == 1)
    
    #expect(table.fieldNumber(forTextName: "value") == 2)
    #expect(table.fieldNumber(forJSONName: "value") == 2)
    
    #expect(table.fieldNumber(forTextName: "foo") == 3)
    #expect(table.fieldNumber(forJSONName: "bar") == 3)
    #expect(table.fieldNumber(forJSONName: "foo") == 3) // Fallback to text name
    
    #expect(table.textName(forFieldNumber: 4) == nil)
    #expect(table.fieldNumber(forTextName: "nonexistent") == nil)
}

@Test func enumCases() throws {
    let case1 = DummyFieldGenerator(number: 1, name: "FOO", jsonName: "FOO")
    let case2 = DummyFieldGenerator(number: 0xFFFF_FFFF, name: "BAR", jsonName: "BAR") // -1 as Int32
    let case3 = DummyFieldGenerator(number: 100, name: "BAZ", jsonName: "BAZ")
    let case4 = DummyFieldGenerator(number: 0xFFFF_FF9C, name: "QUX", jsonName: "QUX") // -100 as Int32
    
    let cases = [case1, case2, case3, case4]
    let calculator = ReflectionTableCalculator(fields: cases, reservedRanges: [], reservedNames: [])
    let result = calculator.uncompressedData()
    let table = ReflectionTable(fieldCount: cases.count, data: result)
    
    #expect(table.textName(forEnumCase: 1) == "FOO")
    #expect(table.jsonName(forEnumCase: 1) == "FOO")
    
    #expect(table.textName(forEnumCase: -1) == "BAR")
    #expect(table.jsonName(forEnumCase: -1) == "BAR")
    
    #expect(table.textName(forEnumCase: 100) == "BAZ")
    #expect(table.jsonName(forEnumCase: 100) == "BAZ")
    
    #expect(table.textName(forEnumCase: -100) == "QUX")
    #expect(table.jsonName(forEnumCase: -100) == "QUX")
    
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
    #expect(table.textName(forFieldNumber: 1) == "key")
    #expect(table.textName(forFieldNumber: 2) == "value")
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

