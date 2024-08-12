#if compiler(>=5.9)

import AccessLevelOnImport
import XCTest

final class AccessLevelOnImportTests: XCTestCase {
    func testAccessLevelOnImport() {
        let access = AccessLevelOnImport.with { $0.dependency = .with { $0.name = "Dependency" } }
        XCTAssertEqual(access.dependency.name, "Dependency")
    }
}

#endif
