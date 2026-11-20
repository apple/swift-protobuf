// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import FuzzCommon
import SwiftProtobuf

// Put a limit on how many messages will be read because oss-fuzz seems
// occational timeouts on really large input sets, likely because there is just
// too much garbage so things just keep failing to parse. Just need to exercise
// things enough to read a few messages in a row.
private let kMaxMessages = 50

private struct AsyncRawBufferSequence: AsyncSequence, @unchecked Sendable {
    typealias Element = UInt8

    // Safe to pass across concurrency boundaries here because the buffer is read-only
    // and FuzzAsyncMessageSequence blocks on a semaphore until the consuming Task completes.
    private let bytes: UnsafeRawBufferPointer

    init(_ bytes: UnsafeRawBufferPointer) {
        self.bytes = bytes
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        private let bytes: UnsafeRawBufferPointer
        private var index = 0

        init(_ bytes: UnsafeRawBufferPointer) {
            self.bytes = bytes
        }

        mutating func next() async -> UInt8? {
            guard index < bytes.count else {
                return nil
            }
            let byte = bytes[index]
            index += 1
            return byte
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(bytes)
    }
}

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzAsyncMessageSequence(_ start: UnsafeRawPointer?, _ count: Int) -> CInt {
    // No decoding options here, a leading zero is actually valid (zero length message),
    // so we rely on the other Binary fuzz tester to test options, and just let this
    // one focus on issue around framing of the messages on the stream.
    guard count >= 0, start != nil || count == 0 else {
        return -1
    }
    let bytes = UnsafeRawBufferPointer(start: start, count: count)
    let asyncBytes = AsyncRawBufferSequence(bytes)
    let decoding = asyncBytes.binaryProtobufDelimitedMessages(
        of: SwiftProtoTesting_Fuzz_Message.self,
        extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions
    )

    let semaphore = DispatchSemaphore(value: 0)
    Task {
        defer { semaphore.signal() }
        do {
            var msgCount = 0
            for try await _ in decoding {
                // TODO: Test serialization for completeness.
                // We could serialize individual messages like this:
                // let _: [UInt8] = try! msg.serializedBytes()
                // but we don't have a stream writer which is what
                // we really want to exercise here.

                // Also, serialization here more than doubles the total
                // run time, leading to timeouts for the fuzz tester. :(

                msgCount += 1
                guard msgCount < kMaxMessages else {
                    break
                }
            }
        } catch {
            // Error parsing are to be expected since not all input will be well formed.
        }
    }
    semaphore.wait()
    return 0
}
