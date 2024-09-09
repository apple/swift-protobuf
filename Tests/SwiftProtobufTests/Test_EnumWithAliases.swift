// Tests/SwiftProtobufTests/Test_EnumWithAliases.swift - Exercise generated enums
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that proto enums are properly translated into Swift enums.  Among
/// other things, enums can have duplicate tags, the names should be correctly
/// translated into Swift lowerCamelCase conventions, etc.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

final class Test_EnumWithAliases: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Enum2_SwiftEnumWithAliasTest

    func testJSONEncodeUsesOriginalNames() {
        assertJSONEncode("{\"values\":[\"FOO1\",\"BAR1\"]}") { (m: inout MessageTestType) in
            m.values = [.foo1, .bar1]
        }

        assertJSONEncode("{\"values\":[\"FOO1\",\"BAR1\"]}") { (m: inout MessageTestType) in
            m.values = [.foo2, .bar2]
        }
    }

    func testJSONDecodeAcceptsAllNames() throws {
        assertJSONDecodeSucceeds("{\"values\":[\"FOO1\",\"BAR1\"]}") { (m: MessageTestType) in
            m.values == [.foo1, .bar1]
        }

        assertJSONDecodeSucceeds("{\"values\":[\"FOO2\",\"BAR2\"]}") { (m: MessageTestType) in
            m.values == [.foo1, .bar1]
        }
    }

    func testTextFormatEncodeUsesOriginalNames() {
        assertTextFormatEncode("values: [FOO1, BAR1]\n") { (m: inout MessageTestType) in
            m.values = [.foo1, .bar1]
        }

        assertTextFormatEncode("values: [FOO1, BAR1]\n") { (m: inout MessageTestType) in
            m.values = [.foo2, .bar2]
        }
    }

    func testTextFormatDecodeAcceptsAllNames() throws {
        assertTextFormatDecodeSucceeds("values: [FOO1, BAR1]\n") { (m: MessageTestType) in
            m.values == [.foo1, .bar1]
        }

        assertTextFormatDecodeSucceeds("values: [FOO2, BAR2]\n") { (m: MessageTestType) in
            m.values == [.foo1, .bar1]
        }
    }
}
