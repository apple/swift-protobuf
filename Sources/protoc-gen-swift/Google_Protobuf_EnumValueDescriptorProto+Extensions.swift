// Sources/protoc-gen-swift/Google_Protobuf_EnumValueDescriptorProto+Extensions.swift - Enum value descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `EnumValueDescriptorProto` that provide
/// Swift-generation-specific functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_EnumValueDescriptorProto {
    // Field numbers used to collect .proto file comments.
    struct FieldNumbers {
      static let number: Int32 = 2
    }

    func getSwiftName(stripLength: Int) -> String {
        return sanitizeEnumCase(getSwiftBareName(stripLength: stripLength))
    }

    func getSwiftBareName(stripLength: Int) -> String {
        let baseName = toLowerCamelCase(name)
        let swiftName: String
        if stripLength == 0 {
            swiftName = baseName
        } else {
            var c = [Character](baseName.characters)
            c.removeFirst(stripLength)
            if c == [] {
                return baseName
            }
            c[0] = Character(String(c[0]).lowercased())
            swiftName = String(c)
        }
        return swiftName
    }
}
