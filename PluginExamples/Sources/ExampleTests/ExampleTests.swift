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
        let foo = Foo.with { $0.bar = .with { $0.name = "Bar" } }
        XCTAssertEqual(foo.bar.name, "Bar")
    }
}
