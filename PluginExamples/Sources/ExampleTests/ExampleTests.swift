import CustomProtoPath
import FlatPackageNaming
import Import
import Nested
import NestedPackageNaming
import Simple
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
        let foo = Import.Foo.with { $0.bar = .with { $0.name = "Bar" } }
        XCTAssertEqual(foo.bar.name, "Bar")
    }

    func testCustomProtoPath() {
        let main = CustomProtoPath.Main.with {
            $0.bar = .with { $0.name = "Bar" }
            $0.foo = .with { $0.bar = .with { $0.name = "BarInFoo" } }
        }
        XCTAssertEqual(main.bar.name, "Bar")
        XCTAssertEqual(main.foo.bar.name, "BarInFoo")
    }

    func testPackageNaming() {
        let nested = Com.Apple.Foo.NestedPackageNaming.with { $0.name = "Nested" }
        let flat = Com_Apple_Foo_FlatPackageNaming.with { $0.name = "Flat" }
        XCTAssertEqual(nested.name, "Nested")
        XCTAssertEqual(flat.name, "Flat")
    }
}
