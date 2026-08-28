import ModuleA

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
        }

        // TODO: ModuleB symbols should all be stripped since they're never
        // referenced by this source file, so the long-term goal is for these
        // to all be `HAS-SYMBOL-NOT` checks. For now, we list the symbols
        // explicitly so we can chip away at them as the work progresses but
        // keeping the tests passing in the current state. Later, we can replace
        // them with regular expressions to ensure that no symbols matching a
        // particular pattern end up in the final linkage.
        //
        // Protobuf runtime support:
        //   HAS-SYMBOL: {{_?}}test_DMessageB_getMessageSchema
        //   HAS-SYMBOL: static ModuleB.Test_MessageB.messageSchema : SwiftProtobuf.MessageSchema
        //
        // Protocol conformance support:
        //   HAS-SYMBOL: base witness table accessor for Swift.Equatable in ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: instantiation function for generic protocol witness table for ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: instantiation function for generic protocol witness table for ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: metadata instantiation cache for protocol conformance descriptor for ModuleB.Test_MessageB : Swift.CustomDebugStringConvertible in ModuleB
        //   HAS-SYMBOL: metadata instantiation cache for protocol conformance descriptor for ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: metadata instantiation cache for protocol conformance descriptor for ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: metadata instantiation cache for protocol conformance descriptor for ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: metadata instantiation cache for protocol conformance descriptor for ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol conformance descriptor for ModuleB.Test_MessageB : Swift.CustomDebugStringConvertible in ModuleB
        //   HAS-SYMBOL: protocol conformance descriptor for ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: protocol conformance descriptor for ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: protocol conformance descriptor for ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: protocol conformance descriptor for ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness table for ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: protocol witness table for ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for Swift.CustomDebugStringConvertible.debugDescription.getter : Swift.String in conformance ModuleB.Test_MessageB : Swift.CustomDebugStringConvertible in ModuleB
        //   HAS-SYMBOL: protocol witness for static Swift.Equatable.== infix(A, A) -> Swift.Bool in conformance ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: protocol witness for Swift.Hashable._rawHashValue(seed: Swift.Int) -> Swift.Int in conformance ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: protocol witness for Swift.Hashable.hash(into: inout Swift.Hasher) -> () in conformance ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: protocol witness for Swift.Hashable.hashValue.getter : Swift.Int in conformance ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: protocol witness for static SwiftProtobuf.GeneratedMessage.messageSchema.getter : SwiftProtobuf.MessageSchema in conformance ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: protocol witness for static SwiftProtobuf.Message.protoMessageName.getter : Swift.String in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for SwiftProtobuf.Message.messageSchema.getter : SwiftProtobuf.MessageSchema in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for SwiftProtobuf.Message._protobuf_messageStorage(accessToken: SwiftProtobuf.MessageStorageToken) -> Swift.AnyObject in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for SwiftProtobuf.Message._protobuf_ensureUniqueStorage(accessToken: SwiftProtobuf.MessageStorageToken) -> () in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for SwiftProtobuf.Message.isEqualTo(message: SwiftProtobuf.Message) -> Swift.Bool in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: protocol witness for SwiftProtobuf.Message.init() -> A in conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.CustomDebugStringConvertible in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table accessor for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.CustomDebugStringConvertible in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Equatable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : Swift.Hashable in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : SwiftProtobuf.GeneratedMessage in ModuleB
        //   HAS-SYMBOL: lazy protocol witness table cache variable for type ModuleB.Test_MessageB and conformance ModuleB.Test_MessageB : SwiftProtobuf.Message in ModuleB
        //
        // Type metadata:
        //   HAS-SYMBOL: full type metadata for ModuleB.Test_MessageB
        //   HAS-SYMBOL: nominal type descriptor for ModuleB.Test_MessageB
        //   HAS-SYMBOL: type metadata accessor for ModuleB.Test_MessageB
        //   HAS-SYMBOL: type metadata for ModuleB.Test_MessageB

        print("✅ All tests passed!")
    }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
    guard condition() else {
        fatalError("Expected condition to be true at line \(line), but it was false")
    }
}
