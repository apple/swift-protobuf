// Sources/SwiftProtobuf/EnumLayout.swift - Type-erased enum layout
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The layout description for the cases of an enum.
///
// -----------------------------------------------------------------------------

import Foundation

/// Defines layout properties of a protobuf enum.
///
/// This type is public because it needs to be referenced and initialized from generated messages.
/// Clients should not access it directly.
///
/// TODO: For now, this type only holds a placeholder (empty) layout string and the name map for
/// the enum's values, similarly to how the name map is represented for messages. In the future,
/// we can store additional information here that's relevant for reflection.
@_spi(ForGeneratedCodeOnly) public struct EnumLayout: @unchecked Sendable {
    /// The encoded layout of the values of this enum.
    ///
    /// TODO: This is currently unused; decide whether we want to adopt something like the sparse
    /// enum layout description that upb uses. We don't really need this for the purpose of checking
    /// raw value validity today because we can simply attempt to initialize an instance and see if
    /// we get nil back, but this could be useful for a future reflection API.
    private let layout: UnsafeRawBufferPointer

    /// The name map for the enum.
    ///
    /// TODO: This is a big but temporary performance regression while we're moving to the new
    /// implementation. Previously, name maps were a `static let` on the individual enum types,
    /// which meant their initialization only occurred when they were first used (e.g., when
    /// performing text/JSON serialization). Now, the name map needs to be part of the layout to
    /// satisfy the self-describing nature of `_MessageStorage` for the new table-driven text/JSON
    /// implementation, which forces it to be initialized whenever any part of the layout is
    /// requested (even during binary serialization). In the near future, we will replace the
    /// current name map implementation with a new one that eliminates this first-time
    /// initialization cost.
    ///
    /// TODO: This is public so that it can be read by generated enums to satisfy the
    /// `ProtoNameProviding` requirement. Make it internal once that's no longer necessary.
    public let nameMap: _NameMap

    /// Creates a new enum layout from the given values.
    ///
    /// This initializer is public because generated enums need to call it.
    public init(layout: StaticString, names: StaticString) {
        self.layout = UnsafeRawBufferPointer(start: layout.utf8Start, count: layout.utf8CodeUnitCount)
        self.nameMap = names.utf8CodeUnitCount != 0 ? _NameMap(bytecode: names) : _NameMap()
    }
}
