// Sources/SwiftProtobuf/Internal.swift - Message support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Internal helpers on Messages for the library. These are public
// just so the generated code can call them, but shouldn't be called
// by developers directly.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Functions that are public only because generated message implementations use them.
/// - IMPORTANT: Clients must not call these directly.
public enum Internal {

    #if !REMOVE_DEPRECATED_APIS
    /// A singleton instance of empty data that the generated code uses for default values.
    ///
    /// This is a performance enhancement to work around the fact that the `Data` type in
    /// Swift involves a new heap allocation every time you initialize an empty instance,
    /// instead of sharing a common empty backing storage.
    /// - Note: Nothing uses this any longer - it only exists to support code that protoc-gen-swift 1.10.2 and earlier produced.
    @available(
        *,
        deprecated,
        message:
            "Internal.emptyData isn't used any longer in newer versions of the generator. Generate code with a version later than 1.10.2 to get performance improvements. See https://github.com/apple/swift-protobuf/pull/1028 for more information."
    )
    public static let emptyData = Data()
    #endif  // !REMOVE_DEPRECATED_APIS

    /// Helper to loop over a list of Messages to see if they are all
    /// initialized (see Message.isInitialized for what that means).
    public static func areAllInitialized(_ listOfMessages: [any Message]) -> Bool {
        for msg in listOfMessages {
            if !msg.isInitialized {
                return false
            }
        }
        return true
    }

    /// Helper to loop over dictionary with values that are Messages to see if
    /// they are all initialized (see Message.isInitialized for what that means).
    public static func areAllInitialized<K>(_ mapToMessages: [K: any Message]) -> Bool {
        for (_, msg) in mapToMessages {
            if !msg.isInitialized {
                return false
            }
        }
        return true
    }
}
