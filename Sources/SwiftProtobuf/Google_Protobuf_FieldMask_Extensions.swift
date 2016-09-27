// ProtobufRuntime/Sources/Protobuf/Google_Protobuf_FieldMask_Extensions.swift - Fieldmask extensions
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
/// Extend the generated FieldMask message with customized JSON coding and
/// convenience methods.
///
// -----------------------------------------------------------------------------

import Swift

// TODO: We should have utilities to apply a fieldmask to an arbitrary
// message, intersect two fieldmasks, etc.

private func ProtoToJSON(name: String) -> String? {
    var jsonPath = ""
    var chars = name.characters.makeIterator()
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
        default:
            jsonPath.append(c)
        }
    }
    return jsonPath
}

private func JSONToProto(name: String) -> String? {
    var path = ""
    for c in name.characters {
        switch c {
        case "_":
            return nil
        case "A"..."Z":
            path.append(Character("_"))
            path.append(String(c).lowercased())
        default:
            path.append(c)
        }
    }
    return path
}

private func parseJSONFieldNames(names: String) -> [String]? {
    var fieldNameCount = 0
    var fieldName = ""
    var split = [String]()
    for c: Character in names.characters {
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
            fieldName = ""
            fieldNameCount = 0
        default:
            fieldName.append(c)
            fieldNameCount += 1
        }
    }
    if fieldNameCount == 0 { // Last field name can't be empty
        return nil
    }
    if let pbName = JSONToProto(name: fieldName) {
        split.append(pbName)
    } else {
        return nil
    }
    return split
}

public extension Google_Protobuf_FieldMask {
    /// Initialize a FieldMask object with an array of paths.
    /// The paths should match the names used in the proto file (which
    /// will be different than the corresponding Swift property names).
    public init(protoPaths: [String]) {
        self.init()
        paths = protoPaths
    }

    /// Initialize a FieldMask object with the provided paths.
    /// The paths should match the names used in the proto file (which
    /// will be different than the corresponding Swift property names).
    public init(protoPaths: String...) {
        self.init(protoPaths: protoPaths)
    }

    /// Initialize a FieldMask object with the provided paths.
    /// The paths should match the names used in the JSON serialization
    /// (which will be different than the field names in the proto file
    /// or the corresponding Swift property names).
    public init?(jsonPaths: String...) {
        // TODO: This should fail if any of the conversions from JSON fails
        self.init(protoPaths: jsonPaths.flatMap(JSONToProto))
    }

    // It would be nice if to have an initializer that accepted Swift property
    // names, but translating between swift and protobuf/json property
    // names is not entirely deterministic.

    mutating public func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        switch token {
        case .string(let s):
            if let names = parseJSONFieldNames(names: s) {
                paths = names
            } else {
                throw ProtobufDecodingError.fieldMaskConversion
            }
        default:
            throw ProtobufDecodingError.schemaMismatch
        }
    }

    // Custom hand-rolled JSON serializer
    public func serializeJSON() throws -> String {
        // Note:  Proto requires alphanumeric field names, so there
        // cannot be a ',' or '"' character to mess up this formatting.
        var jsonPaths = [String]()
        for p in paths {
            if let jsonPath = ProtoToJSON(name: p) {
                jsonPaths.append(jsonPath)
            } else {
                throw ProtobufEncodingError.fieldMaskConversion
            }
        }
        return "\"" + jsonPaths.joined(separator: ",") + "\""
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }
}
