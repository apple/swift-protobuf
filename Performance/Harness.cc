// Performance/Harness.cc - C++ performance harness definition
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

#include <chrono>
#include <cstdio>
#include <cmath>
#include <iostream>
#include <string>
#include <type_traits>
#include <vector>

#include "Harness.h"

using std::chrono::duration_cast;
using std::chrono::steady_clock;
using std::endl;
using std::function;
using std::ostream;
using std::result_of;
using std::sqrt;
using std::string;
using std::vector;

Harness::Harness(std::ostream* results_stream) :
    results_stream(results_stream),
    measurement_count(10),
    run_count(100),
    repeated_count(100) {}

void Harness::write_to_log(const string& name,
                           const vector<milliseconds_d>& timings) const {
  if (results_stream == nullptr) {
    return;
  }

  (*results_stream) << "\"" << name << "\": [";
  for (const auto& duration : timings) {
    auto millis = duration_cast<milliseconds_d>(duration);
    (*results_stream) << millis.count() << ", ";
  }
  (*results_stream) << "]," << endl;
}

Harness::Statistics Harness::compute_statistics(
    const vector<steady_clock::duration>& timings) const {
  milliseconds_d::rep sum = 0;
  milliseconds_d::rep sqsum = 0;

  for (const auto& duration : timings) {
    auto millis = duration_cast<milliseconds_d>(duration);
    auto count = millis.count();
    sum += count;
    sqsum += count * count;
  }

  auto n = timings.size();
  Statistics stats;
  stats.mean = sum / n;
  stats.stddev = sqrt(sqsum / n - stats.mean * stats.mean);
  return stats;
}
