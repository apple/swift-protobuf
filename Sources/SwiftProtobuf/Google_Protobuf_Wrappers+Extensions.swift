// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+Extensions.swift - Well-known wrapper type extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to the well-known types in wrapper.proto that customize the JSON
/// format of those messages and provide convenience initializers from literals.
///
// -----------------------------------------------------------------------------

import Foundation

extension Google_Protobuf_DoubleValue: ExpressibleByFloatLiteral {
    public init(_ value: Double) {
        self.init()
        self.value = value
    }

    public init(floatLiteral: Double) {
        self.init(floatLiteral)
    }
}

extension Google_Protobuf_FloatValue: ExpressibleByFloatLiteral {
    public init(_ value: Float) {
        self.init()
        self.value = value
    }

    public init(floatLiteral: Float) {
        self.init(floatLiteral)
    }
}

extension Google_Protobuf_Int64Value: ExpressibleByIntegerLiteral {
    public init(_ value: Int64) {
        self.init()
        self.value = value
    }

    public init(integerLiteral: Int64) {
        self.init(integerLiteral)
    }
}

extension Google_Protobuf_UInt64Value: ExpressibleByIntegerLiteral {
    public init(_ value: UInt64) {
        self.init()
        self.value = value
    }

    public init(integerLiteral: UInt64) {
        self.init(integerLiteral)
    }
}

extension Google_Protobuf_Int32Value: ExpressibleByIntegerLiteral {

    public init(_ value: Int32) {
        self.init()
        self.value = value
    }

    public init(integerLiteral: Int32) {
        self.init(integerLiteral)
    }
}

extension Google_Protobuf_UInt32Value: ExpressibleByIntegerLiteral {
    public init(_ value: UInt32) {
        self.init()
        self.value = value
    }

    public init(integerLiteral: UInt32) {
        self.init(integerLiteral)
    }
}

extension Google_Protobuf_BoolValue: ExpressibleByBooleanLiteral {
    public init(_ value: Bool) {
        self.init()
        self.value = value
    }

    public init(booleanLiteral: Bool) {
        self.init(booleanLiteral)
    }
}

extension Google_Protobuf_StringValue: ExpressibleByStringLiteral {
    public init(_ value: String) {
        self.init()
        self.value = value
    }

    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }

    public init(extendedGraphemeClusterLiteral: String) {
        self.init(extendedGraphemeClusterLiteral)
    }

    public init(unicodeScalarLiteral: String) {
        self.init(unicodeScalarLiteral)
    }
}

extension Google_Protobuf_BytesValue {
    public init(_ value: Data) {
        self.init()
        self.value = value
    }
}
