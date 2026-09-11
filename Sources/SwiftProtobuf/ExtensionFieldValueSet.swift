// Sources/SwiftProtobuf/ExtensionFieldValueSet.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// A collection of extension field values on a particular object.
//
// Generated messages use this only to manage the values of extension fields;
// it does not need to be very sophisticated.
//
// -----------------------------------------------------------------------------

/// A collection that holds the decoded values of a message's proto2 extension fields, keyed by
/// field number.
public struct ExtensionFieldValueSet: Hashable, Sendable {
    fileprivate var values = [Int: any AnyExtensionField]()

    /// Returns a Boolean value that indicates whether two extension field value sets hold the same
    /// field numbers with equal values.
    public static func == (
        lhs: ExtensionFieldValueSet,
        rhs: ExtensionFieldValueSet
    ) -> Bool {
        guard lhs.values.count == rhs.values.count else {
            return false
        }
        for (index, l) in lhs.values {
            if let r = rhs.values[index] {
                if type(of: l) != type(of: r) {
                    return false
                }
                if !l.isEqual(other: r) {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }

    /// Creates an empty extension field value set.
    public init() {}

    /// A hash based on this set's field numbers and values, kept consistent with this type's
    /// equality.
    ///
    /// The hash mixes each field's contribution together independent of storage order, since
    /// dictionary iteration order isn't stable.
    public func hash(into hasher: inout Hasher) {
        // AnyExtensionField is not Hashable, and the Self constraint that would
        // add breaks some of the uses of it; so the only choice is to manually
        // mix things in. However, one must remember to do things in an order
        // independent manner.
        var hash = 16_777_619
        for (fieldNumber, v) in values {
            var localHasher = hasher
            localHasher.combine(fieldNumber)
            v.hash(into: &localHasher)
            hash = hash &+ localHasher.finalize()
        }
        hasher.combine(hash)
    }

    /// Visits the values of the extension fields whose field numbers fall within the range you
    /// provide, in field-number order.
    public func traverse<V: Visitor>(visitor: inout V, start: Int, end: Int) throws {
        let validIndexes = values.keys.filter { $0 >= start && $0 < end }
        for i in validIndexes.sorted() {
            let value = values[i]!
            try value.traverse(visitor: &visitor)
        }
    }

    /// Accesses the extension field value stored at the field number you provide.
    public subscript(index: Int) -> (any AnyExtensionField)? {
        get { values[index] }
        set { values[index] = newValue }
    }

    mutating func modify<ReturnType>(
        index: Int,
        _ modifier: (inout (any AnyExtensionField)?) throws -> ReturnType
    ) rethrows -> ReturnType {
        // This internal helper exists to invoke the _modify accessor on Dictionary for the given operation, which can avoid CoWs
        // during the modification operation.
        try modifier(&values[index])
    }

    /// A Boolean value that indicates whether every proto2 required field in this set's extension
    /// values has a value set.
    ///
    /// This check recurses into any nested messages held by the extension values.
    public var isInitialized: Bool {
        for (_, v) in values {
            if !v.isInitialized {
                return false
            }
        }
        return true
    }
}
