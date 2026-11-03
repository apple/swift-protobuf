// Performance/Harness.swift - Performance harness definition
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Defines the class that runs the performance tests.
///
// -----------------------------------------------------------------------------

import Foundation

private func padded(_ input: String, to width: Int) -> String {
    input + String(repeating: " ", count: max(0, width - input.count))
}

/// It is expected that the generator will provide these in an extension.
protocol GeneratedHarnessMembers {
    /// The number of times to loop the body of the run() method.
    /// Increase this to get better precision.
    var runCount: Int { get }

    /// The main body of the performance harness.
    func run()
}

/// Harness used for performance tests.
///
/// The generator script will generate an extension to this class that adds a
/// run() method, which the main.swift file calls.
class Harness: GeneratedHarnessMembers {

    /// The number of times to execute the block passed to measure().
    var measurementCount = 10

    /// The number of times to call append() for repeated fields.
    let repeatedCount: Int32 = 10

    /// Ordered list of task names
    var taskNames = [String]()

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

    /// Measures the time it takes to execute the given block.
    ///
    /// The block is warmed up before any attempt is recorded, then executed
    /// `measurementCount` times. Results are summarized per subtask as a median and
    /// relative interquartile range rather than a mean: without a warmup the first
    /// attempts run several times slower than the last, and averaging them in made
    /// the old numbers swing by 25-35% between runs of the same code.
    func measure(block: () throws -> Void) {
        var timings = [TimeInterval]()
        subtaskTimings.removeAll()
        print("Running each check \(runCount) times, times in µs")

        var headingsDisplayed = false

        do {
            // Warm up until a fixed budget is spent, so that codegen, the allocator,
            // and any lazily-built decode tables have settled before the first
            // recorded attempt.
            let warmupStart = ContinuousClock.now
            repeat {
                taskNames.removeAll()
                for _ in 0..<runCount {
                    taskNames.removeAll()
                    try block()
                }
            } while ContinuousClock.now - warmupStart < .milliseconds(200)
            currentSubtasks.removeAll()

            for attempt in 1...measurementCount {
                currentSubtasks.removeAll()
                taskNames.removeAll()
                let start = ContinuousClock.now
                for _ in 0..<runCount {
                    taskNames.removeAll()
                    try block()
                }
                let diff = Harness.milliseconds(ContinuousClock.now - start)
                timings.append(diff)

                if !headingsDisplayed {
                    let names = taskNames
                    print("   ", terminator: "")
                    for (i, name) in names.enumerated() {
                        if i % 2 == 0 {
                            print(padded(name, to: 18), terminator: "")
                        }
                    }
                    print()
                    print("   ", terminator: "")
                    print(padded("", to: 9), terminator: "")
                    for (i, name) in names.enumerated() {
                        if i % 2 == 1 {
                            print(padded(name, to: 18), terminator: "")
                        }
                    }
                    print()
                    headingsDisplayed = true
                }

                print(String(format: "%3d", attempt), terminator: "")

                for name in taskNames {
                    let time = currentSubtasks[name] ?? 0
                    print(String(format: "%9.3f", time), terminator: "")
                    subtaskTimings[name] = (subtaskTimings[name] ?? []) + [time]
                }
                print()
            }
        } catch let e {
            fatalError("Generated harness threw an error: \(e)")
        }

        for (name, times) in subtaskTimings {
            writeToLog("\"\(name)\": \(times),\n")
        }

        printSubtaskSummary()

        let (mean, stddev) = statistics(timings)
        let stats =
            String(format: "Relative stddev = %.1f%%\n", (stddev / mean) * 100.0)
        print(stats)
    }

    /// Converts a `Duration` to milliseconds.
    private static func milliseconds(_ duration: Duration) -> TimeInterval {
        let c = duration.components
        return TimeInterval(c.seconds) * 1000 + TimeInterval(c.attoseconds) / 1e15
    }

    /// Prints the median, min and relative IQR for each subtask.
    ///
    /// The median is the number to compare between branches; the relative IQR says
    /// whether the run is worth believing. Anything above a few percent means the
    /// machine was contended.
    private func printSubtaskSummary() {
        print()
        print(padded("subtask", to: 20) + padded("median", to: 12) + padded("min", to: 12) + "rel IQR")
        for name in taskNames {
            guard let times = subtaskTimings[name], !times.isEmpty else { continue }
            let sorted = times.sorted()
            let median = sorted[sorted.count / 2]
            let q1 = sorted[sorted.count / 4]
            let q3 = sorted[(sorted.count * 3) / 4]
            let relativeIQR = median > 0 ? (q3 - q1) / median * 100 : 0
            print(
                padded(name, to: 20)
                    + padded(String(format: "%.3f", median), to: 12)
                    + padded(String(format: "%.3f", sorted[0]), to: 12)
                    + String(format: "%.1f%%", relativeIQR)
            )
        }
        print()
    }

    /// Measure an individual subtask whose timing will be printed separately
    /// from the main results.
    func measureSubtask<Result>(
        _ name: String,
        block: () throws -> Result
    ) rethrows -> Result {
        try autoreleasepool { () -> Result in
            taskNames.append(name)
            let start = ContinuousClock.now
            let result = try block()
            let diff = Harness.milliseconds(ContinuousClock.now - start) / Double(runCount) * 1000.0
            currentSubtasks[name] = (currentSubtasks[name] ?? 0) + diff
            return result
        }
    }

    /// Compute the mean and standard deviation of the given time intervals.
    private func statistics(_ timings: [TimeInterval]) -> (mean: TimeInterval, stddev: TimeInterval) {
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
