// Sources/protoc-gen-swift/Google_Protobuf_EnumDescriptorProto+Extensions.swift - Enum descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `EnumDescriptorProto` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_EnumDescriptorProto {
    var stripPrefixLength: Int {
        let enumName = toUpperCamelCase(name).uppercased()
        for f in value {
            let fieldName = toUpperCamelCase(f.name).uppercased()
#if os(Linux)
            let enumChars = [Character](enumName.characters)
            let fieldChars = [Character](fieldName.characters)
            if fieldChars.count <= enumChars.count {
                return 0
            }
            let fieldPrefix = fieldChars[0..<enumChars.count]
            let fieldPrefixString = String(fieldPrefix)
            if fieldPrefixString != enumName {
                return 0
            }
#else
            if enumName.commonPrefix(with: fieldName) != enumName {
                return 0
            }
#endif
            if !isValidSwiftIdentifier(f.getSwiftBareName(stripLength: enumName.characters.count)) {
                return 0
            }
        }
        return enumName.characters.count
    }

    func getSwiftNameForEnumCase(caseName: String) -> String {
        let stripLength = stripPrefixLength
        for f in value {
            if f.name == caseName {
                return f.getSwiftName(stripLength: stripLength)
            }
        }
        fatalError("Cannot find case `\(caseName)` in enum \(name)")
    }
}
