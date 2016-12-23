// Sources/SwiftProtobuf/ExtensionSet.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A set of extensions that can be passed into deserializers
/// to provide details of the particular extensions that should
/// be recognized.
///
// -----------------------------------------------------------------------------

import Swift

// TODO: Make this more Set-like
// Note: The generated code only relies on ExpressibleByArrayLiteral
public struct ExtensionSet: CustomDebugStringConvertible, ExpressibleByArrayLiteral {
    public typealias Element = MessageExtensionBase
    
    // Since type objects aren't Hashable, we can't do much better than this...
    private var fields = [Int: Array<(Message.Type, MessageExtensionBase)>]()
    
    public init() {}
    
    public init(arrayLiteral: Element...) {
        insert(contentsOf: arrayLiteral)
    }
    
    public subscript(messageType: Message.Type, protoFieldNumber: Int) -> MessageExtensionBase? {
        get {
            if let l = fields[protoFieldNumber] {
                for (t, e) in l {
                    if t == messageType {
                        return e
                    }
                }
            }
            return nil
        }
        set(newValue) {
            if let l = fields[protoFieldNumber] {
                var newL = l.flatMap {
                    pair -> (Message.Type, MessageExtensionBase)? in
                    if pair.0 == messageType { return nil }
                    else { return pair }
                }
                if let newValue = newValue {
                    newL.append((messageType, newValue))
                    fields[protoFieldNumber] = newL
                }
                fields[protoFieldNumber] = newL
            } else if let newValue = newValue {
                fields[protoFieldNumber] = [(messageType, newValue)]
            }
        }
    }

    public func fieldNumberForJson(messageType: Message.Type, jsonFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for (_, e) in list {
                if e.fieldNames.jsonName == jsonFieldName {
                    return e.protoFieldNumber
                }
            }
        }
        return nil
    }

    public func fieldNumberForProto(messageType: Message.Type, protoFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for (_, e) in list {
                if e.fieldNames.protoName == protoFieldName {
                    return e.protoFieldNumber
                }
            }
        }
        return nil
    }

    public mutating func insert(_ e: Element) {
        self[e.messageType, e.protoFieldNumber] = e
    }

    public mutating func insert(contentsOf: [Element]) {
        for e in contentsOf {
            insert(e)
        }
    }

    public var debugDescription: String {
        var names = [String]()
        for (_, list) in fields {
            for (_, e) in list {
                names.append("\(e.fieldNames.protoName)(\(e.protoFieldNumber))")
            }
        }
        let d = names.joined(separator: ",")
        return "ExtensionSet(\(d))"
    }

    public mutating func union(_ other: ExtensionSet) -> ExtensionSet {
        var out = self
        for (_, list) in other.fields {
            for (_, e) in list {
                out.insert(e)
            }
        }
        return out
    }
}
