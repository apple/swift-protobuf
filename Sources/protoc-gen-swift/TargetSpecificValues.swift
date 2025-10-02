// Sources/protoc-gen-swift/PointerWidthPair.swift - A pair of values based on pointer width
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Bundles values together based on pointer widths of target platforms not yet
/// known at generation time.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary

/// Manages a set of values that represent a single concept but may need to vary based on properties
/// of the target platform, such as byte sizes or encoding strings.
///
/// This type currently assumes that the only axis upon which values will differ is the bit-width
/// of the target's pointers. However, we design this type to be more generalizable so that
/// unforeseen situations can be handled in the future without refactoring large usage sites.
struct TargetSpecificValues<Element> {
    /// The value to use when targeting platforms with 64-bit pointers.
    var values: [TargetSpecificValueChoice: Element]

    /// Creates a new set of target-specific values from the given dictionary.
    ///
    /// Precondition: There must be a value provided for each `TargetSpecificValueChoice`.
    init(_ values: [TargetSpecificValueChoice: Element]) {
        precondition(
            values.count == TargetSpecificValueChoice.allCases.count,
            "At least one TargetSpecificValueChoice was not provided"
        )
        self.values = values
    }

    /// Creates a new set of target-specific values that uses the given value for all targets.
    init(forAllTargets value: Element) {
        self.init(Dictionary(uniqueKeysWithValues: TargetSpecificValueChoice.allCases.map { ($0, value) }))
    }
}

/// Represents the supported target platforms for `TargetSpecificValues`.
enum TargetSpecificValueChoice: CaseIterable {
    /// The value for platforms that use 64-bit pointers.
    case pointerWidth64

    /// The value for platforms that use 32-bit pointers.
    case pointerWidth32

    /// The compiler condition that corresponds to this value choice.
    var compilerCondition: String {
        switch self {
        case .pointerWidth64: return "_pointerBitWidth(_64)"
        case .pointerWidth32: return "_pointerBitWidth(_32)"
        }
    }
}

extension TargetSpecificValues {
    /// Gets or sets the element in the set that corresponds to the given target platform.
    subscript(choice: TargetSpecificValueChoice) -> Element {
        get { values[choice]! }
        set { values[choice] = newValue }
    }

    /// Returns a new target-specific values set by taking the elements of the receiver and
    /// transforming them using the given function.
    func map<Result>(_ transform: (Element) throws -> Result) rethrows -> TargetSpecificValues<Result> {
        .init(try values.mapValues(transform))
    }

    /// Calls the given function for each of the target-specific valeus, allowing them to be
    /// transformed in-place.
    ///
    /// In addition to the element itself, the function is also passed the target choice whose
    /// value is currently being transformed, so that the caller can use this information (for
    /// example, to reference the correct element in related target-specific values).
    mutating func modify(_ body: (inout Element, TargetSpecificValueChoice) throws -> Void) rethrows {
        for choice in TargetSpecificValueChoice.allCases {
            try body(&self[choice], choice)
        }
    }

    /// Prints a sequence of compiler conditional blocks (`#if ... #elseif ... #endif`) for the
    /// values in this set.
    ///
    /// - Parameters:
    ///   - printer: The `CodePrinter` to which the code will be written.
    ///   - body: A function that will be called once per value in the set and which should print
    ///     the body of a single condition branch. It takes three arguments: the element to be
    ///     printed in the current branch, the choice corresponding to that element (to access
    ///     related value sets if necessary), and the `CodePrinter` for the function to write to.
    func printConditionalBlocks(
        to printer: inout CodePrinter,
        body: (Element, TargetSpecificValueChoice, inout CodePrinter) -> Void
    ) {
        for (index, choice) in TargetSpecificValueChoice.allCases.enumerated() {
            let conditionStatement = (index == 0) ? "#if" : "#elseif"
            printer.print("\(conditionStatement) \(choice.compilerCondition)")
            printer.withIndentation { printer in
                body(self[choice], choice, &printer)
            }
        }
        printer.print("#else")
        printer.printIndented(#"#error("Unsupported platform")"#)
        printer.print("#endif")
    }
}

extension TargetSpecificValues where Element: Equatable {
    /// Returns the common value if the value for every choice is the same, or `nil` if any of the
    /// choices differ.
    var valueIfAllEqual: Element? {
        // The initializer ensures that all choices are present.
        let first = values.values.first!
        for next in values.values.dropFirst() {
            guard next == first else {
                return nil
            }
        }
        return first
    }
}

extension TargetSpecificValues<Int> {
    /// Adds the given values to the pair.
    mutating func add(_ size: Self) {
        modify { $0 += size[$1] }
    }

    /// Adds the necessary values to each element in the pair that cause it to align to the given
    /// byte widths.
    mutating func align(to size: Self) {
        modify {
            let misalignmentFor64 = $0 % size[$1]
            if misalignmentFor64 != 0 {
                $0 += size[$1] - misalignmentFor64
            }
        }
    }
}
