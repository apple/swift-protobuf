#!/bin/bash

# SwiftProtobuf/Performance/runners/cpp.sh - C++ test harness runner
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
# -----------------------------------------------------------------------------
#
# Functions for running the C++ harness.
#
# -----------------------------------------------------------------------------

function run_cpp_harness() {
  (
    harness="$1"

    source "$script_dir/generators/cpp.sh"

    echo "Generating C++ harness source..."
    gen_harness_path="$script_dir/_generated/Harness+Generated.cc"
    generate_cpp_harness

    echo
    echo "Building C++ libprotobuf and performance test harness..."
    echo

    pushd $script_dir/runners
    cmake -B ../_generated -S .
    cmake --build ../_generated
    popd

    run_harness_and_concatenate_results "C++" "$harness" "$partial_results"
    echo
  )
}
