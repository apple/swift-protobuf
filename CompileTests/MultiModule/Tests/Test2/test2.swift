import ImportsImportsAPublicly
import ModuleA  // Needed because `import public` doesn't help Swift

import XCTest

final class ExampleTests: XCTestCase {
  func testA() {
    let anA = A.with { $0.e = .a }
    XCTAssertEqual(anA.e, .a)
  }

  func testImportsImportsAPublicly() {
    let imports = ImportsImportsAPublicly.with { $0.a.e = .a }
    XCTAssertEqual(imports.a.e, .a)
  }

  func testInterop() {
    let anA = A.with { $0.e = .b }
    let imports = ImportsImportsAPublicly.with {
      $0.a = anA
      $0.e = .b
    }
    XCTAssertEqual(imports.a.e, imports.e)
    let transtively = UsesATransitively2.with {
      $0.a = anA
      $0.e = imports.e
    }
    XCTAssertEqual(transtively.a, anA)
    XCTAssertEqual(transtively.e, imports.e)
  }
}
