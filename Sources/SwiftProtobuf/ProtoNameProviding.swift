// Sources/SwiftProtobuf/ProtoNameProviding.swift - Support for accessing proto names
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// SwiftProtobuf Internal: Common support looking up field names.
///
/// Messages conform to this protocol to provide the proto/text and JSON field
/// names for their fields. This lets the generator pull these names out into
/// extensions in separate files so that users can omit them in release builds
/// (reducing bloat and minimizing leaks of field names).
public protocol _ProtoNameProviding {

    /// The mapping between field numbers and the proto/JSON field names that
    /// the conforming message type defines.
    static var _protobuf_nameMap: _NameMap { get }
}
