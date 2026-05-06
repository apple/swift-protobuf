// Sources/SwiftProtobuf/Message+FieldMask.swift - Message field mask extensions
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the Message types with FieldMask utilities.
///
// -----------------------------------------------------------------------------

// TODO: Re-implement these using a reflection API.

extension GeneratedMessage {
    /// Checks whether the given path is valid for this message type.
    public static func isPathValid(_ path: String) -> Bool {
        return messageSchema.isPathValid(path)
    }
}

extension Google_Protobuf_FieldMask {
    /// Defines available options for merging two messages.
    public struct MergeOptions {
        public init() {}

        /// The default merging behavior will append entries from the source
        /// repeated field to the destination repeated field. If you only want
        /// to keep the entries from the source repeated field, set this flag
        /// to true.
        public var replaceRepeatedFields = false
    }
}

extension Message {
    /// Merges fields specified in a FieldMask into another message.
    ///
    /// - Parameters:
    ///   - source: Message that should be merged to the original one.
    ///   - fieldMask: FieldMask specifies which fields should be merged.
    public mutating func merge(
        from source: Self,
        fieldMask: Google_Protobuf_FieldMask,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions = .init()
    ) throws {
        try storageForRuntime.merge(from: source.storageForRuntime, fieldMask: fieldMask, mergeOptions: mergeOption)
    }

    /// Removes from 'message' any field that is not represented in the given
    /// FieldMask. If the FieldMask is empty, does nothing.
    ///
    /// - Parameter fieldMask: FieldMask specifies which fields should be kept.
    /// - Returns: Boolean determines if the message is modified
    @discardableResult
    public mutating func trim(keeping fieldMask: Google_Protobuf_FieldMask) -> Bool {
        let allPathsAreValid = fieldMask.paths.allSatisfy { messageSchema.isPathValid($0) }
        guard allPathsAreValid, !fieldMask.paths.isEmpty else {
            return false
        }
        return storageForRuntime.trim(keeping: fieldMask)
    }
}
