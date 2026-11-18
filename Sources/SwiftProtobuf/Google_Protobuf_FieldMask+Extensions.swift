// Sources/SwiftProtobuf/Google_Protobuf_FieldMask+Extensions.swift - Fieldmask extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the generated FieldMask message with customized JSON coding and
/// convenience methods.
///
// -----------------------------------------------------------------------------

#if FieldMaskUtilities
extension Google_Protobuf_FieldMask {
    /// Creates a new `Google_Protobuf_FieldMask` from the given array of paths.
    ///
    /// The paths should match the names used in the .proto file, which may be
    /// different than the corresponding Swift property names.
    ///
    /// - Parameter protoPaths: The paths from which to create the field mask,
    ///   defined using the .proto names for the fields.
    public init(protoPaths: [String]) {
        self.init()
        paths = protoPaths
    }

    /// Creates a new `Google_Protobuf_FieldMask` from the given paths.
    ///
    /// The paths should match the names used in the .proto file, which may be
    /// different than the corresponding Swift property names.
    ///
    /// - Parameter protoPaths: The paths from which to create the field mask,
    ///   defined using the .proto names for the fields.
    public init(protoPaths: String...) {
        self.init(protoPaths: protoPaths)
    }

    /// Creates a new `Google_Protobuf_FieldMask` from the given paths.
    ///
    /// The paths should match the JSON names of the fields, which may be
    /// different than the corresponding Swift property names.
    ///
    /// - Parameter jsonPaths: The paths from which to create the field mask,
    ///   defined using the JSON names for the fields.
    public init?(jsonPaths: String...) {
        var protoPaths = [String]()
        protoPaths.reserveCapacity(jsonPaths.count)
        for jsonPath in jsonPaths {
            guard let protoPath = protoName(forJSONFieldMaskPath: jsonPath) else {
                return nil
            }
            protoPaths.append(protoPath)
        }
        self.init(protoPaths: protoPaths)
    }

    // It would be nice if to have an initializer that accepted Swift property
    // names, but translating between swift and protobuf/json property
    // names is not entirely deterministic.
}

extension Google_Protobuf_FieldMask {
    /// Initiates a field mask with all fields of the message type.
    ///
    /// - Parameter messageType: Message type to get all paths from.
    public init<M: GeneratedMessage>(
        allFieldsOf messageType: M.Type
    ) {
        self.init()
        let schema = M.messageSchema
        var paths: [String] = []
        for field in schema.fields {
            if let name = schema.textName(forFieldNumber: field.fieldNumber) {
                paths.append(String(decoding: name.buffer, as: UTF8.self))
            }
        }
        self.paths = paths
    }

    /// Initiates a field mask from some particular field numbers of a message
    ///
    /// - Parameters:
    ///   - messageType: Message type to get all paths from.
    ///   - fieldNumbers: Field numbers of paths to be included.
    /// - Returns: Field mask that include paths of corresponding field numbers.
    /// - Throws: `FieldMaskError.invalidFieldNumber` if the field number
    ///  is not on the message
    public init<M: GeneratedMessage>(
        fieldNumbers: [Int],
        of messageType: M.Type
    ) throws {
        self.init()
        let schema = M.messageSchema
        var paths: [String] = []
        for number in fieldNumbers {
            guard let name = schema.textName(forFieldNumber: UInt32(number)) else {
                throw FieldMaskError.invalidFieldNumber
            }
            paths.append(String(decoding: name.buffer, as: UTF8.self))
        }
        self.paths = paths
    }
}

/// Compact flat-array prefix trie over dot-separated `FieldMask` path
/// components, providing linear-time sub-path coverage checks and canonical
/// intersection without recursion or per-segment `String` allocations.
private struct FieldMaskPathTrie {
    private struct Node {
        fileprivate var terminalPath: String? = nil
        fileprivate var children: [Substring: Int] = [:]
    }

    private var nodes: [Node] = [Node()]

    init(_ paths: [String]) {
        for path in paths {
            insert(path)
        }
    }

    private mutating func insert(_ path: String) {
        var nodeIndex = 0
        var remaining = path[...]
        while true {
            if nodes[nodeIndex].terminalPath != nil {
                // Already covered by an ancestor path.
                return
            }
            let component: Substring
            let nextStart: String.Index?
            if let dot = remaining.firstIndex(of: ".") {
                component = remaining[..<dot]
                nextStart = remaining.index(after: dot)
            } else {
                component = remaining
                nextStart = nil
            }
            if let nextIndex = nodes[nodeIndex].children[component] {
                nodeIndex = nextIndex
            } else {
                let newIndex = nodes.count
                nodes.append(Node())
                nodes[nodeIndex].children[component] = newIndex
                nodeIndex = newIndex
            }
            if let nextStart {
                remaining = remaining[nextStart...]
            } else {
                break
            }
        }
        nodes[nodeIndex].terminalPath = path
        nodes[nodeIndex].children.removeAll()
    }

    /// Returns true if `path` or one of its parent paths ("foo" for "foo.bar")
    /// is in this trie, matching the coverage rule of `contains(_:)`.
    fileprivate func covers(_ path: String) -> Bool {
        var nodeIndex = 0
        var remaining = path[...]
        while true {
            if nodes[nodeIndex].terminalPath != nil {
                return true
            }
            let component: Substring
            let nextStart: String.Index?
            if let dot = remaining.firstIndex(of: ".") {
                component = remaining[..<dot]
                nextStart = remaining.index(after: dot)
            } else {
                component = remaining
                nextStart = nil
            }
            guard let nextIndex = nodes[nodeIndex].children[component] else {
                return false
            }
            nodeIndex = nextIndex
            if let nextStart {
                remaining = remaining[nextStart...]
            } else {
                return nodes[nodeIndex].terminalPath != nil
            }
        }
    }

    private func collectTerminals(from startIndex: Int, into output: inout [String]) {
        var stack = [startIndex]
        while let nodeIndex = stack.popLast() {
            if let path = nodes[nodeIndex].terminalPath {
                output.append(path)
            } else {
                stack.append(contentsOf: nodes[nodeIndex].children.values)
            }
        }
    }

    /// Returns the sorted canonical intersection of the paths in `self` and `other`.
    fileprivate func intersect(with other: FieldMaskPathTrie) -> [String] {
        var output: [String] = []
        var stack: [(Int, Int)] = [(0, 0)]
        while let (lhsIndex, rhsIndex) = stack.popLast() {
            if nodes[lhsIndex].terminalPath != nil {
                other.collectTerminals(from: rhsIndex, into: &output)
            } else if other.nodes[rhsIndex].terminalPath != nil {
                collectTerminals(from: lhsIndex, into: &output)
            } else {
                let lhsChildren = nodes[lhsIndex].children
                let rhsChildren = other.nodes[rhsIndex].children
                if lhsChildren.count <= rhsChildren.count {
                    for (component, lhsChild) in lhsChildren {
                        if let rhsChild = rhsChildren[component] {
                            stack.append((lhsChild, rhsChild))
                        }
                    }
                } else {
                    for (component, rhsChild) in rhsChildren {
                        if let lhsChild = lhsChildren[component] {
                            stack.append((lhsChild, rhsChild))
                        }
                    }
                }
            }
        }
        output.sort()
        return output
    }
}

extension Google_Protobuf_FieldMask {

    /// Adds a path to FieldMask after checking whether the given path is valid.
    /// This method check-fails if the path is not a valid path for Message type.
    ///
    /// - Parameters:
    ///   - path: Path to be added to FieldMask.
    ///   - messageType: Message type to check validity.
    public mutating func addPath<M: GeneratedMessage>(
        _ path: String,
        of messageType: M.Type
    ) throws {
        guard M.messageSchema.isPathValid(path) else {
            throw FieldMaskError.invalidPath
        }
        paths.append(path)
    }

    /// Converts a FieldMask to the canonical form. It will:
    ///   1. Remove paths that are covered by another path. For example,
    ///      "foo.bar" is covered by "foo" and will be removed if "foo"
    ///      is also in the FieldMask.
    ///   2. Sort all paths in alphabetical order.
    public var canonical: Google_Protobuf_FieldMask {
        var mask = Google_Protobuf_FieldMask()
        let sortedPaths = self.paths.sorted()
        for path in sortedPaths {
            if let lastPath = mask.paths.last {
                if path != lastPath, !path.hasPrefix("\(lastPath).") {
                    mask.paths.append(path)
                }
            } else {
                mask.paths.append(path)
            }
        }
        return mask
    }

    /// Creates an union of two FieldMasks.
    ///
    /// - Parameter mask: FieldMask to union with.
    /// - Returns: FieldMask with union of two path sets.
    public func union(
        _ mask: Google_Protobuf_FieldMask
    ) -> Google_Protobuf_FieldMask {
        var buffer: Set<String> = .init()
        var paths: [String] = []
        let allPaths = self.paths + mask.paths
        for path in allPaths where !buffer.contains(path) {
            buffer.insert(path)
            paths.append(path)
        }
        return .with { mask in
            mask.paths = paths
        }
    }

    /// Creates an intersection of two FieldMasks.
    ///
    /// A path is in the intersection if both masks contain it (see
    /// ``contains(_:)``), so "foo.bar" intersected with "foo" is "foo.bar".
    /// The result is in canonical form (see ``canonical``).
    ///
    /// - Parameter mask: FieldMask to intersect with.
    /// - Returns: FieldMask with intersection of two path sets.
    public func intersect(
        _ mask: Google_Protobuf_FieldMask
    ) -> Google_Protobuf_FieldMask {
        guard !self.paths.isEmpty && !mask.paths.isEmpty else {
            return Google_Protobuf_FieldMask()
        }
        let selfTrie = FieldMaskPathTrie(self.paths)
        let otherTrie = FieldMaskPathTrie(mask.paths)
        return Google_Protobuf_FieldMask(protoPaths: selfTrie.intersect(with: otherTrie))
    }

    /// Creates a FieldMasks with paths of the original FieldMask
    /// that does not included in mask.
    ///
    /// A path is removed if `mask` contains it (see ``contains(_:)``), so
    /// "foo.bar" minus "foo" is empty. A path that `mask` only covers part of
    /// is kept as is ("foo" minus "foo.bar" is "foo"), since splitting it into
    /// the remaining fields needs the message type.
    ///
    /// - Parameter mask: FieldMask with paths should be substracted.
    /// - Returns: FieldMask with all paths does not included in mask.
    public func subtract(
        _ mask: Google_Protobuf_FieldMask
    ) -> Google_Protobuf_FieldMask {
        guard !self.paths.isEmpty else {
            return Google_Protobuf_FieldMask()
        }
        var paths: [String] = []
        var buffer = Set<String>()
        if mask.paths.isEmpty {
            paths.reserveCapacity(self.paths.count)
            for path in self.paths where buffer.insert(path).inserted {
                paths.append(path)
            }
        } else {
            let otherTrie = FieldMaskPathTrie(mask.paths)
            for path in self.paths where buffer.insert(path).inserted && !otherTrie.covers(path) {
                paths.append(path)
            }
        }
        return Google_Protobuf_FieldMask(protoPaths: paths)
    }

    /// Returns true if path is covered by the given FieldMask. Note that path
    /// "foo.bar" covers all paths like "foo.bar.baz", "foo.bar.quz.x", etc.
    /// Also note that parent paths are not covered by explicit child path, i.e.
    /// "foo.bar" does NOT cover "foo", even if "bar" is the only child.
    ///
    /// - Parameter path: Path to be checked.
    /// - Returns: Boolean determines is path covered.
    public func contains(_ path: String) -> Bool {
        for fieldMaskPath in paths {
            if path.hasPrefix("\(fieldMaskPath).") || fieldMaskPath == path {
                return true
            }
        }
        return false
    }
}

extension Google_Protobuf_FieldMask {

    /// Checks whether the given FieldMask is valid for type M.
    ///
    /// - Parameter messageType: Message type to paths check with.
    /// - Returns: Boolean determines FieldMask is valid.
    public func isValid<M: GeneratedMessage>(
        for messageType: M.Type
    ) -> Bool {
        paths.allSatisfy { path in
            M.messageSchema.isPathValid(path)
        }
    }
}

/// Describes errors could happen during FieldMask utilities.
public enum FieldMaskError: Error {

    /// Describes a path is invalid for a Message type.
    case invalidPath

    /// Describes a fieldNumber is invalid for a Message type.
    case invalidFieldNumber
}
#endif
