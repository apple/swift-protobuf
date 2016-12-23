// Sources/PluginLibrary/ProtoLanguage.swift - Proto language utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Utility functions for dealing with proto language syntax
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

/// Tests whether a string represents a valid identifier in a
/// proto schema file.  This is based on the proto language grammar
/// at:
///
/// https://developers.google.com/protocol-buffers/docs/reference/proto3-spec
///
/// (Note that proto2 and proto3 have exactly the same grammar
/// productions for identifiers.)
///
public func isValidProtobufIdentifier(_ s: String) -> Bool {
    var i = s.characters.makeIterator()
    if let first = i.next() {
        switch first {
        case "a"..."z", "A"..."Z", "_":
            break
        default:
            return false
        }
        while let c = i.next() {
            switch c {
            case "0"..."9":
                break
            case "a"..."z", "A"..."Z", "_":
                break
            default:
                return false
            }
        }
        return true
    }
    return false
}
