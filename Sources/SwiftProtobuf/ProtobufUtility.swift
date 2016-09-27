// ProtobufRuntime/Sources/Protobuf/ProtobufUtility.swift - Utility methods
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// In Swift 3, the standard library does not include == or != for [UInt8],
/// so we define these utilities.
///
// -----------------------------------------------------------------------------

import Swift

public func ==(lhs: [[UInt8]], rhs: [[UInt8]]) -> Bool {
    guard lhs.count == rhs.count else {return false}
    for (l,r) in zip(lhs, rhs) {
        if l != r {
            return false
        }
    }
    return true
}

public func !=(lhs: [[UInt8]], rhs: [[UInt8]]) -> Bool {
    return !(lhs == rhs)
}

public func ==<T: Equatable>(lhs: Dictionary<T, [UInt8]>, rhs: Dictionary<T, [UInt8]>) -> Bool {
    guard lhs.count == rhs.count else {return false}
    for (k,v) in lhs {
        let rv = rhs[k]
        if rv == nil || rv! != v {
            return false
        }
    }
    return true
}

public func !=<T: Equatable>(lhs: Dictionary<T, [UInt8]>, rhs: Dictionary<T, [UInt8]>) -> Bool {
    return !(lhs == rhs)
}
