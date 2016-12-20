#!/bin/bash

# SwiftProtobuf/Performance/multi_perf_runner.swift - Multi-perf test runner
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
# Helper script to run the perf harness multiple times over all (unrepeated)
# data types.
#
# Usage is the same as perf_runner.sh, but with the field type omitted. All the
# other arguments will be passed directly to each perf_runner.sh invocation.
#
# -----------------------------------------------------------------------------

set -eu

readonly script_dir="$(dirname $0)"

readonly field_types=( \
  int32 sint32 uint32 fixed32 sfixed32 \
  int64 sint64 uint64 fixed64 sfixed64 \
  float double string \
)

for field_type in "${field_types[@]}"; do
  "$script_dir"/perf_runner.sh "$@" "$field_type"
done
