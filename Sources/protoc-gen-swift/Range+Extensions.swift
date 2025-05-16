// Sources/protoc-gen-swift/Range+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Range` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

extension Range where Bound == Int32 {

    /// A `String` containing the Swift expression that represents this range to
    /// be used in a `case` statement.
    var swiftCaseExpression: String {
        if lowerBound == upperBound - 1 {
            return "\(lowerBound)"
        }
        return "\(lowerBound)..<\(upperBound)"
    }

    /// A `String` containing the Swift Boolean expression that tests the given
    /// variable for containment within this range.
    ///
    /// - Parameter variable: The name of the variable to test in the expression.
    /// - Returns: A `String` containing the Boolean expression.
    func swiftBooleanExpression(variable: String) -> String {
        if lowerBound == upperBound - 1 {
            return "\(lowerBound) == \(variable)"
        }
        return "\(lowerBound) <= \(variable) && \(variable) < \(upperBound)"
    }

}

extension Array where Element == Range<Int32> {

    /// A `String` containing a comma-delimited list of Swift expressions for
    /// the ranges.
    ///
    /// This expression list is suitable as a pattern match in a `case`
    /// statement. For example, `"case 5..<10, 15, 20..<30:"`.
    ///
    /// - Returns: A `String` containing the comma-delimited expressions.
    var swiftCaseExpression: String {
        map { $0.swiftCaseExpression }.joined(separator: ", ")
    }

    /// A `String` containing a Swift Boolean expression that tests if the given
    /// variable is in any of ranges.
    ///
    /// - Parameter variable: The name of the variable to test in the expression.
    /// - Returns: A `String` containing the Boolean expression.
    func swiftBooleanExpression(variable: String) -> String {
        map {
            "(\($0.swiftBooleanExpression(variable: variable)))"
        }.joined(separator: " || ")
    }

    /// Helper tha will take an array of Ranges and sort them and then merge any that are
    /// continuous (i.e. - [(21,30),(10,20)] -> [(10,30)])
    func sortAndMergeContinuous() -> [Range<Int32>] {
        var ordered = self.sorted(by: { $0.lowerBound < $1.lowerBound })
        if ordered.count > 1 {
            for i in (0..<(ordered.count - 1)).reversed() {
                if ordered[i].upperBound == ordered[i + 1].lowerBound {
                    ordered[i] = ordered[i].lowerBound..<ordered[i + 1].upperBound
                    ordered.remove(at: i + 1)
                }
            }
        }
        return ordered
    }
}
