import ModuleA

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A small test harness for weak-linked Swift protos.
///
/// We use a minimal executable client to make sure we have as much control over
/// the linkage as possible (i.e., we want to replicate the conditions a client
/// application would have, not pick up any subtle differences from Darwin
/// idiosyncracies like `MH_BUNDLE` if we used a test bundle).
///
/// The test cases in this file verify the correctness of the runtime behavior,
/// even when messages/enums are stripped from the linkage. A separate script
/// verifies the presence/absence of symbols themselves.
@main
struct Main {
    static func main() {
        // We can't reliably test for the presence of individual accessors
        // because the compiler may inline them and then discard the
        // canonical symbol if it's no longer referenced anywhere. This is
        // fine and actually what we want. Instead, we just check for
        // symbols that will never be inlined, like metadata.

        do {
            // Verify that MessageA is obviously kept in the linkage.
            //
            // Here and below, the C functions used to dynamically load schemas
            // match optional leading underscores, because Darwin includes an
            // underscore while Linux does not.

            // HAS-SYMBOL: full type metadata for ModuleA.Test_MessageA
            // HAS-SYMBOL: nominal type descriptor for ModuleA.Test_MessageA
            // HAS-SYMBOL: type metadata accessor for ModuleA.Test_MessageA
            // HAS-SYMBOL: type metadata for ModuleA.Test_MessageA
            // HAS-SYMBOL: ModuleA.Test_MessageA.init() -> ModuleA.Test_MessageA
            // HAS-SYMBOL: {{_?}}test_DMessageA_getMessageSchema
            var msg = Test_MessageA()
            msg.title = "Hello Weak Imports"
            expect(msg.hasTitle)
            expect(msg.title == "Hello Weak Imports")
        }

        do {
            var msg = Test_MessageA()

            // HAS-SYMBOL: full type metadata for ModuleC.Test_MessageC
            // HAS-SYMBOL: nominal type descriptor for ModuleC.Test_MessageC
            // HAS-SYMBOL: type metadata accessor for ModuleC.Test_MessageC
            // HAS-SYMBOL: type metadata for ModuleC.Test_MessageC
            // HAS-SYMBOL: {{_?}}test_DMessageC_getMessageSchema
            msg.nestedC.id = 12345
            expect(msg.hasNestedC)
            expect(msg.nestedC.id == 12345)

            // HAS-SYMBOL: full type metadata for ModuleC.Test_EnumC
            // HAS-SYMBOL: nominal type descriptor for ModuleC.Test_EnumC
            // HAS-SYMBOL: type metadata accessor for ModuleC.Test_EnumC
            // HAS-SYMBOL: type metadata for ModuleC.Test_EnumC
            msg.nestedEnumC = .first
            expect(msg.hasNestedEnumC)
            expect(msg.nestedEnumC == .first)

            msg.mapC["key"] = msg.nestedC
            expect(msg.mapC["key"]?.id == 12345)
            msg.Test_extMessageC.id = 67890
            expect(msg.hasTest_extMessageC)
            expect(msg.Test_extMessageC.id == 67890)
            msg.Test_extEnumC = .first
            expect(msg.hasTest_extEnumC)
            expect(msg.Test_extEnumC == .first)
            msg.Test_extRepeatedMessageC = [msg.nestedC]
            expect(msg.Test_extRepeatedMessageC.count == 1)
            expect(msg.Test_extRepeatedMessageC[0].id == 12345)
            msg.Test_extRepeatedEnumC = [.first, .unspecified]
            expect(msg.Test_extRepeatedEnumC == [.first, .unspecified])
            let bytes = try! msg.serializedData()
            let decoded = try! Test_MessageA(serializedBytes: bytes, extensions: Test_A_Extensions)
            expect(decoded.mapC["key"]?.id == 12345)
            expect(decoded.Test_extMessageC.id == 67890)
            expect(decoded.Test_extEnumC == .first)
            expect(decoded.Test_extRepeatedMessageC.count == 1)
            expect(decoded.Test_extRepeatedMessageC[0].id == 12345)
            expect(decoded.Test_extRepeatedEnumC == [.first, .unspecified])

            // Test oneof equality
            var msg1 = Test_MessageA()
            var msg2 = Test_MessageA()
            expect(msg1.oneofC == nil)
            expect(msg1.oneofC == msg2.oneofC)

            msg1.nestedC.id = 100
            msg1.oneofMessageC = msg1.nestedC
            expect(msg1.oneofC == .oneofMessageC(msg1.nestedC))
            expect(msg1.oneofC != msg2.oneofC)
            msg2.oneofMessageC = msg1.nestedC
            expect(msg1.oneofC == msg2.oneofC)

            msg2.nestedC.id = 200
            msg2.oneofMessageC = msg2.nestedC
            expect(msg1.oneofC != msg2.oneofC)

            msg1.oneofEnumC = .first
            msg2.oneofEnumC = .first
            expect(msg1.oneofC == msg2.oneofC)
            expect(msg1.oneofC == .oneofEnumC(.first))
            msg2.oneofEnumC = .unspecified
            expect(msg1.oneofC != msg2.oneofC)
        }

        do {
            // This test ensures that when a map field whose value type is from
            // an unlinked module (MessageB) is encountered in the payload,
            // the map entry bytes are preserved into unknown fields and round-trip.
            //
            // Field 1 (title): "Hello" (tag 0x0A, len 5, "Hello")
            // Field 4 (map_b): tag 0x22, len 9
            //   Entry field 1 (key): tag 0x0A, len 3, "foo"
            //   Entry field 2 (value): tag 0x12, len 2, [0x08, 0x2A] (id: 42)
            let rawBytes = Data([
                0x0A, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F,
                0x22, 0x09,
                0x0A, 0x03, 0x66, 0x6F, 0x6F,
                0x12, 0x02, 0x08, 0x2A,
            ])
            let decoded = try! Test_MessageA(serializedBytes: rawBytes)
            expect(decoded.hasTitle)
            expect(decoded.title == "Hello")
            // Re-serializing should preserve the exact original bytes including
            // the `map_b` payload in unknown fields.
            let reserialized = try! decoded.serializedData()
            expect(reserialized == rawBytes)

            // Copy-on-write test: mutating decoded message
            var copy = decoded
            copy.title = "World"
            expect(copy.title == "World")
            expect(decoded.title == "Hello")

            let copyBytes = try! copy.serializedData()
            let expectedCopyBytes = Data([
                0x0A, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64,
                0x22, 0x09,
                0x0A, 0x03, 0x66, 0x6F, 0x6F,
                0x12, 0x02, 0x08, 0x2A,
            ])
            expect(copyBytes == expectedCopyBytes)
        }

        do {
            // This test ensures that even without `MessageB` being linked into
            // the binary, decoding, hazzer behavior, and encoding for singular
            // and repeated message fields and extensions all round-trip correctly.

            // Field 1 (title): "Hello" (tag 0x0A, len 5, "Hello")
            // Field 2 (nested_b): tag 0x12, len 2, payload [0x08, 0x64] (id: 100)
            // Field 100 (ext_message): tag [0xA2, 0x06], len 2, payload [0x08, 0x64] (id: 100)
            // Field 102 (ext_repeated_message): tag [0xB2, 0x06], len 2, payload [0x08, 0x65] (id: 101)
            let rawBytes = Data([
                0x0A, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F,
                0x12, 0x02, 0x08, 0x64,
                0xA2, 0x06, 0x02, 0x08, 0x64,
                0xB2, 0x06, 0x02, 0x08, 0x65,
            ])
            let decoded = try! Test_MessageA(serializedBytes: rawBytes, extensions: Test_A_Extensions)
            expect(decoded.hasTitle)
            expect(decoded.title == "Hello")
            expect(decoded.hasNestedB)
            expect(decoded.hasTest_extMessage)
            expect(!decoded.hasNestedC)
            expect(!decoded.hasTest_extMessageC)

            // Re-serializing should preserve the exact original bytes including
            // the `nested_b`, `ext_message`, and `ext_repeated_message` payloads.
            let reserialized = try! decoded.serializedData()
            expect(reserialized == rawBytes)

            // Copy-on-write test: copying decoded message and mutating title
            var copy = decoded
            expect(copy.hasNestedB)
            expect(copy.hasTest_extMessage)
            copy.title = "World"
            expect(copy.title == "World")
            expect(decoded.title == "Hello")
            // Invoking the hazzers here ensures that the placeholder messages are
            // working as expected. If they return false but the check of the
            // reserialized bytes above succeeded, that means the submessage
            // data was placed in the parent message's unknown fields, which is
            // incorrect.
            //
            // NOTE: We must ONLY use the hazzers here. Accessing `nestedB` or
            // `Test_extMessage` directly would pull `MessageB` into the linkage.
            expect(copy.hasNestedB)
            expect(copy.hasTest_extMessage)

            let copyBytes = try! copy.serializedData()
            let expectedCopyBytes = Data([
                0x0A, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64,
                0x12, 0x02, 0x08, 0x64,
                0xA2, 0x06, 0x02, 0x08, 0x64,
                0xB2, 0x06, 0x02, 0x08, 0x65,
            ])
            expect(copyBytes == expectedCopyBytes)
        }

        do {
            // This test ensures that even without `EnumB` being linked into
            // the binary, decoding, hazzer behavior, and encoding for singular
            // and repeated enums (including extensions) all round-trip correctly.
            //
            // Field 1 (title): "Hello" (tag 0x0A, len 5, "Hello")
            // Field 3 (nested_enum): tag 0x18, varint 1 (ENUM_B_FIRST)
            // Field 6 (repeated_enum_b): tag 0x30, varint 1; tag 0x30, varint 2
            // Field 8 (oneof_enum_b): tag 0x40, varint 1
            // Field 101 (ext_enum): tag [0xA8, 0x06], varint 1
            // Field 103 (ext_repeated_enum): tag [0xB8, 0x06], varint 1; tag [0xB8, 0x06], varint 2
            let rawBytes = Data([
                0x0A, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F,
                0x18, 0x01,
                0x30, 0x01, 0x30, 0x02,
                0x40, 0x01,
                0xA8, 0x06, 0x01,
                0xB8, 0x06, 0x01, 0xB8, 0x06, 0x02,
            ])
            let decoded = try! Test_MessageA(serializedBytes: rawBytes, extensions: Test_A_Extensions)
            expect(decoded.hasTitle)
            expect(decoded.title == "Hello")
            expect(decoded.hasNestedEnum)
            expect(decoded.hasTest_extEnum)
            expect(!decoded.hasNestedEnumC)
            expect(!decoded.hasTest_extEnumC)

            // Re-serializing should preserve the exact original bytes.
            let reserialized = try! decoded.serializedData()
            expect(reserialized == rawBytes)

            // Copy-on-write test: mutating decoded message
            var copy = decoded
            expect(copy.hasNestedEnum)
            expect(copy.hasTest_extEnum)
            copy.title = "World"
            expect(copy.title == "World")
            expect(decoded.title == "Hello")
            expect(copy.hasNestedEnum)
            expect(copy.hasTest_extEnum)

            let copyBytes = try! copy.serializedData()
            let expectedCopyBytes = Data([
                0x0A, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64,
                0x18, 0x01,
                0x30, 0x01, 0x30, 0x02,
                0x40, 0x01,
                0xA8, 0x06, 0x01,
                0xB8, 0x06, 0x01, 0xB8, 0x06, 0x02,
            ])
            expect(copyBytes == expectedCopyBytes)
        }

        // ModuleB symbols should all be stripped since they're never referenced
        // by this source file:
        //
        //   HAS-SYMBOL-NOT: {{(static )?ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{.* in ModuleB}}
        //   HAS-SYMBOL-NOT: {{.* for ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{.* type ModuleB\..*}}
        //
        // C functions exported via @_cdecl for dynamic schema and witness lookup
        // of types in ModuleB (in proto package "test", matching functions such as
        // `test_DMessageB_getMessageSchema` and `test_DEnumB_getMapWitness`):
        //   HAS-SYMBOL-NOT: {{_?test_D.*B_.*}}

        print("✅ All tests passed!")
    }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
    guard condition() else {
        fatalError("Expected condition to be true at line \(line), but it was false")
    }
}
