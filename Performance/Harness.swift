// Performance/Harness.swift - Performance harness definition
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

  /// The number of times to loop the body of the run() method.
  var runCount = 100

  /// The number of times to call append() for repeated fields.
  let repeatedCount: Int32 = 100

  var subtasks = [String: TimeInterval]()

  /// Measures the time it takes to execute the given block. The block is
  /// executed five times and the mean/standard deviation are computed.
  func measure(block: () throws -> Void) {
    var timings = [TimeInterval]()

    do {
      // Do each measurement 5 times and collect the means and standard
      // deviation to account for noise.
      for attempt in 1...5 {
        print("Attempt \(attempt), \(runCount) runs:")
        subtasks.removeAll()

        let start = Date()
        try block()
        let end = Date()
        let diff = end.timeIntervalSince(start)
        timings.append(diff)

        for (name, time) in subtasks {
          print(String(format: "\"%@\" took %.3f sec", name, time))
        }
        print(String(format: "Total execution time: %.3f sec\n", diff))
        print("----")
      }
    } catch let e {
      fatalError("Generated harness threw an error: \(e)")
    }

    let (mean, stddev) = statistics(timings)

    let stats =
        String(format: "mean = %.3f sec, stddev = %.3f sec\n", mean, stddev)
    print(stats)
  }

  /// Measure an individual subtask whose timing will be printed separately from the main results.
  func measureSubtask<Result>(_ name: String, block: () throws -> Result) rethrows -> Result {
    let start = Date()
    let result = try block()
    let end = Date()
    let diff = end.timeIntervalSince(start)
    subtasks[name] = (subtasks[name] ?? 0) + diff
    return result
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
