// Sources/SwiftProtobuf/SimpleExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// A default implementation of ExtensionMap.
//
// -----------------------------------------------------------------------------

// Note: The generated code only relies on ExpressibleByArrayLiteral

/// A basic, in-memory extension map that indexes extension descriptors by field number.
///
/// Within each field number, entries are further indexed by the message type the extension
/// applies to, since message types aren't `Hashable`.
public struct SimpleExtensionMap: ExtensionMap, ExpressibleByArrayLiteral {
    /// The type Swift uses when creating this map directly from an array literal of extension descriptors.
    public typealias Element = AnyMessageExtension

    // Since type objects aren't Hashable, we can't do much better than this...

    /// The extension descriptors this map holds, indexed by field number.
    ///
    /// Each field number maps to a list holding one entry per message type that declares an
    /// extension there.
    package var fields = [Int: [any AnyMessageExtension]]()

    /// Creates an empty extension map.
    public init() {}

    /// Creates a map from an array literal of extension descriptors.
    public init(arrayLiteral: any Element...) {
        insert(contentsOf: arrayLiteral)
    }

    /// Creates a map by combining every extension map you provide.
    public init(_ others: SimpleExtensionMap...) {
        for other in others {
            formUnion(other)
        }
    }

    /// Returns the extension descriptor registered for the field number on the message type you
    /// provide, or `nil` if none exists.
    public subscript(messageType: any Message.Type, fieldNumber: Int) -> (any AnyMessageExtension)? {
        get {
            if let l = fields[fieldNumber] {
                for e in l {
                    if messageType == e.messageType {
                        return e
                    }
                }
            }
            return nil
        }
    }

    /// Returns the field number of the extension with the proto field name and message type you
    /// provide, or `nil` if none exists.
    public func fieldNumberForProto(messageType: any Message.Type, protoFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for e in list {
                if e.fieldName == protoFieldName && e.messageType == messageType {
                    return e.fieldNumber
                }
            }
        }
        return nil
    }

    /// Inserts an extension descriptor into the map, replacing any existing entry with the same
    /// field number and message type.
    public mutating func insert(_ newValue: any Element) {
        let fieldNumber = newValue.fieldNumber
        if let l = fields[fieldNumber] {
            let messageType = newValue.messageType
            var newL = l.filter { $0.messageType != messageType }
            newL.append(newValue)
            fields[fieldNumber] = newL
        } else {
            fields[fieldNumber] = [newValue]
        }
    }

    /// Inserts every extension descriptor in the array you provide into the map.
    public mutating func insert(contentsOf: [any Element]) {
        for e in contentsOf {
            insert(e)
        }
    }

    /// Merges the extensions from another map into this map.
    ///
    /// Entries from the other map replace any of this map's own entries that share a field number
    /// and message type.
    public mutating func formUnion(_ other: SimpleExtensionMap) {
        for (fieldNumber, otherList) in other.fields {
            if let list = fields[fieldNumber] {
                var newList = list.filter {
                    for o in otherList {
                        if $0.messageType == o.messageType { return false }
                    }
                    return true
                }
                newList.append(contentsOf: otherList)
                fields[fieldNumber] = newList
            } else {
                fields[fieldNumber] = otherList
            }
        }
    }

    /// Returns a new map that combines this map's extensions with those from the map you provide.
    public func union(_ other: SimpleExtensionMap) -> SimpleExtensionMap {
        var out = self
        out.formUnion(other)
        return out
    }

}

extension SimpleExtensionMap: CustomDebugStringConvertible {
    /// A debug-build listing of this map's registered extension field names and numbers; outside
    /// of debug builds, a generic type description.
    public var debugDescription: String {
        #if DEBUG
        var names = [String]()
        for (_, list) in fields {
            for e in list {
                names.append("\(e.fieldName):(\(e.fieldNumber))")
            }
        }
        let d = names.joined(separator: ",")
        return "SimpleExtensionMap(\(d))"
        #else
        return String(reflecting: type(of: self))
        #endif
    }
}
