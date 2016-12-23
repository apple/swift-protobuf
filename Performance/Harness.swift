// Performance/Harness.swift - Performance harness definition
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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

  /// The number of times to execute the block passed to measure().
  var measurementCount = 10

  /// The number of times to loop the body of the run() method.
  var runCount = 100

  /// The number of times to call append() for repeated fields.
  let repeatedCount: Int32 = 10

  /// The times taken by subtasks during each measured attempt.
  var subtaskTimings = [String: [TimeInterval]]()

  /// Times for the subtasks in the current attempt.
  var currentSubtasks = [String: TimeInterval]()

  /// The file to which results should be written.
  let resultsFile: FileHandle?

  /// Creates a new harness that writes its statistics to the given file
  /// (as well as to stdout).
  init(resultsFile: FileHandle?) {
    self.resultsFile = resultsFile
  }

  /// Measures the time it takes to execute the given block. The block is
  /// executed five times and the mean/standard deviation are computed.
  func measure(block: () throws -> Void) {
    var timings = [TimeInterval]()
    subtaskTimings.removeAll()

    do {
      // Do each measurement 5 times and collect the means and standard
      // deviation to account for noise.
      for attempt in 1...measurementCount {
        print("Attempt \(attempt), \(runCount) runs:")
        currentSubtasks.removeAll()

        let start = Date()
        try block()
        let end = Date()
        let diff = end.timeIntervalSince(start) * 1000
        timings.append(diff)

        for (name, time) in currentSubtasks {
          print(String(format: "\"%@\" took %.3f ms", name, time))

          if var timings = subtaskTimings[name] {
            timings.append(time)
            subtaskTimings[name] = timings
          } else {
            subtaskTimings[name] = [time]
          }
        }
        print(String(format: "Total execution time: %.3f ms\n", diff))
        print("----")
      }
    } catch let e {
      fatalError("Generated harness threw an error: \(e)")
    }

    for (name, times) in subtaskTimings {
      writeToLog("\"\(name)\": \(times),\n")
    }

    let (mean, stddev) = statistics(timings)
    let stats =
        String(format: "mean = %.3f ms, stddev = %.3f ms\n", mean, stddev)
    print(stats)
  }

  /// Measure an individual subtask whose timing will be printed separately
  /// from the main results.
  func measureSubtask<Result>(
    _ name: String,
    block: () throws -> Result
  ) rethrows -> Result {
    let start = Date()
    let result = try block()
    let end = Date()
    let diff = end.timeIntervalSince(start) * 1000
    currentSubtasks[name] = (currentSubtasks[name] ?? 0) + diff
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

  /// Writes a string to the data results file that will be parsed by the
  /// calling script to produce visualizations.
  private func writeToLog(_ string: String) {
    if let resultsFile = resultsFile {
      let utf8 = Data(string.utf8)
      resultsFile.write(utf8)
    }
  }
}
