import XCTest

import generatedTests

var tests = [XCTestCaseEntry]()
tests += generatedTests.allTests()
XCTMain(tests)
