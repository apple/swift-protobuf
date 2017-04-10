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

// NOTE: If this code fails to compile, make sure the name changes make sense.

class Test_FieldNamingInitials: XCTestCase {
  func testHidingFunctions() throws {
    // Check that we can access the standard `serializeData`, etc
    // methods even on messages that define fields or submessages with
    // such names:
    let msg = SwiftUnittest_Names_FieldNames()
    _ = try msg.serializedData()
    _ = try msg.jsonUTF8Data()
    _ = try msg.jsonString()

    let msg2 = ProtobufUnittest_GeneratedSwiftReservedMessages()
    // The submessage is a static type name:
    _ = ProtobufUnittest_GeneratedSwiftReservedMessages.serializedData()
    // The method is an instance property:
    _ = try msg2.serializedData()
    _ = try msg2.jsonUTF8Data()
    _ = try msg2.jsonString()
  }

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

class Test_ExtensionNamingInitials_MessageScoped: XCTestCase {
  func testLowers() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitials()

    msg.SwiftUnittest_Names_Lowers_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_http)
    msg.clearSwiftUnittest_Names_Lowers_http()

    msg.SwiftUnittest_Names_Lowers_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_httpRequest)
    msg.clearSwiftUnittest_Names_Lowers_httpRequest()

    msg.SwiftUnittest_Names_Lowers_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theHTTPRequest)
    msg.clearSwiftUnittest_Names_Lowers_theHTTPRequest()

    msg.SwiftUnittest_Names_Lowers_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theHTTP)
    msg.clearSwiftUnittest_Names_Lowers_theHTTP()

    msg.SwiftUnittest_Names_Lowers_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_https)
    msg.clearSwiftUnittest_Names_Lowers_https()

    msg.SwiftUnittest_Names_Lowers_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_httpsRequest)
    msg.clearSwiftUnittest_Names_Lowers_httpsRequest()

    msg.SwiftUnittest_Names_Lowers_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_Lowers_theHTTPSRequest()

    msg.SwiftUnittest_Names_Lowers_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theHTTPS)
    msg.clearSwiftUnittest_Names_Lowers_theHTTPS()

    msg.SwiftUnittest_Names_Lowers_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_url)
    msg.clearSwiftUnittest_Names_Lowers_url()

    msg.SwiftUnittest_Names_Lowers_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_urlValue)
    msg.clearSwiftUnittest_Names_Lowers_urlValue()

    msg.SwiftUnittest_Names_Lowers_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theURLValue)
    msg.clearSwiftUnittest_Names_Lowers_theURLValue()

    msg.SwiftUnittest_Names_Lowers_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_theURL)
    msg.clearSwiftUnittest_Names_Lowers_theURL()

    msg.SwiftUnittest_Names_Lowers_aBC = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Lowers_aBC)
    msg.clearSwiftUnittest_Names_Lowers_aBC()
  }

  func testUppers() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitials()

    msg.SwiftUnittest_Names_Uppers_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_http)
    msg.clearSwiftUnittest_Names_Uppers_http()

    msg.SwiftUnittest_Names_Uppers_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_httpRequest)
    msg.clearSwiftUnittest_Names_Uppers_httpRequest()

    msg.SwiftUnittest_Names_Uppers_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theHTTPRequest)
    msg.clearSwiftUnittest_Names_Uppers_theHTTPRequest()

    msg.SwiftUnittest_Names_Uppers_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theHTTP)
    msg.clearSwiftUnittest_Names_Uppers_theHTTP()

    msg.SwiftUnittest_Names_Uppers_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_https)
    msg.clearSwiftUnittest_Names_Uppers_https()

    msg.SwiftUnittest_Names_Uppers_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_httpsRequest)
    msg.clearSwiftUnittest_Names_Uppers_httpsRequest()

    msg.SwiftUnittest_Names_Uppers_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_Uppers_theHTTPSRequest()

    msg.SwiftUnittest_Names_Uppers_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theHTTPS)
    msg.clearSwiftUnittest_Names_Uppers_theHTTPS()

    msg.SwiftUnittest_Names_Uppers_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_url)
    msg.clearSwiftUnittest_Names_Uppers_url()

    msg.SwiftUnittest_Names_Uppers_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_urlValue)
    msg.clearSwiftUnittest_Names_Uppers_urlValue()

    msg.SwiftUnittest_Names_Uppers_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theURLValue)
    msg.clearSwiftUnittest_Names_Uppers_theURLValue()

    msg.SwiftUnittest_Names_Uppers_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_Uppers_theURL)
    msg.clearSwiftUnittest_Names_Uppers_theURL()
  }

  func testWordCase() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitials()

    msg.SwiftUnittest_Names_WordCase_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_http)
    msg.clearSwiftUnittest_Names_WordCase_http()

    msg.SwiftUnittest_Names_WordCase_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_httpRequest)
    msg.clearSwiftUnittest_Names_WordCase_httpRequest()

    msg.SwiftUnittest_Names_WordCase_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theHTTPRequest)
    msg.clearSwiftUnittest_Names_WordCase_theHTTPRequest()

    msg.SwiftUnittest_Names_WordCase_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theHTTP)
    msg.clearSwiftUnittest_Names_WordCase_theHTTP()

    msg.SwiftUnittest_Names_WordCase_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_https)
    msg.clearSwiftUnittest_Names_WordCase_https()

    msg.SwiftUnittest_Names_WordCase_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_httpsRequest)
    msg.clearSwiftUnittest_Names_WordCase_httpsRequest()

    msg.SwiftUnittest_Names_WordCase_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_WordCase_theHTTPSRequest()

    msg.SwiftUnittest_Names_WordCase_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theHTTPS)
    msg.clearSwiftUnittest_Names_WordCase_theHTTPS()

    msg.SwiftUnittest_Names_WordCase_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_url)
    msg.clearSwiftUnittest_Names_WordCase_url()

    msg.SwiftUnittest_Names_WordCase_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_urlValue)
    msg.clearSwiftUnittest_Names_WordCase_urlValue()

    msg.SwiftUnittest_Names_WordCase_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theURLValue)
    msg.clearSwiftUnittest_Names_WordCase_theURLValue()

    msg.SwiftUnittest_Names_WordCase_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_WordCase_theURL)
    msg.clearSwiftUnittest_Names_WordCase_theURL()
  }
}

class Test_ExtensionNamingInitials_GlobalScoped: XCTestCase {
  func testLowers() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsLowers()

    msg.SwiftUnittest_Names_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_http)
    msg.clearSwiftUnittest_Names_http()

    msg.SwiftUnittest_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpRequest)
    msg.clearSwiftUnittest_Names_httpRequest()

    msg.SwiftUnittest_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPRequest)
    msg.clearSwiftUnittest_Names_theHTTPRequest()

    msg.SwiftUnittest_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTP)
    msg.clearSwiftUnittest_Names_theHTTP()

    msg.SwiftUnittest_Names_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_https)
    msg.clearSwiftUnittest_Names_https()

    msg.SwiftUnittest_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpsRequest)
    msg.clearSwiftUnittest_Names_httpsRequest()

    msg.SwiftUnittest_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_theHTTPSRequest()

    msg.SwiftUnittest_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPS)
    msg.clearSwiftUnittest_Names_theHTTPS()

    msg.SwiftUnittest_Names_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_url)
    msg.clearSwiftUnittest_Names_url()

    msg.SwiftUnittest_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_urlValue)
    msg.clearSwiftUnittest_Names_urlValue()

    msg.SwiftUnittest_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURLValue)
    msg.clearSwiftUnittest_Names_theURLValue()

    msg.SwiftUnittest_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURL)
    msg.clearSwiftUnittest_Names_theURL()

    msg.SwiftUnittest_Names_aBC = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_aBC)
    msg.clearSwiftUnittest_Names_aBC()
  }

  func testUppers() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsUppers()

    msg.SwiftUnittest_Names_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_http)
    msg.clearSwiftUnittest_Names_http()

    msg.SwiftUnittest_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpRequest)
    msg.clearSwiftUnittest_Names_httpRequest()

    msg.SwiftUnittest_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPRequest)
    msg.clearSwiftUnittest_Names_theHTTPRequest()

    msg.SwiftUnittest_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTP)
    msg.clearSwiftUnittest_Names_theHTTP()

    msg.SwiftUnittest_Names_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_https)
    msg.clearSwiftUnittest_Names_https()

    msg.SwiftUnittest_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpsRequest)
    msg.clearSwiftUnittest_Names_httpsRequest()

    msg.SwiftUnittest_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_theHTTPSRequest()

    msg.SwiftUnittest_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPS)
    msg.clearSwiftUnittest_Names_theHTTPS()

    msg.SwiftUnittest_Names_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_url)
    msg.clearSwiftUnittest_Names_url()

    msg.SwiftUnittest_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_urlValue)
    msg.clearSwiftUnittest_Names_urlValue()

    msg.SwiftUnittest_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURLValue)
    msg.clearSwiftUnittest_Names_theURLValue()

    msg.SwiftUnittest_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURL)
    msg.clearSwiftUnittest_Names_theURL()
  }

  func testWordCase() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsWordCase()

    msg.SwiftUnittest_Names_http = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_http)
    msg.clearSwiftUnittest_Names_http()

    msg.SwiftUnittest_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpRequest)
    msg.clearSwiftUnittest_Names_httpRequest()

    msg.SwiftUnittest_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPRequest)
    msg.clearSwiftUnittest_Names_theHTTPRequest()

    msg.SwiftUnittest_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTP)
    msg.clearSwiftUnittest_Names_theHTTP()

    msg.SwiftUnittest_Names_https = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_https)
    msg.clearSwiftUnittest_Names_https()

    msg.SwiftUnittest_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_httpsRequest)
    msg.clearSwiftUnittest_Names_httpsRequest()

    msg.SwiftUnittest_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPSRequest)
    msg.clearSwiftUnittest_Names_theHTTPSRequest()

    msg.SwiftUnittest_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theHTTPS)
    msg.clearSwiftUnittest_Names_theHTTPS()

    msg.SwiftUnittest_Names_url = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_url)
    msg.clearSwiftUnittest_Names_url()

    msg.SwiftUnittest_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_urlValue)
    msg.clearSwiftUnittest_Names_urlValue()

    msg.SwiftUnittest_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURLValue)
    msg.clearSwiftUnittest_Names_theURLValue()

    msg.SwiftUnittest_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftUnittest_Names_theURL)
    msg.clearSwiftUnittest_Names_theURL()
  }
}

class Test_ExtensionNamingInitials_GlobalScoped_NoPrefix: XCTestCase {
  func testLowers() {
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsLowers()

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
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsUppers()

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
    var msg = SwiftUnittest_Names_ExtensionNamingInitialsWordCase()

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
