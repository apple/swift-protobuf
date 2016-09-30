// ProtobufRuntime/Sources/Protobuf/ProtobufGroup.swift - Group support
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
/// These are the core protocols that are implemented by generated group types.
///
// -----------------------------------------------------------------------------

import Swift

///
/// Generated Groups conform to ProtobufGroup
///
public protocol ProtobufGroupBase: CustomDebugStringConvertible, ProtobufTraversable {
    init()

    mutating func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool

    mutating func decodeFromJSONObject(jsonDecoder: inout ProtobufJSONDecoder) throws

    var swiftClassName: String { get }
}

public extension ProtobufGroupBase {
    var hashValue: Int {
        return ProtobufHashVisitor(group: self).hashValue
    }
    var debugDescription: String {
        return ProtobufDebugDescriptionVisitor(group: self).description
    }
}

public protocol ProtobufGroup: ProtobufGroupBase, Hashable {
    func isEqualTo(other: Self) -> Bool
    var jsonFieldNames: [String: Int] {get}
    var protoFieldNames: [String: Int] {get}
}

public func ==<G: ProtobufGroup>(lhs: G, rhs: G) -> Bool {
    return lhs.isEqualTo(other: rhs)
}

public protocol ProtobufGeneratedGroup: ProtobufGroup {
    // The compiler actually generates the following methods.
    // Default implementations below redirect the standard names.
    // This allows developers to override the standard names to
    // customize the behavior.
    mutating func _protoc_generated_decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool
    func _protoc_generated_traverse(visitor: inout ProtobufVisitor) throws
    func _protoc_generated_isEqualTo(other: Self) -> Bool
}

public extension ProtobufGeneratedGroup {
    // Default implementations simply redirect to the generated versions.
    func traverse(visitor: inout ProtobufVisitor) throws {
        try _protoc_generated_traverse(visitor: &visitor)
    }

    mutating func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {
        return try _protoc_generated_decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)
    }

    func isEqualTo(other: Self) -> Bool {
        return _protoc_generated_isEqualTo(other: other)
    }
}

// TODO: This is a transition aid, remove this in August 2016.
public typealias ProtobufGeneratedGroupType = ProtobufGeneratedGroup
