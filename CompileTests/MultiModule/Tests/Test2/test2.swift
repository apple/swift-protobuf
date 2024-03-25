import ImportsImportsAPublicly
// Don't need to import ModuleA because of the file being a `import public`

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
    let transitively = UsesATransitively2.with {
      $0.a = anA
      $0.e = imports.e
    }
    XCTAssertEqual(transitively.a, anA)
    XCTAssertEqual(transitively.e, imports.e)
  }
}
