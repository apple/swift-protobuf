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
      var msg = Test_MessageA()
      msg.title = "Hello Weak Imports"
      expect(msg.hasTitle)
      expect(msg.title == "Hello Weak Imports")
    }

    do {
      // Referencing MessageC's fields should keep those properties in MessageA
      // and MessageC alive.
      var msg = Test_MessageA()
      msg.nestedC.id = 12345
      expect(msg.hasNestedC)
      expect(msg.nestedC.id == 12345)
    }

    // TODO: Add more tests.

    print("✅ All tests passed!")
  }
}

func expect(_ condition: @autoclosure () -> Bool, line: UInt = #line) {
  guard condition() else {
    fatalError("Expected condition to be true at line \(line), but it was false")
  }
}
