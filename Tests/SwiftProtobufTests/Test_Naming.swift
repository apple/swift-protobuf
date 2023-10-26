// Tests/SwiftProtobufTests/Test_Naming.swift - Verify handling of special naming
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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

final class Test_PackageMapping: XCTestCase {
  func testPackageStartingWithNumber() {
    let _ = _4fun_SwiftProtoTesting_Mumble_MyMessage()
  }
}

final class Test_FieldNamingInitials: XCTestCase {
  func testHidingFunctions() throws {
    // Check that we can access the standard `serializeData`, etc
    // methods even on messages that define fields or submessages with
    // such names:
    let msg = SwiftProtoTesting_Names_FieldNames()
    _ = try msg.serializedBytes() as [UInt8]
    _ = try msg.jsonUTF8Bytes() as [UInt8]
    _ = try msg.jsonString()

    let msg2 = SwiftProtoTesting_Names_MessageNames()
    // The submessage is a static type name:
    _ = SwiftProtoTesting_Names_MessageNames.serializedData()
    // The method is an instance property:
    _ = try msg2.serializedBytes() as [UInt8]
    _ = try msg2.jsonUTF8Bytes() as [UInt8]
    _ = try msg2.jsonString()
  }

  func testLowers() {
    var msg = SwiftProtoTesting_Names_FieldNamingInitials.Lowers()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }

  func testUppers() {
    var msg = SwiftProtoTesting_Names_FieldNamingInitials.Uppers()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }

  func testWordCase() {
    var msg = SwiftProtoTesting_Names_FieldNamingInitials.WordCase()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }
}

final class Test_ExtensionNamingInitials_MessageScoped: XCTestCase {
  func testLowers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitials()

    msg.SwiftProtoTesting_Names_Lowers_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_http)
    msg.clearSwiftProtoTesting_Names_Lowers_http()

    msg.SwiftProtoTesting_Names_Lowers_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_httpRequest)
    msg.clearSwiftProtoTesting_Names_Lowers_httpRequest()

    msg.SwiftProtoTesting_Names_Lowers_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_Lowers_theHTTPRequest()

    msg.SwiftProtoTesting_Names_Lowers_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theHTTP)
    msg.clearSwiftProtoTesting_Names_Lowers_theHTTP()

    msg.SwiftProtoTesting_Names_Lowers_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_https)
    msg.clearSwiftProtoTesting_Names_Lowers_https()

    msg.SwiftProtoTesting_Names_Lowers_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_httpsRequest)
    msg.clearSwiftProtoTesting_Names_Lowers_httpsRequest()

    msg.SwiftProtoTesting_Names_Lowers_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_Lowers_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_Lowers_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theHTTPS)
    msg.clearSwiftProtoTesting_Names_Lowers_theHTTPS()

    msg.SwiftProtoTesting_Names_Lowers_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_url)
    msg.clearSwiftProtoTesting_Names_Lowers_url()

    msg.SwiftProtoTesting_Names_Lowers_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_urlValue)
    msg.clearSwiftProtoTesting_Names_Lowers_urlValue()

    msg.SwiftProtoTesting_Names_Lowers_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theURLValue)
    msg.clearSwiftProtoTesting_Names_Lowers_theURLValue()

    msg.SwiftProtoTesting_Names_Lowers_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theURL)
    msg.clearSwiftProtoTesting_Names_Lowers_theURL()

    msg.SwiftProtoTesting_Names_Lowers_aBC = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_aBC)
    msg.clearSwiftProtoTesting_Names_Lowers_aBC()

    msg.SwiftProtoTesting_Names_Lowers_id = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_id)
    msg.clearSwiftProtoTesting_Names_Lowers_id()

    msg.SwiftProtoTesting_Names_Lowers_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_idNumber)
    msg.clearSwiftProtoTesting_Names_Lowers_idNumber()

    msg.SwiftProtoTesting_Names_Lowers_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_theIDNumber)
    msg.clearSwiftProtoTesting_Names_Lowers_theIDNumber()

    msg.SwiftProtoTesting_Names_Lowers_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Lowers_requestID)
    msg.clearSwiftProtoTesting_Names_Lowers_requestID()
  }

  func testUppers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitials()

    msg.SwiftProtoTesting_Names_Uppers_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_http)
    msg.clearSwiftProtoTesting_Names_Uppers_http()

    msg.SwiftProtoTesting_Names_Uppers_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_httpRequest)
    msg.clearSwiftProtoTesting_Names_Uppers_httpRequest()

    msg.SwiftProtoTesting_Names_Uppers_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_Uppers_theHTTPRequest()

    msg.SwiftProtoTesting_Names_Uppers_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theHTTP)
    msg.clearSwiftProtoTesting_Names_Uppers_theHTTP()

    msg.SwiftProtoTesting_Names_Uppers_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_https)
    msg.clearSwiftProtoTesting_Names_Uppers_https()

    msg.SwiftProtoTesting_Names_Uppers_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_httpsRequest)
    msg.clearSwiftProtoTesting_Names_Uppers_httpsRequest()

    msg.SwiftProtoTesting_Names_Uppers_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_Uppers_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_Uppers_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theHTTPS)
    msg.clearSwiftProtoTesting_Names_Uppers_theHTTPS()

    msg.SwiftProtoTesting_Names_Uppers_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_url)
    msg.clearSwiftProtoTesting_Names_Uppers_url()

    msg.SwiftProtoTesting_Names_Uppers_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_urlValue)
    msg.clearSwiftProtoTesting_Names_Uppers_urlValue()

    msg.SwiftProtoTesting_Names_Uppers_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theURLValue)
    msg.clearSwiftProtoTesting_Names_Uppers_theURLValue()

    msg.SwiftProtoTesting_Names_Uppers_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theURL)
    msg.clearSwiftProtoTesting_Names_Uppers_theURL()

    msg.SwiftProtoTesting_Names_Uppers_id = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_id)
    msg.clearSwiftProtoTesting_Names_Uppers_id()

    msg.SwiftProtoTesting_Names_Uppers_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_idNumber)
    msg.clearSwiftProtoTesting_Names_Uppers_idNumber()

    msg.SwiftProtoTesting_Names_Uppers_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_theIDNumber)
    msg.clearSwiftProtoTesting_Names_Uppers_theIDNumber()

    msg.SwiftProtoTesting_Names_Uppers_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_Uppers_requestID)
    msg.clearSwiftProtoTesting_Names_Uppers_requestID()
  }

  func testWordCase() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitials()

    msg.SwiftProtoTesting_Names_WordCase_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_http)
    msg.clearSwiftProtoTesting_Names_WordCase_http()

    msg.SwiftProtoTesting_Names_WordCase_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_httpRequest)
    msg.clearSwiftProtoTesting_Names_WordCase_httpRequest()

    msg.SwiftProtoTesting_Names_WordCase_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_WordCase_theHTTPRequest()

    msg.SwiftProtoTesting_Names_WordCase_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theHTTP)
    msg.clearSwiftProtoTesting_Names_WordCase_theHTTP()

    msg.SwiftProtoTesting_Names_WordCase_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_https)
    msg.clearSwiftProtoTesting_Names_WordCase_https()

    msg.SwiftProtoTesting_Names_WordCase_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_httpsRequest)
    msg.clearSwiftProtoTesting_Names_WordCase_httpsRequest()

    msg.SwiftProtoTesting_Names_WordCase_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_WordCase_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_WordCase_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theHTTPS)
    msg.clearSwiftProtoTesting_Names_WordCase_theHTTPS()

    msg.SwiftProtoTesting_Names_WordCase_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_url)
    msg.clearSwiftProtoTesting_Names_WordCase_url()

    msg.SwiftProtoTesting_Names_WordCase_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_urlValue)
    msg.clearSwiftProtoTesting_Names_WordCase_urlValue()

    msg.SwiftProtoTesting_Names_WordCase_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theURLValue)
    msg.clearSwiftProtoTesting_Names_WordCase_theURLValue()

    msg.SwiftProtoTesting_Names_WordCase_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theURL)
    msg.clearSwiftProtoTesting_Names_WordCase_theURL()

    msg.SwiftProtoTesting_Names_WordCase_id = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_id)
    msg.clearSwiftProtoTesting_Names_WordCase_id()

    msg.SwiftProtoTesting_Names_WordCase_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_idNumber)
    msg.clearSwiftProtoTesting_Names_WordCase_idNumber()

    msg.SwiftProtoTesting_Names_WordCase_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_theIDNumber)
    msg.clearSwiftProtoTesting_Names_WordCase_theIDNumber()

    msg.SwiftProtoTesting_Names_WordCase_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_WordCase_requestID)
    msg.clearSwiftProtoTesting_Names_WordCase_requestID()
  }
}

final class Test_ExtensionNamingInitials_GlobalScoped: XCTestCase {
  func testLowers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsLowers()

    msg.SwiftProtoTesting_Names_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_http)
    msg.clearSwiftProtoTesting_Names_http()

    msg.SwiftProtoTesting_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpRequest)
    msg.clearSwiftProtoTesting_Names_httpRequest()

    msg.SwiftProtoTesting_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPRequest()

    msg.SwiftProtoTesting_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTP)
    msg.clearSwiftProtoTesting_Names_theHTTP()

    msg.SwiftProtoTesting_Names_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_https)
    msg.clearSwiftProtoTesting_Names_https()

    msg.SwiftProtoTesting_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpsRequest)
    msg.clearSwiftProtoTesting_Names_httpsRequest()

    msg.SwiftProtoTesting_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPS)
    msg.clearSwiftProtoTesting_Names_theHTTPS()

    msg.SwiftProtoTesting_Names_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_url)
    msg.clearSwiftProtoTesting_Names_url()

    msg.SwiftProtoTesting_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_urlValue)
    msg.clearSwiftProtoTesting_Names_urlValue()

    msg.SwiftProtoTesting_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURLValue)
    msg.clearSwiftProtoTesting_Names_theURLValue()

    msg.SwiftProtoTesting_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURL)
    msg.clearSwiftProtoTesting_Names_theURL()

    msg.SwiftProtoTesting_Names_aBC = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_aBC)
    msg.clearSwiftProtoTesting_Names_aBC()

    msg.SwiftProtoTesting_Names_id = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_id)
    msg.clearSwiftProtoTesting_Names_id()

    msg.SwiftProtoTesting_Names_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_idNumber)
    msg.clearSwiftProtoTesting_Names_idNumber()

    msg.SwiftProtoTesting_Names_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theIDNumber)
    msg.clearSwiftProtoTesting_Names_theIDNumber()

    msg.SwiftProtoTesting_Names_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_requestID)
    msg.clearSwiftProtoTesting_Names_requestID()
  }

  func testUppers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsUppers()

    msg.SwiftProtoTesting_Names_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_http)
    msg.clearSwiftProtoTesting_Names_http()

    msg.SwiftProtoTesting_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpRequest)
    msg.clearSwiftProtoTesting_Names_httpRequest()

    msg.SwiftProtoTesting_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPRequest()

    msg.SwiftProtoTesting_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTP)
    msg.clearSwiftProtoTesting_Names_theHTTP()

    msg.SwiftProtoTesting_Names_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_https)
    msg.clearSwiftProtoTesting_Names_https()

    msg.SwiftProtoTesting_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpsRequest)
    msg.clearSwiftProtoTesting_Names_httpsRequest()

    msg.SwiftProtoTesting_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPS)
    msg.clearSwiftProtoTesting_Names_theHTTPS()

    msg.SwiftProtoTesting_Names_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_url)
    msg.clearSwiftProtoTesting_Names_url()

    msg.SwiftProtoTesting_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_urlValue)
    msg.clearSwiftProtoTesting_Names_urlValue()

    msg.SwiftProtoTesting_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURLValue)
    msg.clearSwiftProtoTesting_Names_theURLValue()

    msg.SwiftProtoTesting_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURL)
    msg.clearSwiftProtoTesting_Names_theURL()

    msg.SwiftProtoTesting_Names_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_idNumber)
    msg.clearSwiftProtoTesting_Names_idNumber()

    msg.SwiftProtoTesting_Names_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theIDNumber)
    msg.clearSwiftProtoTesting_Names_theIDNumber()

    msg.SwiftProtoTesting_Names_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_requestID)
    msg.clearSwiftProtoTesting_Names_requestID()
  }

  func testWordCase() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsWordCase()

    msg.SwiftProtoTesting_Names_http = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_http)
    msg.clearSwiftProtoTesting_Names_http()

    msg.SwiftProtoTesting_Names_httpRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpRequest)
    msg.clearSwiftProtoTesting_Names_httpRequest()

    msg.SwiftProtoTesting_Names_theHTTPRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPRequest()

    msg.SwiftProtoTesting_Names_theHTTP = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTP)
    msg.clearSwiftProtoTesting_Names_theHTTP()

    msg.SwiftProtoTesting_Names_https = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_https)
    msg.clearSwiftProtoTesting_Names_https()

    msg.SwiftProtoTesting_Names_httpsRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_httpsRequest)
    msg.clearSwiftProtoTesting_Names_httpsRequest()

    msg.SwiftProtoTesting_Names_theHTTPSRequest = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPSRequest)
    msg.clearSwiftProtoTesting_Names_theHTTPSRequest()

    msg.SwiftProtoTesting_Names_theHTTPS = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theHTTPS)
    msg.clearSwiftProtoTesting_Names_theHTTPS()

    msg.SwiftProtoTesting_Names_url = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_url)
    msg.clearSwiftProtoTesting_Names_url()

    msg.SwiftProtoTesting_Names_urlValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_urlValue)
    msg.clearSwiftProtoTesting_Names_urlValue()

    msg.SwiftProtoTesting_Names_theURLValue = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURLValue)
    msg.clearSwiftProtoTesting_Names_theURLValue()

    msg.SwiftProtoTesting_Names_theURL = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theURL)
    msg.clearSwiftProtoTesting_Names_theURL()

    msg.SwiftProtoTesting_Names_idNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_idNumber)
    msg.clearSwiftProtoTesting_Names_idNumber()

    msg.SwiftProtoTesting_Names_theIDNumber = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_theIDNumber)
    msg.clearSwiftProtoTesting_Names_theIDNumber()

    msg.SwiftProtoTesting_Names_requestID = 1
    XCTAssertTrue(msg.hasSwiftProtoTesting_Names_requestID)
    msg.clearSwiftProtoTesting_Names_requestID()
  }
}

final class Test_ExtensionNamingInitials_GlobalScoped_NoPrefix: XCTestCase {
  func testLowers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsLowers()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }

  func testUppers() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsUppers()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }

  func testWordCase() {
    var msg = SwiftProtoTesting_Names_ExtensionNamingInitialsWordCase()

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

    msg.id = 1
    XCTAssertTrue(msg.hasID)
    msg.clearID()

    msg.idNumber = 1
    XCTAssertTrue(msg.hasIDNumber)
    msg.clearIDNumber()

    msg.theIDNumber = 1
    XCTAssertTrue(msg.hasTheIDNumber)
    msg.clearTheIDNumber()

    msg.requestID = 1
    XCTAssertTrue(msg.hasRequestID)
    msg.clearRequestID()
  }
}

final class Test_ValidIdentifiers: XCTestCase {
  func testFieldNames() {
    let msg = SwiftProtoTesting_Names_ValidIdentifiers()
    XCTAssertEqual(msg._1Field, 0)
    XCTAssertFalse(msg.has_1Field)
    XCTAssertEqual(msg.field, 0)
    XCTAssertFalse(msg.hasField)
    XCTAssertEqual(msg._3Field3, 0)
    XCTAssertFalse(msg.has_3Field3)
  }

  func testOneofNames() {
    var msg = SwiftProtoTesting_Names_ValidIdentifiers()
    XCTAssertEqual(msg._2Of, nil)

    XCTAssertEqual(msg._4, 0)
    XCTAssertEqual(msg._5Field, 0)

    msg._2Of = ._4(20)

    XCTAssertEqual(msg._2Of, SwiftProtoTesting_Names_ValidIdentifiers.OneOf__2Of._4(20))
    XCTAssertEqual(msg._4, 20)
  }

  func testEnumCaseNames() {
    var msg = SwiftProtoTesting_Names_ValidIdentifiers()
    msg.enumField = .testEnum0
    msg.enumField = .first
    msg.enumField = ._2
    msg.enumField = ._3Value
  }
}
