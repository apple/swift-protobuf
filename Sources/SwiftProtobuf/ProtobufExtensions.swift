// ProtobufRuntime/Sources/Protobuf/ProtobufExtensions.swift - Extension support
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
/// A 'Message Extension' is an immutable class object that describes
/// a particular extension field, including string and number
/// identifiers, serialization details, and the identity of the
/// message that is being extended.
///
// -----------------------------------------------------------------------------

import Swift

/// Note that the base ProtobufMessageExtension class has no generic
/// pieces, which allows us to construct dictionaries of
/// ProtobufMessageExtension-typed objects.
public class ProtobufMessageExtension {
    public let protoFieldNumber: Int
    public let protoFieldName: String
    public let jsonFieldName: String
    public let swiftFieldName: String
    public let messageType: ProtobufMessage.Type
    init(protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String, messageType: ProtobufMessage.Type) {
        self.protoFieldNumber = protoFieldNumber
        self.protoFieldName = protoFieldName
        self.jsonFieldName = jsonFieldName
        self.swiftFieldName = swiftFieldName
        self.messageType = messageType
    }
    public func newField() -> ProtobufExtensionField {
        fatalError("newField() -> ProtobufExtensionField must always be overridden.")
    }
}

public func ==(lhs: ProtobufMessageExtension, rhs: ProtobufMessageExtension) -> Bool {
    return lhs.protoFieldNumber == rhs.protoFieldNumber
}

/// A "Generic Message Extension" augments the base Extension type
/// with generic information about the type of the message being
/// extended.  These generic constrints enable compile-time checks on
/// compatibility.
public class ProtobufGenericMessageExtension<FieldType: ProtobufTypedExtensionField, MessageType: ProtobufMessage>: ProtobufMessageExtension {
    public init(protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String, defaultValue: FieldType.ValueType) {
        self.defaultValue = defaultValue
        super.init(protoFieldNumber: protoFieldNumber, protoFieldName: protoFieldName, jsonFieldName: jsonFieldName, swiftFieldName: swiftFieldName, messageType: MessageType.self)
    }
    public let defaultValue: FieldType.ValueType
    public func set(value: FieldType.ValueType) -> ProtobufExtensionField {
        var f = FieldType(protobufExtension: self)
        f.value = value
        return f
    }
    override public func newField() -> ProtobufExtensionField {
        return FieldType(protobufExtension: self)
    }
}

// Messages that support extensions implement this protocol
public protocol ProtobufExtensibleMessage: ProtobufMessage {
    mutating func setExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, Self>, value: F.ValueType)
    mutating func getExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, Self>) -> F.ValueType
}

// Backwards compatibility shim:  Remove in August 2016
public typealias ProtobufExtensibleMessageType = ProtobufExtensibleMessage

// Common support for storage classes to handle extension fields
public protocol ProtobufExtensibleMessageStorage: class {
    associatedtype ProtobufExtendedMessage: ProtobufMessage
    var extensionFieldValues: ProtobufExtensionFieldValueSet {get set}
    func setExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, ProtobufExtendedMessage>, value: F.ValueType)
    func getExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, ProtobufExtendedMessage>) -> F.ValueType
}

// Backwards compatibility shim:  Remove in August 2016
public typealias ProtobufExtensibleMessageStorageType = ProtobufExtensibleMessageStorage

public extension ProtobufExtensibleMessageStorage {
    public func setExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, ProtobufExtendedMessage>, value: F.ValueType) {
        extensionFieldValues[ext.protoFieldNumber] = ext.set(value: value)
    }

    public func getExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, ProtobufExtendedMessage>) -> F.ValueType {
        if let fieldValue = extensionFieldValues[ext.protoFieldNumber] as? F {
            return fieldValue.value
        }
        return ext.defaultValue
    }
}

///
/// A set of extensions that can be passed into deserializers
/// to provide details of the particular extensions that should
/// be recognized.
///

// TODO: Make this more Set-like
// Note: The generated code only relies on ExpressibleByArrayLiteral
public struct ProtobufExtensionSet: CustomDebugStringConvertible, ExpressibleByArrayLiteral {
    public typealias Element = ProtobufMessageExtension

    // Since type objects aren't Hashable, we can't do much better than this...
    private var fields = [Int: Array<(ProtobufMessage.Type, ProtobufMessageExtension)>]()

    public init() {}

    public init(arrayLiteral: Element...) {
        insert(contentsOf: arrayLiteral)
    }

    public subscript(messageType: ProtobufMessage.Type, protoFieldNumber: Int) -> ProtobufMessageExtension? {
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
                    pair -> (ProtobufMessage.Type, ProtobufMessageExtension)? in
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

    public func fieldNumberForJson(messageType: ProtobufJSONMessageBase.Type, jsonFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for (_, e) in list {
                if e.jsonFieldName == jsonFieldName {
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
                names.append("\(e.protoFieldName)(\(e.protoFieldNumber))")
            }
        }
        let d = names.joined(separator: ",")
        return "ProtobufExtensionSet(\(d))"
    }

    public mutating func union(_ other: ProtobufExtensionSet) -> ProtobufExtensionSet {
        var out = self
        for (_, list) in other.fields {
            for (_, e) in list {
                out.insert(e)
            }
        }
        return out
    }
}

/// A collection of extension field values on a particular object.
/// This is only used within messages to manage the values of extension fields;
/// it does not need to be very sophisticated.
public struct ProtobufExtensionFieldValueSet: Equatable, Sequence {
    public typealias Iterator = Dictionary<Int, ProtobufExtensionField>.Iterator
    fileprivate var values = [Int : ProtobufExtensionField]()
    public init() {}

    public func makeIterator() -> Iterator {
        return values.makeIterator()
    }

    public var hashValue: Int {
        var hash: Int = 0
        for i in values.keys.sorted() {
            hash = (hash &* 16777619) ^ values[i]!.hashValue
        }
        return hash
    }

    public func traverse(visitor: inout ProtobufVisitor, start: Int, end: Int) throws {
         let validIndexes = values.keys.filter {$0 >= start && $0 < end}
         for i in validIndexes.sorted() {
            let value = values[i]!
            try value.traverse(visitor: &visitor)
         }
    }

    public subscript(index: Int) -> ProtobufExtensionField? {
        get {return values[index]}
        set(newValue) {values[index] = newValue}
    }
}

public func ==(lhs: ProtobufExtensionFieldValueSet, rhs: ProtobufExtensionFieldValueSet) -> Bool {
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
    for (index, _) in rhs.values {
        if lhs.values[index] == nil {
            return false
        }
    }
    return true
}
