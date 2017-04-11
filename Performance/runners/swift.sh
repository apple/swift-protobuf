#!/bin/bash

# SwiftProtobuf/Performance/runners/swift.sh - Swift test harness runner
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
# Functions for generating the Swift harness.
#
# -----------------------------------------------------------------------------

function run_swift_harness() {
  # Wrapped in a subshell to prevent state from leaking out (important since
  # this gets run multiple times during a comparison).
  (
    root_dir="$1"
    description="$2"
    results_file="$3"

    perf_dir="$root_dir/Performance"
    harness="$perf_dir/_generated/harness_swift"

    # Load the generator from perf_dir so that we use the comparison revision
    # instead of the working copy if we're running an older checkout.
    source "$perf_dir/generators/swift.sh"

    echo "Generating Swift harness source..."
    gen_harness_path="$perf_dir/_generated/Harness+Generated.swift"
    generate_swift_harness

    # Build the dynamic library to use in the tests.
    # TODO: Make the dylib a product again in the package manifest and just use
    # that.
    echo "Building SwiftProtobuf dynamic library..."
    xcrun -sdk macosx swiftc -emit-library -emit-module -O -wmo \
        -o "$perf_dir/_generated/libSwiftProtobuf.dylib" \
        "$perf_dir/../Sources/SwiftProtobuf/"*.swift

    echo "Building Swift test harness..."
    time ( xcrun -sdk macosx swiftc -O \
        -o "$harness" \
        -I "$perf_dir/_generated" \
        -L "$perf_dir/_generated" \
        -lSwiftProtobuf \
        "$gen_harness_path" \
        "$perf_dir/Harness.swift" \
        "$perf_dir/_generated/message.pb.swift" \
        "$perf_dir/main.swift"
    )
    echo

    dylib="$perf_dir/_generated/libSwiftProtobuf.dylib"
    echo "Swift dylib size before stripping: $(stat -f "%z" "$dylib") bytes"
    cp "$dylib" "${dylib}_stripped"
    strip -u -r "${dylib}_stripped"
    echo "Swift dylib size after stripping:  $(stat -f "%z" "${dylib}_stripped") bytes"
    echo

    run_harness_and_concatenate_results "Swift ($description)" "$harness" "$results_file"
    profile_harness "Swift ($description)" "$harness" "$perf_dir"
  )
}
