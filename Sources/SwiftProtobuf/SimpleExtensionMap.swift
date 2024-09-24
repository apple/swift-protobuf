// Sources/SwiftProtobuf/SimpleExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A default implementation of ExtensionMap.
///
// -----------------------------------------------------------------------------

// Note: The generated code only relies on ExpressibleByArrayLiteral
public struct SimpleExtensionMap: ExtensionMap, ExpressibleByArrayLiteral {
    public typealias Element = AnyMessageExtension

    // Since type objects aren't Hashable, we can't do much better than this...
    internal var fields = [Int: [any AnyMessageExtension]]()

    public init() {}

    public init(arrayLiteral: any Element...) {
        insert(contentsOf: arrayLiteral)
    }

    public init(_ others: SimpleExtensionMap...) {
        for other in others {
            formUnion(other)
        }
    }

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

    public mutating func insert(contentsOf: [any Element]) {
        for e in contentsOf {
            insert(e)
        }
    }

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

    public func union(_ other: SimpleExtensionMap) -> SimpleExtensionMap {
        var out = self
        out.formUnion(other)
        return out
    }

}

extension SimpleExtensionMap: CustomDebugStringConvertible {
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
