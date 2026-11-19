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

extension Google_Protobuf_FieldMask {

    /// Defines available options for merging two messages.
    public struct MergeOptions {
        /// The default merging behavior will append entries from the source
        /// repeated field to the destination repeated field. If you only want
        /// to keep the entries from the source repeated field, set this flag
        /// to true.
        public var replaceRepeatedFields: Bool

        /// When merging message fields, the default behavior is to merge the
        /// content of two message fields together. If you instead want to use
        /// the field from the source message to replace the corresponding field
        /// in the destination message, set this flag to true. When this flag is
        /// set, specified submessage fields that are missing in source will be
        /// cleared in destination.
        public var replaceMessageFields: Bool

        public init() {
            self.replaceRepeatedFields = false
            self.replaceMessageFields = false
        }
    }
}

#if FieldMaskUtilities

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

extension GeneratedMessage {
    /// Checks whether the given path is valid for this message type.
    public static func isPathValid(_ path: String) -> Bool {
        messageSchema.isPathValid(path)
    }
}
extension Message {
    /// Merges fields specified in a FieldMask into another message.
    ///
    /// - Parameters:
    ///   - source: Message that should be merged to the original one.
    ///   - fieldMask: FieldMask specifies which fields should be merged.
    ///   - mergeOption: Options that customize how the fields are merged.
    public mutating func merge(
        from source: Self,
        fieldMask: Google_Protobuf_FieldMask,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions = .init()
    ) throws {
        guard !fieldMask.paths.isEmpty else { return }
        let trie = try FieldMaskMergeTrie(paths: fieldMask.paths, rootSchema: storageForRuntime.schema)
        guard trie.hasResolvedLeaf else { return }
        _protobuf_ensureUniqueStorage(accessToken: .init())
        storageForRuntime.merge(from: source.storageForRuntime, trie: trie, mergeOptions: mergeOption)
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
        _protobuf_ensureUniqueStorage(accessToken: .init())
        return storageForRuntime.trim(keeping: fieldMask)
    }
}

#endif
