// Benchmarks/Sources/BenchSupport.swift - timing and reporting
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Measurement core for the (de)serialization benchmarks, discarding the first few
/// "cold" iterations.
///
// -----------------------------------------------------------------------------

import Foundation

let baselineLabel = ProcessInfo.processInfo.environment["SP_BASELINE"] ?? "unknown"

/// Number of timed repetitions per measurement. Odd so the median is a real sample.
let repetitions = Int(ProcessInfo.processInfo.environment["SP_REPETITIONS"] ?? "") ?? 9

/// Minimum wall-clock a warmup phase must burn before timing starts.
let warmupDuration = Duration.milliseconds(200)

func nanos(_ d: Duration) -> Double {
    let c = d.components
    return Double(c.seconds) * 1e9 + Double(c.attoseconds) / 1e9
}

/// A single measurement: median/min per-operation nanoseconds over `repetitions`.
struct Measurement {
    let perOpNanosMedian: Double
    let perOpNanosMin: Double
    /// Interquartile range as a fraction of the median. This is a stability signal.
    /// A high value means the machine was contended and you must discard the run.
    let relativeIQR: Double
}

/// Runs `body` -- which performs `opsPerBatch` operations -- warmed up, then timed
/// `repetitions` times.
func measure(opsPerBatch: Int, _ body: () throws -> Void) rethrows -> Measurement {
    // Warm up until the loop uses `warmupDuration`. Codegen, the allocator and any
    // lazily-built decode tables then settle before the first timed batch.
    let warmupStart = ContinuousClock.now
    repeat {
        try body()
    } while ContinuousClock.now - warmupStart < warmupDuration

    var perOp: [Double] = []
    perOp.reserveCapacity(repetitions)
    for _ in 0..<repetitions {
        let start = ContinuousClock.now
        try body()
        let elapsed = ContinuousClock.now - start
        perOp.append(nanos(elapsed) / Double(opsPerBatch))
    }
    perOp.sort()

    let median = perOp[perOp.count / 2]
    let q1 = perOp[perOp.count / 4]
    let q3 = perOp[(perOp.count * 3) / 4]
    return Measurement(
        perOpNanosMedian: median,
        perOpNanosMin: perOp[0],
        relativeIQR: median > 0 ? (q3 - q1) / median : 0
    )
}

/// Emits one machine-readable line per measurement for the driver to collate.
func report(type: String, op: String, messages: Int, _ m: Measurement) {
    let fields = [
        "baseline=\(baselineLabel)",
        "type=\(type)",
        "op=\(op)",
        "messages=\(messages)",
        "per_op_ns=\(String(format: "%.2f", m.perOpNanosMedian))",
        "per_op_ns_min=\(String(format: "%.2f", m.perOpNanosMin))",
        "rel_iqr=\(String(format: "%.4f", m.relativeIQR))",
    ]
    print("KV " + fields.joined(separator: " "))
}
