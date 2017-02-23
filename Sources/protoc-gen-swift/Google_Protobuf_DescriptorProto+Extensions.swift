// Sources/protoc-gen-swift/Google_Protobuf_DescriptorProto+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `DescriptorProto` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_DescriptorProto {
    func getMessageForPath(path: String, parentPath: String) -> Google_Protobuf_DescriptorProto? {
        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            if messagePath == path {
                return m
            }
            if let n = m.getMessageForPath(path: path, parentPath: messagePath) {
                return n
            }
        }
        return nil
    }

    func getMessageNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
            if messagePath == path {
                return messageSwiftPath
            }
            if let n = m.getMessageNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getEnumNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
        for e in enumType {
            let enumPath = parentPath + "." + e.name
            if enumPath == path {
                return swiftPrefix + "." + sanitizeEnumTypeName(e.name)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
            if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String, parentPath: String, swiftPrefix: String) -> String? {
        for e in enumType {
            let enumPath = parentPath + "." + e.name
            if enumPath == path {
                let enumSwiftName = swiftPrefix + "." + sanitizeEnumTypeName(e.name)
                return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
            if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }
}
