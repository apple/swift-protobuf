import ModuleA
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Tests JSON encoding and decoding with weak-linked Swift protos, verifying
/// that schema and reflection data in `.pbschema.o` is retained via
/// `live_support` while unreferenced nominal types and witnesses in `.pb.o`
/// (ModuleB) remain stripped.
@main
struct Main {
    static func main() {
        do {
            // HAS-SYMBOL: full type metadata for ModuleA.Test_MessageA
            // HAS-SYMBOL: {{_?}}test_DMessageA_getMessageSchema
            // HAS-SYMBOL [MachO only]: {{_?}}test_DMessageA_getReflection
            // HAS-SYMBOL: full type metadata for ModuleC.Test_MessageC
            // HAS-SYMBOL: {{_?}}test_DMessageC_getMessageSchema
            // HAS-SYMBOL [MachO only]: {{_?}}test_DMessageC_getReflection
            // HAS-SYMBOL: full type metadata for ModuleC.Test_EnumC
            // HAS-SYMBOL: {{_?}}test_DEnumC_getEnumSchema
            // HAS-SYMBOL [MachO only]: {{_?}}test_DEnumC_getReflection
            // HAS-SYMBOL [MachO only]: {{_?}}test_DMessageB_getMessageSchema
            // HAS-SYMBOL [MachO only]: {{_?}}test_DMessageB_getReflection
            // HAS-SYMBOL [MachO only]: {{_?}}test_DEnumB_getEnumSchema
            // HAS-SYMBOL [MachO only]: {{_?}}test_DEnumB_getReflection
            var msg = Test_MessageA()
            msg.title = "Hello JSON"
            msg.nestedC.id = 12345
            msg.nestedC.detail = "nested detail"
            msg.nestedEnumC = .first
            msg.mapC["alpha"] = .with {
                $0.id = 42
                $0.detail = "map value"
            }
            msg.repeatedC = [
                .with {
                    $0.id = 1
                    $0.detail = "one"
                },
                .with {
                    $0.id = 2
                    $0.detail = "two"
                },
            ]
            msg.repeatedEnumC = [.unspecified, .first]
            msg.oneofMessageC = .with {
                $0.id = 99
                $0.detail = "oneof"
            }

            let json = try! msg.jsonString()
            expect(json.contains("\"title\":\"Hello JSON\""))
            expect(json.contains("\"nestedC\":{"))
            expect(json.contains("\"nestedEnumC\":\"ENUM_C_FIRST\""))
            expect(json.contains("\"mapC\":{\"alpha\":{"))
            expect(json.contains("\"repeatedC\":["))
            expect(json.contains("\"repeatedEnumC\":[\"ENUM_C_UNSPECIFIED\",\"ENUM_C_FIRST\"]"))
            expect(json.contains("\"oneofMessageC\":{"))

            let decoded = try! Test_MessageA(jsonString: json)
            expect(decoded == msg)
            expect(decoded.title == "Hello JSON")
            expect(decoded.nestedC.id == 12345)
            expect(decoded.nestedC.detail == "nested detail")
            expect(decoded.nestedEnumC == .first)
            expect(decoded.mapC["alpha"]?.id == 42)
            expect(decoded.mapC["alpha"]?.detail == "map value")
            expect(decoded.repeatedC.count == 2)
            expect(decoded.repeatedEnumC == [.unspecified, .first])
            expect(decoded.oneofMessageC.id == 99)
        }

        #if canImport(Darwin)
        do {
            // Verify full JSON <-> Binary round-tripping of all field kinds whose
            // types come from ModuleB (`b.pbschema.o` is retained via `live_support`
            // while `b.pb.o` is never linked).
            let jsonWithModuleB = """
                {
                  "title": "With Unlinked B",
                  "nestedB": {"id": 100, "detail": "kept"},
                  "nestedEnum": "ENUM_B_FIRST",
                  "mapB": {"k": {"id": 42, "detail": "map b"}},
                  "repeatedB": [{"id": 1, "detail": "r1"}],
                  "repeatedEnumB": ["ENUM_B_UNSPECIFIED", "ENUM_B_FIRST"],
                  "oneofMessageB": {"id": 7, "detail": "oneof b"},
                  "nestedC": {"id": 55, "detail": "kept c"}
                }
                """
            let fromJSON = try! Test_MessageA(jsonString: jsonWithModuleB)
            expect(fromJSON.title == "With Unlinked B")
            expect(fromJSON.hasNestedB)
            expect(fromJSON.hasNestedEnum)
            expect(fromJSON.hasNestedC)
            expect(fromJSON.nestedC.id == 55)
            expect(fromJSON.nestedC.detail == "kept c")

            let bytes = try! fromJSON.serializedData()
            let fromBytes = try! Test_MessageA(serializedBytes: bytes)
            expect(fromBytes == fromJSON)

            let roundTrippedJSON = try! fromBytes.jsonString()
            expect(roundTrippedJSON.contains("\"nestedB\":{\"id\":100,\"detail\":\"kept\"}"))
            expect(roundTrippedJSON.contains("\"nestedEnum\":\"ENUM_B_FIRST\""))
            expect(roundTrippedJSON.contains("\"mapB\":{\"k\":{\"id\":42,\"detail\":\"map b\"}}"))
            expect(roundTrippedJSON.contains("\"repeatedB\":[{\"id\":1,\"detail\":\"r1\"}]"))
            expect(roundTrippedJSON.contains("\"repeatedEnumB\":[\"ENUM_B_UNSPECIFIED\",\"ENUM_B_FIRST\"]"))
            expect(roundTrippedJSON.contains("\"oneofMessageB\":{\"id\":7,\"detail\":\"oneof b\"}"))

            // Verify that closed enum validation for `EnumB` works via `EnumSchema`
            // even though `b.pb.o` (and `EnumB`'s witness table) is dead-stripped.
            let validFromJSON = try? Test_MessageA(jsonString: "{\"nestedEnum\": 1}")
            expect(validFromJSON?.hasNestedEnum == true)
            expect((try? Test_MessageA(jsonString: "{\"nestedEnum\": 99}")) == nil)
        }
        #endif

        // Nominal type metadata, property accessors, and concrete witnesses from
        // `b.pb.o` in ModuleB should all be stripped since ModuleB is never
        // referenced in Swift code:
        //
        //   HAS-SYMBOL-NOT: {{(static )?ModuleB\.Test_.*}}
        //   HAS-SYMBOL-NOT: {{.* in ModuleB}}
        //   HAS-SYMBOL-NOT: {{.* for ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{.* type ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{_?test_D.*B_get(Message|Enum|Map)Witness}}

        print("✅ All JSON tests passed!")
    }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
    guard condition() else {
        fatalError("Expected condition to be true at line \(line), but it was false")
    }
}
