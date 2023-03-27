import Simple
import Nested
import Import

import XCTest

final class ExampleTests: XCTestCase {
    func testSimple() {
        let simple = Simple.with { $0.name = "Simple" }
        XCTAssertEqual(simple.name, "Simple")
    }

    func testNested() {
        let nested = Nested.with { $0.name = "Nested" }
        XCTAssertEqual(nested.name, "Nested")
    }

    func testImport() {
        let importFoo = ImportFoo.with { $0.bar = .with { $0.name = "ImportBar" } }
        XCTAssertEqual(importFoo.bar.name, "ImportBar")
    }
}
