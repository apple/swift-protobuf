// Sources/protoc-gen-swift/MessageStorageDecision.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

// The file attempts to isolate the decisions around when to use heap based
// storage vs. inlining it into the value times. At the moment the decisions
// are entirely based on field counts and language requires, but this could be
// revised in the future to better account for the actually *real* memory
// impacts.

/// Wraps the calculation of the "cost" of fields.
///
/// As mentioned in the file comment, these numbers can be revised in the future
/// to compute a real stack/heap cost if desired.
private enum FieldCost {
    /// Of a repeated field.
    static let repeated = 1
    /// Of a map field.
    static let map = 1

    /// Of "Plan Old Data" (ints, floating point) field that is 64 bits
    static let singlePOD32 = 1
    /// Of "Plan Old Data" (ints, floating point) field that is 64 bits
    static let singlePOD64 = 1
    /// Of bool field.
    static let singleBool = 1
    /// Of a `string` field.
    static let singleString = 1
    /// Of a `bytes` field.
    static let singleBytes = 1

    /// A single Message field where the message in question uses storage.
    static let singleMessageFieldUsingStorage = 1

    static func estimate(_ field: FieldDescriptor) -> Int {
        guard !field.isRepeated else {
            // Repeated fields don't count the exact types, just fixed costs.
            return field.isMap ? FieldCost.map : FieldCost.repeated
        }

        switch field.type {
        case .bool:
            return 1
        case .int32, .sint32, .uint32, .fixed32, .sfixed32, .float, .enum:
            return FieldCost.singlePOD32
        case .int64, .sint64, .uint64, .fixed64, .sfixed64, .double:
            return FieldCost.singlePOD64
        case .string:
            return FieldCost.singleString
        case .bytes:
            return FieldCost.singleBytes
        case .group, .message:
            return analyze(descriptor: field.messageType!).costAsField
        }
    }
}

/// Maximum computed cost of a Message's fields allow before it uses Storage.
private let totalFieldCostRequiringStorage = 17

/// The result of analysis, if the message should use heap storage and the
/// cost of the message when used as a field in other messages.
private struct AnalyzeResult {
    let usesStorage: Bool
    let costAsField: Int

    init(usesStorage: Bool, costAsField: Int) {
        precondition(costAsField < totalFieldCostRequiringStorage || usesStorage)
        self.usesStorage = usesStorage
        self.costAsField = costAsField
    }

    @inlinable
    init(_ costAsField: Int) {
        self.init(usesStorage: false, costAsField: costAsField)
    }

    /// The message should use storage.
    static let useStorage =
        AnalyzeResult(usesStorage: true, costAsField: FieldCost.singleMessageFieldUsingStorage)
}

// This is adapted from SwiftNIO so sendable checks don't flag issues with
// `analysisCache`. Another option would be something like NIO's
// `LockedValueBox` or moving the entire handling to a Task.
private final class UnsafeMutableTransferBox<Wrapped> {
    var wrappedValue: Wrapped
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}

extension UnsafeMutableTransferBox: @unchecked Sendable {}

/// Cache for the `analyze(descriptor:)` results to avoid doing them multiple
/// times.
private let analysisCache: UnsafeMutableTransferBox<[String: AnalyzeResult]> = .init([
    // google.protobuf.Any can be seeded.
    "google.protobuf.Any": .useStorage
])

/// Cache for containsRecursiveSingularField() values to speed things up.
private let recursiveMessageCache: UnsafeMutableTransferBox<[String: Bool]> = .init([:])

/// Analyze the given descriptor to decide if it should use storage and what
/// the cost of it will be when appearing as a single field in another message.
private func analyze(descriptor: Descriptor) -> AnalyzeResult {
    if let analysis = analysisCache.wrappedValue[descriptor.fullName] {
        return analysis
    }

    func containsRecursiveSingularField(_ descriptor: Descriptor) -> Bool {
        if let cached = recursiveMessageCache.wrappedValue[descriptor.fullName] {
            return cached
        }

        let initialFile = descriptor.file

        func recursionHelper(_ descriptor: Descriptor, messageStack: [Descriptor]) -> Bool {
            var messageStack = messageStack
            messageStack.append(descriptor)
            // Note: This stops as soon as it finds recursion though any singular message field.
            // That means there could be other cycles via other message types that won't get caught
            // until starting with one of them message in that distict cycle.
            let result = descriptor.fields.contains {
                guard !$0.isRepeated else { return false }
                // Ignore fields that aren’t messages or groups.
                guard $0.type == .message || $0.type == .group else { return false }
                guard let messageType = $0.messageType else { return false }

                // Proto files are a graph without cycles, to be recursive, the messages
                // in the cycle must be defined in the same file.
                guard messageType.file === initialFile else { return false }

                // If the message for this field has already been checked and is known to not be
                // recursive, there is no need to check it again. If it was known to be recursive
                // then as mentioned above, that doesn't mean anything about the message that
                // referenced it as a field and there could be an undiscovered loop through that
                // message back to the original, so we still have to do the work.
                if recursiveMessageCache.wrappedValue[messageType.fullName] == false {
                    return false
                }

                // Did things recurse?
                if let first = messageStack.firstIndex(where: { $0 === messageType }) {
                    // Go ahead and flag that range as recursive and might as well also seed the
                    // analysis cache with the fact that they are going to use storage.
                    for msg in messageStack[first..<messageStack.endIndex] {
                        recursiveMessageCache.wrappedValue[msg.fullName] = true
                        analysisCache.wrappedValue[msg.fullName] = .useStorage
                    }

                    // If it was the first thing in the stack, we've recurse the thing original
                    // asked about, so done (stops the `contains`) and says the message being
                    // checked is recursive.
                    if first == messageStack.startIndex {
                        return true
                    }

                    // The cycle wasn't the whole message stack, meaning the cycle was between
                    // some nested down in subfields and didn't go all the way back up to the
                    // message we started with, so that means we haven't found recursion for the
                    // message we actually are checking.
                    return false
                }

                // Examine sub-message.
                return recursionHelper(messageType, messageStack: messageStack)
            }
            recursiveMessageCache.wrappedValue[descriptor.fullName] = result
            return result
        }

        return recursionHelper(descriptor, messageStack: [])
    }

    func helper(_ descriptor: Descriptor) -> AnalyzeResult {
        // NOTE: The first thing we do is check if the message has any path to being recursive.
        // An alternative would be to do this check after adding up the sizes of fields to see
        // if we want to spill to storage. However, that has the side effect that the storage
        // choice could *change* if you moved the messages around within the file as the decision
        // to use storage could make a second recursive path not also use storage. And having
        // a determistic decision regardless of order seems more correct.
        if containsRecursiveSingularField(descriptor) {
            return .useStorage
        }

        var fieldsCost: Int = 0

        // Compute a cost for all the fields that aren't in a oneof.
        for f in descriptor.fields {
            guard f.oneofIndex == nil else { continue }
            fieldsCost += FieldCost.estimate(f)
            if fieldsCost >= totalFieldCostRequiringStorage {
                return .useStorage
            }
        }

        // Add in the cost of the largest field of each oneof.
        for o in descriptor.oneofs {
            var oneofCost: Int = 0
            for f in o.fields {
                oneofCost = max(oneofCost, FieldCost.estimate(f))
                if (fieldsCost + oneofCost) >= totalFieldCostRequiringStorage {
                    return .useStorage
                }
            }
            fieldsCost += oneofCost
        }
        assert(fieldsCost <= totalFieldCostRequiringStorage)

        return AnalyzeResult(fieldsCost)
    }

    let result = helper(descriptor)
    analysisCache.wrappedValue[descriptor.fullName] = result
    return result
}

/// Encapsulates the decision choices around when a Message should use
/// heap based storage.
enum MessageStorageDecision {
    /// Compute if a message should use heap based storage or not.
    static func shouldUseHeapStorage(descriptor: Descriptor) -> Bool {
        analyze(descriptor: descriptor).usesStorage
    }
}
