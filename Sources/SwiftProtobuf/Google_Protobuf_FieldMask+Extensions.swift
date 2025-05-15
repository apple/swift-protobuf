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

// True if the string only contains printable (non-control)
// ASCII characters.  Note: This follows the ASCII standard;
// space is not a "printable" character.
private func isPrintableASCII(_ s: String) -> Bool {
    for u in s.utf8 {
        if u <= 0x20 || u >= 0x7f {
            return false
        }
    }
    return true
}

private func ProtoToJSON(name: String) -> String? {
    guard isPrintableASCII(name) else { return nil }
    var jsonPath = String()
    var chars = name.makeIterator()
    while let c = chars.next() {
        switch c {
        case "_":
            if let toupper = chars.next() {
                switch toupper {
                case "a"..."z":
                    jsonPath.append(String(toupper).uppercased())
                default:
                    return nil
                }
            } else {
                return nil
            }
        case "A"..."Z":
            return nil
        case "a"..."z", "0"..."9", ".", "(", ")":
            jsonPath.append(c)
        default:
            // TODO: Change this to `return nil`
            // once we know everything legal is handled
            // above.
            jsonPath.append(c)
        }
    }
    return jsonPath
}

private func JSONToProto(name: String) -> String? {
    guard isPrintableASCII(name) else { return nil }
    var path = String()
    for c in name {
        switch c {
        case "_":
            return nil
        case "A"..."Z":
            path.append(Character("_"))
            path.append(String(c).lowercased())
        case "a"..."z", "0"..."9", ".", "(", ")":
            path.append(c)
        default:
            // TODO: Change to `return nil` once
            // we know everything legal is being
            // handled above
            path.append(c)
        }
    }
    return path
}

private func parseJSONFieldNames(names: String) -> [String]? {
    // An empty field mask is the empty string (no paths).
    guard !names.isEmpty else { return [] }
    var fieldNameCount = 0
    var fieldName = String()
    var split = [String]()
    for c in names {
        switch c {
        case ",":
            if fieldNameCount == 0 {
                return nil
            }
            if let pbName = JSONToProto(name: fieldName) {
                split.append(pbName)
            } else {
                return nil
            }
            fieldName = String()
            fieldNameCount = 0
        default:
            fieldName.append(c)
            fieldNameCount += 1
        }
    }
    if fieldNameCount == 0 {  // Last field name can't be empty
        return nil
    }
    if let pbName = JSONToProto(name: fieldName) {
        split.append(pbName)
    } else {
        return nil
    }
    return split
}

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
        // TODO: This should fail if any of the conversions from JSON fails
        self.init(protoPaths: jsonPaths.compactMap(JSONToProto))
    }

    // It would be nice if to have an initializer that accepted Swift property
    // names, but translating between swift and protobuf/json property
    // names is not entirely deterministic.
}

extension Google_Protobuf_FieldMask: _CustomJSONCodable {
    mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        let s = try decoder.scanner.nextQuotedString()
        if let names = parseJSONFieldNames(names: s) {
            paths = names
        } else {
            throw JSONDecodingError.malformedFieldMask
        }
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        // Note:  Proto requires alphanumeric field names, so there
        // cannot be a ',' or '"' character to mess up this formatting.
        var jsonPaths = [String]()
        for p in paths {
            if let jsonPath = ProtoToJSON(name: p) {
                jsonPaths.append(jsonPath)
            } else {
                throw JSONEncodingError.fieldMaskConversion
            }
        }
        return "\"" + jsonPaths.joined(separator: ",") + "\""
    }
}

extension Google_Protobuf_FieldMask {

    /// Initiates a field mask with all fields of the message type.
    ///
    /// - Parameter messageType: Message type to get all paths from.
    public init<M: Message & _ProtoNameProviding>(
        allFieldsOf messageType: M.Type
    ) {
        self = .with { mask in
            mask.paths = M.allProtoNames
        }
    }

    /// Initiates a field mask from some particular field numbers of a message
    ///
    /// - Parameters:
    ///   - messageType: Message type to get all paths from.
    ///   - fieldNumbers: Field numbers of paths to be included.
    /// - Returns: Field mask that include paths of corresponding field numbers.
    /// - Throws: `FieldMaskError.invalidFieldNumber` if the field number
    ///  is not on the message
    public init<M: Message & _ProtoNameProviding>(
        fieldNumbers: [Int],
        of messageType: M.Type
    ) throws {
        var paths: [String] = []
        for number in fieldNumbers {
            guard let name = M.protoName(for: number) else {
                throw FieldMaskError.invalidFieldNumber
            }
            paths.append(name)
        }
        self = .with { mask in
            mask.paths = paths
        }
    }
}

extension Google_Protobuf_FieldMask {

    /// Adds a path to FieldMask after checking whether the given path is valid.
    /// This method check-fails if the path is not a valid path for Message type.
    ///
    /// - Parameters:
    ///   - path: Path to be added to FieldMask.
    ///   - messageType: Message type to check validity.
    public mutating func addPath<M: Message>(
        _ path: String,
        of messageType: M.Type
    ) throws {
        guard M.isPathValid(path) else {
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
    /// - Parameter mask: FieldMask to intersect with.
    /// - Returns: FieldMask with intersection of two path sets.
    public func intersect(
        _ mask: Google_Protobuf_FieldMask
    ) -> Google_Protobuf_FieldMask {
        let set = Set<String>(mask.paths)
        var paths: [String] = []
        var buffer = Set<String>()
        for path in self.paths where set.contains(path) && !buffer.contains(path) {
            buffer.insert(path)
            paths.append(path)
        }
        return .with { mask in
            mask.paths = paths
        }
    }

    /// Creates a FieldMasks with paths of the original FieldMask
    /// that does not included in mask.
    ///
    /// - Parameter mask: FieldMask with paths should be substracted.
    /// - Returns: FieldMask with all paths does not included in mask.
    public func subtract(
        _ mask: Google_Protobuf_FieldMask
    ) -> Google_Protobuf_FieldMask {
        let set = Set<String>(mask.paths)
        var paths: [String] = []
        var buffer = Set<String>()
        for path in self.paths where !set.contains(path) && !buffer.contains(path) {
            buffer.insert(path)
            paths.append(path)
        }
        return .with { mask in
            mask.paths = paths
        }
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
    public func isValid<M: Message & _ProtoNameProviding>(
        for messageType: M.Type
    ) -> Bool {
        var message = M()
        return paths.allSatisfy { path in
            message.isPathValid(path)
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

extension Message where Self: _ProtoNameProviding {
    fileprivate static func protoName(for number: Int) -> String? {
        Self._protobuf_nameMap.names(for: number)?.proto.description
    }

    fileprivate static var allProtoNames: [String] {
        Self._protobuf_nameMap.names.map(\.description)
    }
}
