// Sources/SwiftProtobuf/SimpleExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A default implementation of ExtensionMap.
///
// -----------------------------------------------------------------------------


// Note: The generated code only relies on ExpressibleByArrayLiteral
public struct SimpleExtensionMap: ExtensionMap, ExpressibleByArrayLiteral, CustomDebugStringConvertible {
    public typealias Element = MessageExtensionBase

    // Since type objects aren't Hashable, we can't do much better than this...
    private var fields = [Int: Array<(Message.Type, MessageExtensionBase)>]()

    public init() {}

    public init(arrayLiteral: Element...) {
        insert(contentsOf: arrayLiteral)
    }

    public subscript(messageType: Message.Type, fieldNumber: Int) -> MessageExtensionBase? {
        get {
            if let l = fields[fieldNumber] {
                for (t, e) in l {
                    if t == messageType {
                        return e
                    }
                }
            }
            return nil
        }
    }

    public func fieldNumberForProto(messageType: Message.Type, protoFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for (t, e) in list {
                let extensionName = e.fieldName.description
                if extensionName == protoFieldName && t == messageType {
                    return e.fieldNumber
                }
            }
        }
        return nil
    }

    public mutating func insert(_ newValue: Element) {
        let messageType = newValue.messageType
        let fieldNumber = newValue.fieldNumber
        if let l = fields[fieldNumber] {
            var newL = l.flatMap {
                pair -> (Message.Type, MessageExtensionBase)? in
                if pair.0 == messageType { return nil }
                else { return pair }
            }
            newL.append((messageType, newValue))
            fields[fieldNumber] = newL
        } else {
            fields[fieldNumber] = [(messageType, newValue)]
        }
    }

    public mutating func insert(contentsOf: [Element]) {
        for e in contentsOf {
            insert(e)
        }
    }

    public mutating func union(_ other: SimpleExtensionMap) -> SimpleExtensionMap {
        var out = self
        for (_, list) in other.fields {
            for (_, e) in list {
                out.insert(e)
            }
        }
        return out
    }

    public var debugDescription: String {
        var names = [String]()
        for (_, list) in fields {
            for (_, e) in list {
                let extensionName = e.fieldName
                names.append("\(extensionName)(\(e.fieldNumber))")
            }
        }
        let d = names.joined(separator: ",")
        return "SimpleExtensionMap(\(d))"
    }

}
