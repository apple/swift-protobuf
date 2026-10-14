import ModuleA
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Tests TextFormat encoding and decoding with weak-linked Swift protos,
/// verifying that schema and reflection data in `.pbschema.o` is retained via
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
            msg.title = "Hello TextFormat"
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
            msg.Test_extMessageC = .with {
                $0.id = 777
                $0.detail = "ext"
            }
            msg.Test_extEnumC = .first

            let text = msg.textFormatString()
            expect(text.contains("title: \"Hello TextFormat\""))
            expect(text.contains("nested_c {"))
            expect(text.contains("nested_enum_c: ENUM_C_FIRST"))
            expect(text.contains("map_c {"))
            expect(text.contains("repeated_c {"))
            expect(text.contains("repeated_enum_c: ENUM_C_UNSPECIFIED"))
            expect(text.contains("repeated_enum_c: ENUM_C_FIRST"))
            expect(text.contains("oneof_message_c {"))
            expect(text.contains("[test.ext_message_c] {"))
            expect(text.contains("[test.ext_enum_c]: ENUM_C_FIRST"))

            let decoded = try! Test_MessageA(textFormatString: text, extensions: Test_A_Extensions)
            expect(decoded == msg)
            expect(decoded.title == "Hello TextFormat")
            expect(decoded.nestedC.id == 12345)
            expect(decoded.nestedC.detail == "nested detail")
            expect(decoded.nestedEnumC == .first)
            expect(decoded.mapC["alpha"]?.id == 42)
            expect(decoded.mapC["alpha"]?.detail == "map value")
            expect(decoded.repeatedC.count == 2)
            expect(decoded.repeatedEnumC == [.unspecified, .first])
            expect(decoded.oneofMessageC.id == 99)
            expect(decoded.Test_extMessageC.id == 777)
            expect(decoded.Test_extEnumC == .first)
        }

        #if canImport(Darwin)
        do {
            // Verify full TextFormat <-> Binary round-tripping of all field kinds
            // whose types come from ModuleB (`b.pbschema.o` is retained via
            // `live_support` while `b.pb.o` is never linked).
            let inputText = """
                title: "RoundTrip B"
                nested_b {
                  id: 100
                  detail: "from b"
                }
                nested_enum: ENUM_B_FIRST
                map_b {
                  key: "k"
                  value {
                    id: 42
                    detail: "map b"
                  }
                }
                repeated_b {
                  id: 1
                  detail: "r1"
                }
                repeated_enum_b: ENUM_B_UNSPECIFIED
                repeated_enum_b: ENUM_B_FIRST
                oneof_message_b {
                  id: 7
                  detail: "oneof b"
                }
                [test.ext_message] {
                  id: 88
                  detail: "ext b"
                }
                [test.ext_enum]: ENUM_B_FIRST
                """
            let fromText = try! Test_MessageA(textFormatString: inputText, extensions: Test_A_Extensions)
            expect(fromText.title == "RoundTrip B")
            expect(fromText.hasNestedB)
            expect(fromText.hasNestedEnum)
            expect(fromText.hasTest_extMessage)
            expect(fromText.hasTest_extEnum)

            let bytes = try! fromText.serializedData()
            let fromBytes = try! Test_MessageA(serializedBytes: bytes, extensions: Test_A_Extensions)
            expect(fromBytes == fromText)

            let roundTrippedText = fromBytes.textFormatString()
            expect(roundTrippedText.contains("nested_b {\n  id: 100\n  detail: \"from b\"\n}"))
            expect(roundTrippedText.contains("nested_enum: ENUM_B_FIRST"))
            expect(
                roundTrippedText.contains("map_b {\n  key: \"k\"\n  value {\n    id: 42\n    detail: \"map b\"\n  }\n}")
            )
            expect(roundTrippedText.contains("repeated_b {\n  id: 1\n  detail: \"r1\"\n}"))
            expect(roundTrippedText.contains("repeated_enum_b: ENUM_B_UNSPECIFIED"))
            expect(roundTrippedText.contains("repeated_enum_b: ENUM_B_FIRST"))
            expect(roundTrippedText.contains("oneof_message_b {\n  id: 7\n  detail: \"oneof b\"\n}"))
            expect(roundTrippedText.contains("[test.ext_message] {\n  id: 88\n  detail: \"ext b\"\n}"))
            expect(roundTrippedText.contains("[test.ext_enum]: ENUM_B_FIRST"))
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

        print("✅ All TextFormat tests passed!")
    }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
    guard condition() else {
        fatalError("Expected condition to be true at line \(line), but it was false")
    }
}
