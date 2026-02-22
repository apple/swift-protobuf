import CustomProtoPath
import Import
import Nested
import Simple
import XCTest

#if compiler(>=6.2.3)
import Nonexhaustive
#endif

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

    #if compiler(>=6.2.3)
    func testNonexhaustive() {
        let testEnum = TestEnum.valueA
        switch testEnum {
        case .valueA: break
        case .valueB: break
        case .unknown: break
        case .UNRECOGNIZED: break
        @unknown default: break
        }

        let testMessage = TestMessage.with { $0.payload = .text("test") }
        switch testMessage.payload! {
        case .text: break
        case .data: break
        @unknown default: break
        }
    }
    #endif
}
