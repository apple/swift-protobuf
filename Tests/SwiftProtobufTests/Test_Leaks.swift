// Tests/SwiftProtobufTests/Test_Leaks.swift - Proto3 coding/decoding
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Detect memory leaks in the SwiftProtobuf runtime.
///
/// To enable this, you must be on macOS and run `DETECT_LEAKS=1 swift test`
/// (without `--parallel`, see below). (`DETECT_LEAKS` only needs to be set;
/// the value does not matter.)
///
/// Fuzz testing does this for us on Linux (since it enables ASan), but when
/// doing local development on macOS, it's helpful to have a way to explicitly
/// check for them without reaching for Instruments. Unfortunately the `leaks`
/// tool does not report leaks by default for .xctest bundles run under the
/// `xctest` tool, so we have to use this trick of invoking `leaks` with the
/// current PID in an `atexit` handler. If leaks are detected, we'll print the
/// output and exit with a failure code.
///
/// Note that this only works for serialized test runs (i.e., `swift test`
/// without the `--parallel` flag), because serialized runs are run in a single
/// process whereas `--parallel` spawns multiple processes with subsets of
/// tests.
///
// -----------------------------------------------------------------------------

#if os(macOS)

import Foundation
import XCTest

final class Test_Leaks: XCTestCase {
    func test_registerLeaksCheck() {
        guard getenv("DETECT_LEAKS") != nil else {
            return
        }
        // Since this is a global variable, it will only be initialized once. This ensures that the
        // installed `atexit` handler only runs once, even if the test runs multiple times for some
        // reason.
        _ = checkLeaks
    }
}

let checkLeaks = {
    atexit {
        // We run `leaks` twice; first to determine if there actually were any leaks, and then
        // again if the first run indicated that there were leaks, this time writing to stderr
        // so that the user sees the output. This is honestly easier than using `Process`'s APIs to
        // capture the output into a string the first time.
        let process = computeLeaks(writingOutputTo: "/dev/null")
        let exitCode = process.terminationStatus
        guard process.terminationReason == .exit && [0, 1].contains(exitCode) else {
            print(
                """
                ================
                Unexpected termination from leaks:

                Reason: \(process.terminationReason)
                Exit code: \(exitCode)
                """
            )
            exit(255)
        }
        if exitCode == 1 {
            print("================")
            print("Memory leaks detected!")
            _ = computeLeaks(writingOutputTo: "/dev/stderr")
        }
        exit(exitCode)
    }
}()

func computeLeaks(writingOutputTo path: String) -> Process {
    let outputHandle = FileHandle(forWritingAtPath: path)!
    let process = Process()
    process.launchPath = "/usr/bin/leaks"
    process.arguments = ["\(getpid())"]
    process.standardOutput = outputHandle
    process.standardError = outputHandle
    process.launch()
    process.waitUntilExit()
    return process
}

#endif  // os(macOS)
