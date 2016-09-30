// SwiftProtobuf/Performance/Harness.swift - Performance harness definition
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
/// Defines the class that runs the performance tests.
///
// -----------------------------------------------------------------------------

import Foundation

/// Harness used for performance tests.
///
/// The generator script will generate an extension to this class that adds a
/// run() method, which the main.swift file calls.
class Harness {

  /// The number of times to call append() for repeated fields.
  let repeatedCount: Int32 = 100

  /// Measures the time it takes to execute the given block. The block is
  /// executed five times and the mean/standard deviation are computed.
  func measure(block: () throws -> Void) {
    var timings = [TimeInterval]()

    do {
      // Do each measurement 5 times and collect the means and standard
      // deviation to account for noise.
      for _ in 0..<5 {
        let start = Date()
        try block()
        let end = Date()
        let diff = end.timeIntervalSince(start)
        timings.append(diff)
      }
    } catch let e {
      fatalError("Generated harness threw an error: \(e)")
    }

    let (mean, stddev) = statistics(timings)

    let runtimes = timings.map { String(format: "%.3f", $0) }.joined(separator: ", ")
    let message = "Runtimes: [\(runtimes)]\n" +
        String(format: "mean = %.3f sec, stddev = %.3f sec\n", mean, stddev)
    print(message)
  }

  /// Compute the mean and standard deviation of the given time intervals.
  private func statistics(_ timings: [TimeInterval]) ->
    (mean: TimeInterval, stddev: TimeInterval) {
    var sum: TimeInterval = 0
    var sqsum: TimeInterval = 0
    for timing in timings {
      sum += timing
      sqsum += timing * timing
    }
    let n = TimeInterval(timings.count)
    let mean = sum / n
    let variance = sqsum / n - mean * mean
    return (mean: mean, stddev: sqrt(variance))
  }
}
