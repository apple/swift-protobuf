import XCTest

import bgeneratedTests

var tests = [XCTestCaseEntry]()
tests += bgeneratedTests.allTests()
XCTMain(tests)
