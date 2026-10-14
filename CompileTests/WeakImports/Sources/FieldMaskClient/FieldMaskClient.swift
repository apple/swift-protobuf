import ModuleA
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Tests FieldMask operations (`isPathValid`, `trim`, `merge`) with weak-linked
/// Swift protos, verifying that schema and reflection data in `.pbschema.o` is
/// retained via `live_support` while unreferenced nominal types and witnesses
/// in `.pb.o` (ModuleB) remain stripped.
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

            // Top-level fields of MessageA (including those whose types are in ModuleB)
            // are known in MessageA's reflection table:
            expect(Test_MessageA.isPathValid("title"))
            expect(Test_MessageA.isPathValid("nested_b"))
            expect(Test_MessageA.isPathValid("nested_enum"))
            expect(Test_MessageA.isPathValid("nested_c"))
            expect(Test_MessageA.isPathValid("nested_enum_c"))

            // Subpaths into linked ModuleC are valid:
            expect(Test_MessageA.isPathValid("nested_c.id"))
            expect(Test_MessageA.isPathValid("nested_c.detail"))
            expect(!Test_MessageA.isPathValid("nested_c.nonexistent"))

            #if canImport(Darwin)
            // On Darwin, `b.pbschema.o` is retained via `live_support`, so deep
            // subpaths into ModuleB are also valid without linking `b.pb.o`:
            expect(Test_MessageA.isPathValid("nested_b.id"))
            expect(Test_MessageA.isPathValid("nested_b.detail"))
            expect(!Test_MessageA.isPathValid("nested_b.nonexistent"))
            #endif
        }

        do {
            // Verify `trim(keeping:)` and `merge(from:fieldMask:)` across both
            // linked ModuleC subpaths and unlinked ModuleB subpaths.
            //
            // Field 1 (title): "Original"
            // Field 2 (nested_b): tag 0x12, len 6, payload [0x08, 0x64, 0x12, 0x02, 0x68, 0x69] (id: 100, detail: "hi")
            let rawBytes = Data([
                0x0A, 0x08, 0x4F, 0x72, 0x69, 0x67, 0x69, 0x6E, 0x61, 0x6C,
                0x12, 0x06, 0x08, 0x64, 0x12, 0x02, 0x68, 0x69,
            ])
            var msg = try! Test_MessageA(serializedBytes: rawBytes)
            msg.nestedC.id = 42
            msg.nestedC.detail = "keep or trim"
            msg.nestedEnumC = .first

            #if canImport(Darwin)
            let mask = Google_Protobuf_FieldMask(protoPaths: "nested_b.id", "nested_c.id")
            #else
            let mask = Google_Protobuf_FieldMask(protoPaths: "nested_b", "nested_c.id")
            #endif
            let changed = msg.trim(keeping: mask)
            expect(changed)
            expect(!msg.hasTitle)
            expect(msg.hasNestedB)
            expect(msg.hasNestedC)
            expect(msg.nestedC.id == 42)
            expect(msg.nestedC.detail.isEmpty)
            expect(!msg.hasNestedEnumC)

            #if canImport(Darwin)
            // Verify that `nested_b.detail` was trimmed while `nested_b.id` (100) was kept:
            var checkB = msg
            checkB.clearNestedC()
            let trimmedBBytes = try! checkB.serializedData()
            expect(trimmedBBytes == Data([0x12, 0x02, 0x08, 0x64]))
            #endif

            // Merge `title` and `nested_c.detail` from another message using a FieldMask:
            var source = Test_MessageA()
            source.title = "Merged Title"
            source.nestedC.id = 999
            source.nestedC.detail = "merged detail"

            let mergeMask = Google_Protobuf_FieldMask(protoPaths: "title", "nested_c.detail")
            try! msg.merge(from: source, fieldMask: mergeMask)
            expect(msg.title == "Merged Title")
            expect(msg.hasNestedB)
            expect(msg.nestedC.id == 42)
            expect(msg.nestedC.detail == "merged detail")
        }

        // Nominal type metadata, property accessors, and concrete witnesses from
        // `b.pb.o` in ModuleB should all be stripped since ModuleB is never
        // referenced in Swift code:
        //
        //   HAS-SYMBOL-NOT: {{(static )?ModuleB\.Test_.*}}
        //   HAS-SYMBOL-NOT: {{.* in ModuleB}}
        //   HAS-SYMBOL-NOT: {{.* for ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{.* type ModuleB\..*}}
        //   HAS-SYMBOL-NOT: {{_?test_D.*B_get(Message|Enum|Map)Witness}}

        print("✅ All FieldMask tests passed!")
    }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
    guard condition() else {
        fatalError("Expected condition to be true at line \(line), but it was false")
    }
}
