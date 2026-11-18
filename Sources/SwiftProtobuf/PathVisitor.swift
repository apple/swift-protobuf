// Sources/SwiftProtobuf/PathVisitor.swift - Path visitor
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor which captures a pair of paths and their values.
///
// -----------------------------------------------------------------------------

#if FieldMaskUtilities

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Flat-arena trie of canonicalized `FieldMask` paths (matching C++
/// `FieldMaskTree`). Each node stores only single path components so inserting,
/// deduplicating parent-covered paths, and pruning `PathVisitor` traversal run
/// in linear time and memory without recursive stack growth.
internal struct FieldMaskPathTree {
    internal enum Children {
        case none
        case single(Substring, Int)
        case multiple([Substring: Int])

        internal var isEmpty: Bool {
            if case .none = self {
                return true
            }
            return false
        }

        internal subscript(key: Substring) -> Int? {
            get {
                switch self {
                case .none:
                    return nil
                case .single(let existingKey, let index):
                    return existingKey == key ? index : nil
                case .multiple(let dict):
                    return dict[key]
                }
            }
            set {
                guard let newIndex = newValue else {
                    return
                }
                switch self {
                case .none:
                    self = .single(key, newIndex)
                case .single(let existingKey, let existingIndex):
                    if existingKey == key {
                        self = .single(key, newIndex)
                    } else {
                        self = .multiple([existingKey: existingIndex, key: newIndex])
                    }
                case .multiple(var dict):
                    self = .none
                    dict[key] = newIndex
                    self = .multiple(dict)
                }
            }
        }

        internal func forEachValue(_ body: (Int) -> Void) {
            switch self {
            case .none:
                break
            case .single(_, let index):
                body(index)
            case .multiple(let dict):
                for index in dict.values {
                    body(index)
                }
            }
        }
    }

    internal struct Node {
        internal var children: Children = .none
        internal var isLeaf = false
        internal var leafPath: String?
        internal var insertionOrder = 0
    }

    internal private(set) var nodes: [Node] = [Node()]
    private var nextOrder = 0

    internal init(
        paths: [String],
        rootHasField: (Substring) -> Bool
    ) {
        for path in paths {
            insert(path, rootHasField: rootHasField)
        }
    }

    private mutating func insert(
        _ path: String,
        rootHasField: (Substring) -> Bool
    ) {
        let firstDot = path.firstIndex(of: ".")
        let firstSegment = firstDot.map { path[..<$0] } ?? path[...]
        guard !firstSegment.isEmpty else {
            return
        }
        // Fast path: if the root field is already covered by a parent leaf,
        // avoid scanning the remainder of the path.
        if let existingRootChild = nodes[0].children[firstSegment],
            nodes[existingRootChild].isLeaf
        {
            return
        }
        // Reject paths whose first segment is not a field on the root message
        // before scanning or allocating nodes for deeper segments.
        guard rootHasField(firstSegment) else {
            return
        }
        if let firstDot {
            let remaining = path[path.index(after: firstDot)...]
            guard !hasEmptySegment(remaining) else {
                return
            }
        }

        var nodeIndex = 0
        var segmentStart = path.startIndex
        while true {
            if nodes[nodeIndex].isLeaf {
                return
            }
            let dotIndex = path[segmentStart...].firstIndex(of: ".")
            let segment = dotIndex.map { path[segmentStart..<$0] } ?? path[segmentStart...]
            if let existing = nodes[nodeIndex].children[segment] {
                nodeIndex = existing
            } else {
                let newIndex = nodes.count
                nodes.append(Node())
                nodes[nodeIndex].children[segment] = newIndex
                nodeIndex = newIndex
            }
            guard let dotIndex else {
                break
            }
            segmentStart = path.index(after: dotIndex)
        }
        if !nodes[nodeIndex].isLeaf {
            nodes[nodeIndex].isLeaf = true
            nodes[nodeIndex].leafPath = path
            nodes[nodeIndex].insertionOrder = nextOrder
            nextOrder += 1
            nodes[nodeIndex].children = .none
        }
    }

    internal func child(of nodeIndex: Int, named name: String) -> Int? {
        nodes[nodeIndex].children[name[...]]
    }

    /// Returns surviving canonical leaf paths (excluding duplicates and child
    /// paths covered by a parent path) in stable first-seen order, ensuring any
    /// sibling `"value"` leaf runs before `"type_url"` so overwriting both
    /// fields of a `Google_Protobuf_Any` replaces `state` before updating
    /// `type_url`.
    internal func canonicalLeaves() -> [(nodeIndex: Int, path: String)] {
        var leaves: [(nodeIndex: Int, path: String, order: Int)] = []
        var stack: [Int] = [0]
        while let current = stack.popLast() {
            let node = nodes[current]
            var swappedValueIndex: Int?
            var swappedTypeURLIndex: Int?
            var swappedValueOrder = 0
            var swappedTypeURLOrder = 0
            if let typeURLIdx = node.children["type_url"],
                let valueIdx = node.children["value"],
                nodes[typeURLIdx].isLeaf,
                nodes[valueIdx].isLeaf,
                nodes[typeURLIdx].insertionOrder < nodes[valueIdx].insertionOrder
            {
                swappedTypeURLIndex = typeURLIdx
                swappedValueIndex = valueIdx
                swappedValueOrder = nodes[typeURLIdx].insertionOrder
                swappedTypeURLOrder = nodes[valueIdx].insertionOrder
            }
            node.children.forEachValue { childIndex in
                let child = nodes[childIndex]
                if child.isLeaf, let path = child.leafPath {
                    let order: Int
                    if childIndex == swappedValueIndex {
                        order = swappedValueOrder
                    } else if childIndex == swappedTypeURLIndex {
                        order = swappedTypeURLOrder
                    } else {
                        order = child.insertionOrder
                    }
                    leaves.append((childIndex, path, order))
                } else {
                    stack.append(childIndex)
                }
            }
        }
        leaves.sort { $0.order < $1.order }
        return leaves.map { ($0.nodeIndex, $0.path) }
    }
}

private func hasEmptySegment(_ remainingPath: Substring) -> Bool {
    let utf8 = remainingPath.utf8
    guard !utf8.isEmpty else {
        return true
    }
    var prevWasDot = true
    for byte in utf8 {
        if byte == UInt8(ascii: ".") {
            if prevWasDot {
                return true
            }
            prevWasDot = true
        } else {
            prevWasDot = false
        }
    }
    return prevWasDot
}

/// Extracted binary payload for a `Google_Protobuf_Any` `"value"` sub-path,
/// carrying any decoded binary recursion budget so `setAnySubPath` preserves
/// `BinaryDecodingOptions.messageDepthLimit`.
internal struct AnyBinaryFieldValue {
    internal let data: Data
    internal let binaryRemainingDepth: Int?
}

// Visitor captures all values of message with their paths
struct PathVisitor<T: Message>: Visitor {

    // Canonicalized path trie used to prune traversal to masked paths only
    private let tree: FieldMaskPathTree

    // Current node index within `tree`
    private let nodeIndex: Int

    // Captured values keyed by canonical leaf node index in `tree`
    private(set) var values: [Int: Any] = [:]

    internal init(
        tree: FieldMaskPathTree,
        nodeIndex: Int = 0
    ) {
        self.tree = tree
        self.nodeIndex = nodeIndex
    }

    private mutating func visit(_ value: Any, fieldNumber: Int) {
        guard let name = T.name(for: fieldNumber),
            let childIndex = tree.child(of: nodeIndex, named: name),
            tree.nodes[childIndex].isLeaf
        else {
            return
        }
        values[childIndex] = value
    }

    private mutating func visitMessageField<M: Message>(
        _ value: M,
        fieldNumber: Int
    ) throws {
        guard let name = T.name(for: fieldNumber),
            let childIndex = tree.child(of: nodeIndex, named: name)
        else {
            return
        }
        let childNode = tree.nodes[childIndex]
        if childNode.isLeaf {
            values[childIndex] = value
            return
        }
        guard !childNode.children.isEmpty else {
            return
        }
        if let anyValue = value as? Google_Protobuf_Any {
            let anyValues = try extractAnyPathValues(
                from: anyValue,
                nodeIndex: childIndex,
                tree: tree
            )
            values.merge(anyValues) { _, new in
                new
            }
        } else {
            var visitor = PathVisitor<M>(
                tree: tree,
                nodeIndex: childIndex
            )
            try value.traverse(visitor: &visitor)
            values.merge(visitor.values) { _, new in
                new
            }
        }
    }

    internal mutating func visitExtensionFields(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}

    internal mutating func visitExtensionFieldsAsMessageSet(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}

    mutating func visitUnknown(bytes: Data) throws {}

    mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        try visitMessageField(value, fieldNumber: fieldNumber)
    }

    mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
        try visitMessageField(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedMessageField<M>(value: [M], fieldNumber: Int) throws where M: Message {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: MapValueType {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: Enum, ValueType.RawValue == Int {
        visit(value, fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where KeyType: MapKeyType, ValueType: Hashable, ValueType: Message {
        visit(value, fieldNumber: fieldNumber)
    }
}

internal func extractAnyPathValues(
    from any: Google_Protobuf_Any,
    nodeIndex: Int,
    tree: FieldMaskPathTree
) throws -> [Int: Any] {
    var result: [Int: Any] = [:]
    if let typeURLChild = tree.child(of: nodeIndex, named: "type_url"),
        tree.nodes[typeURLChild].isLeaf,
        !any._storage._typeURL.isEmpty
    {
        result[typeURLChild] = any._storage._typeURL
    }
    if let valueChild = tree.child(of: nodeIndex, named: "value"),
        tree.nodes[valueChild].isLeaf
    {
        let data: Data
        let remainingDepth: Int?
        switch any._storage.state {
        case .binary(let binaryData):
            data = binaryData
            remainingDepth = any._storage._binaryRemainingDepth
        case .message(let msg):
            data = try msg.serializedBytes(partial: true)
            remainingDepth = nil
        case .contentJSON(let contentJSON, let options):
            data = try any._storage.serializedContentJSONBytes(
                contentJSON: contentJSON,
                options: options
            )
            remainingDepth = nil
        }
        if !data.isEmpty {
            result[valueChild] = AnyBinaryFieldValue(
                data: data,
                binaryRemainingDepth: remainingDepth
            )
        }
    }
    return result
}

#endif
