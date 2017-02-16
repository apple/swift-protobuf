// Tests/SwiftProtobufTests/Test_Naming.swift - Verify handling of special naming
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

// In transforming some of the names in protos to Swift names, we do different
// transforms, this test is mainly a compile test in that the code below calls
// methods as they should be generated, so if the name transforms change from
// the expected, this code won't compile any more.
//
// By using proto2 syntax the has*/clear* methods are generated enabling this
// code to call those to help ensure things end up uniformly upper/lower as
// needed.

// NOTE: If this code fails to compile, make sure the name change make sense.

class Test_FieldNamingInitials: XCTestCase {
  func testLowers() {
    var msg = SwiftUnittest_Names_FieldNamingInitials.Lowers()

    msg.http = 1
    XCTAssertTrue(msg.hasHTTP)
    msg.clearHTTP()

    msg.httpRequest = 1
    XCTAssertTrue(msg.hasHTTPRequest)
    msg.clearHTTPRequest()

    msg.theHTTPRequest = 1
    XCTAssertTrue(msg.hasTheHTTPRequest)
    msg.clearTheHTTPRequest()

    msg.theHTTP = 1
    XCTAssertTrue(msg.hasTheHTTP)
    msg.clearTheHTTP()

    msg.https = 1
    XCTAssertTrue(msg.hasHTTPS)
    msg.clearHTTPS()

    msg.httpsRequest = 1
    XCTAssertTrue(msg.hasHTTPSRequest)
    msg.clearHTTPSRequest()

    msg.theHTTPSRequest = 1
    XCTAssertTrue(msg.hasTheHTTPSRequest)
    msg.clearTheHTTPSRequest()

    msg.theHTTPS = 1
    XCTAssertTrue(msg.hasTheHTTPS)
    msg.clearTheHTTPS()

    msg.url = 1
    XCTAssertTrue(msg.hasURL)
    msg.clearURL()

    msg.urlValue = 1
    XCTAssertTrue(msg.hasURLValue)
    msg.clearURLValue()

    msg.theURLValue = 1
    XCTAssertTrue(msg.hasTheURLValue)
    msg.clearTheURLValue()

    msg.theURL = 1
    XCTAssertTrue(msg.hasTheURL)
    msg.clearTheURL()

    msg.aBC = 1
    XCTAssertTrue(msg.hasABC)
    msg.clearABC()
  }

  func testUppers() {
    var msg = SwiftUnittest_Names_FieldNamingInitials.Uppers()

    msg.http = 1
    XCTAssertTrue(msg.hasHTTP)
    msg.clearHTTP()

    msg.httpRequest = 1
    XCTAssertTrue(msg.hasHTTPRequest)
    msg.clearHTTPRequest()

    msg.theHTTPRequest = 1
    XCTAssertTrue(msg.hasTheHTTPRequest)
    msg.clearTheHTTPRequest()

    msg.theHTTP = 1
    XCTAssertTrue(msg.hasTheHTTP)
    msg.clearTheHTTP()

    msg.https = 1
    XCTAssertTrue(msg.hasHTTPS)
    msg.clearHTTPS()

    msg.httpsRequest = 1
    XCTAssertTrue(msg.hasHTTPSRequest)
    msg.clearHTTPSRequest()

    msg.theHTTPSRequest = 1
    XCTAssertTrue(msg.hasTheHTTPSRequest)
    msg.clearTheHTTPSRequest()

    msg.theHTTPS = 1
    XCTAssertTrue(msg.hasTheHTTPS)
    msg.clearTheHTTPS()

    msg.url = 1
    XCTAssertTrue(msg.hasURL)
    msg.clearURL()

    msg.urlValue = 1
    XCTAssertTrue(msg.hasURLValue)
    msg.clearURLValue()

    msg.theURLValue = 1
    XCTAssertTrue(msg.hasTheURLValue)
    msg.clearTheURLValue()

    msg.theURL = 1
    XCTAssertTrue(msg.hasTheURL)
    msg.clearTheURL()
  }

  func testWordCase() {
    var msg = SwiftUnittest_Names_FieldNamingInitials.WordCase()

    msg.http = 1
    XCTAssertTrue(msg.hasHTTP)
    msg.clearHTTP()

    msg.httpRequest = 1
    XCTAssertTrue(msg.hasHTTPRequest)
    msg.clearHTTPRequest()

    msg.theHTTPRequest = 1
    XCTAssertTrue(msg.hasTheHTTPRequest)
    msg.clearTheHTTPRequest()

    msg.theHTTP = 1
    XCTAssertTrue(msg.hasTheHTTP)
    msg.clearTheHTTP()

    msg.https = 1
    XCTAssertTrue(msg.hasHTTPS)
    msg.clearHTTPS()

    msg.httpsRequest = 1
    XCTAssertTrue(msg.hasHTTPSRequest)
    msg.clearHTTPSRequest()

    msg.theHTTPSRequest = 1
    XCTAssertTrue(msg.hasTheHTTPSRequest)
    msg.clearTheHTTPSRequest()

    msg.theHTTPS = 1
    XCTAssertTrue(msg.hasTheHTTPS)
    msg.clearTheHTTPS()

    msg.url = 1
    XCTAssertTrue(msg.hasURL)
    msg.clearURL()

    msg.urlValue = 1
    XCTAssertTrue(msg.hasURLValue)
    msg.clearURLValue()

    msg.theURLValue = 1
    XCTAssertTrue(msg.hasTheURLValue)
    msg.clearTheURLValue()

    msg.theURL = 1
    XCTAssertTrue(msg.hasTheURL)
    msg.clearTheURL()
  }
}
