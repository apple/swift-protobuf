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
    do {
      // Referencing MessageA's fields should keep those properties alive.

      // HAS-SYMBOL: nominal type descriptor for ModuleA.Test_MessageA
      // HAS-SYMBOL: ModuleA.Test_MessageA.init() -> ModuleA.Test_MessageA
      var msg = Test_MessageA()
      msg.title = "Hello Weak Imports"
      expect(msg.hasTitle)
      expect(msg.title == "Hello Weak Imports")
    }

    do {
      // Referencing MessageC's fields should keep those properties in MessageA
      // and MessageC alive.

      var msg = Test_MessageA()
      // HAS-SYMBOL: ModuleC.Test_MessageC.id.setter : Swift.Int32
      // HAS-SYMBOL: ModuleA.Test_MessageA.nestedC.{{getter|setter|modify}} : ModuleC.Test_MessageC
      msg.nestedC.id = 12345
      // HAS-SYMBOL: ModuleA.Test_MessageA.hasNestedC.getter : Swift.Bool
      expect(msg.hasNestedC)
      // HAS-SYMBOL: ModuleC.Test_MessageC.id.getter : Swift.Int32
      expect(msg.nestedC.id == 12345)
    }

    // TODO: Add more tests.
    // HAS-SYMBOL-NOT: NonExistentSymbol_DoesNotExist

    print("✅ All tests passed!")
  }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
  guard condition() else {
    fatalError("Expected condition to be true at line \(line), but it was false")
  }
}
