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
fileprivate enum FieldCost {
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
fileprivate let totalFieldCostRequiringStorage = 17

/// The result of analysis, if the message should use heap storage and the
/// cost of the message when used as a field in other messages.
fileprivate struct AnalyzeResult {
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
fileprivate final class UnsafeMutableTransferBox<Wrapped> {
  var wrappedValue: Wrapped
  init(_ wrappedValue: Wrapped) {
    self.wrappedValue = wrappedValue
  }
}

extension UnsafeMutableTransferBox: @unchecked Sendable {}

/// Cache for the `analyze(descriptor:)` results to avoid doing them multiple
/// times.
fileprivate let analysisCache: UnsafeMutableTransferBox<Dictionary<String,AnalyzeResult>> = .init([
  // google.protobuf.Any can be seeded.
  "google.protobuf.Any": .useStorage,
])

/// Analyze the given descriptor to decide if it should use storage and what
/// the cost of it will be when appearing as a single field in another message.
fileprivate func analyze(descriptor: Descriptor) -> AnalyzeResult {
  if let analysis = analysisCache.wrappedValue[descriptor.fullName] {
    return analysis
  }

  func containsRecursiveSingularField(_ descriptor: Descriptor) -> Bool {
    let initialFile = descriptor.file

    func recursionHelper(_ descriptor: Descriptor, messageStack: [Descriptor]) -> Bool {
      var messageStack = messageStack
      messageStack.append(descriptor)
      return descriptor.fields.contains {
        guard !$0.isRepeated else { return false }
        // Ignore fields that aren’t messages or groups.
        guard $0.type == .message || $0.type == .group else { return false }
        guard let messageType = $0.messageType else { return false }

        // Proto files are a graph without cycles, to be recursive, the messages
        // in the cycle must be defined in the same file.
        guard messageType.file === initialFile else { return false }

        // Did things recurse?
        if let first = messageStack.firstIndex(where: { $0 === messageType }) {
          // Mark all those in the loop as using storage.
          for msg in messageStack[first..<messageStack.endIndex] {
            analysisCache.wrappedValue[msg.fullName] = .useStorage
          }

          // And it was the top message, so return the result.
          if first == messageStack.startIndex {
            return true
          }

          // It recursed to something lower in the graph, so no need to
          // process it again.
          return false
        }

        // Examine sub-message.
        return recursionHelper(messageType, messageStack: messageStack)
      }
    }

    return recursionHelper(descriptor, messageStack: [])
  }

  func helper(_ descriptor: Descriptor) -> AnalyzeResult {
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
    return analyze(descriptor: descriptor).usesStorage
  }
}
