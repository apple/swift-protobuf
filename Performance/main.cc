// Performance/main.cc - C++ performance harness entry point
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
/// Entry point for the C++ performance harness.
///
// -----------------------------------------------------------------------------

#include <fstream>

#include "Harness.h"

using std::ios_base;
using std::ofstream;

int main(int argc, char **argv) {
  ofstream* results_stream = (argc > 1) ?
      new ofstream(argv[1], ios_base::app) : nullptr;

  Harness harness(results_stream);
  harness.run();

  if (results_stream) {
    results_stream->close();
    delete results_stream;
  }

  return 0;
}
