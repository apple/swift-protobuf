#!/bin/bash

# SwiftProtobuf/Performance/perf_runner.swift - Performance test runner
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
# This script creates a .proto file with the requested number of fields of a
# particular type and generates a test harness that populates it, serializes
# it, and then parses it back out. Then it generates the Swift source for the
# .proto file, builds the harness, and runs it under Instruments to collect
# timing samples.
#
# The results are stored in the Performance/Results directory. The instruments
# traces are named based on the number and type of fields; multiple runs with
# the same inputs will append to the existing trace file if it is present.
#
# In addition to the collected samples, this script also prints the time it
# takes to compile/link the harness and the byte size of the harness before and
# after stripping.
#
# -----------------------------------------------------------------------------

set -eu

readonly script_dir="$(dirname $0)"

# Change this if your checkout of github.com/google/protobuf is in a different
# location.
readonly GOOGLE_PROTOBUF_CHECKOUT="$script_dir/../../protobuf"

function usage() {
  cat >&2 <<EOF
Usage: $0 [-p <true|false>] [-s2|-s3] <field count> <field types...>

Currently supported field types:
    int32, sint32, uint32, fixed32, sfixed32,
    int64, sint64, uint64, fixed64, sfixed64,
    float, double, string,
    ...and repeated variants of the above.

    Additionally, you can specify "all" to run the harness
    multiple times with all of the (non-repeated) field types
    listed above.

Options:
    -p <true|false>: Adds a packed option to each field.
    -s[23]:          Generate proto2 or proto3 syntax. proto3 is
                     the default.
EOF
  exit 1
}

# ---------------------------------------------------------------
# Functions for generating the .proto file.

function print_proto_field() {
  num="$1"
  if [[ "$proto_syntax" == "2" ]] && [[ "$field_type" != repeated* ]]; then
    type="optional $2"
  else
    type="$2"
  fi

  if [[ -n "$packed" ]]; then
    echo "  $type field$num = $num [packed=$packed];"
  else
    echo "  $type field$num = $num;"
  fi
}

function generate_test_proto() {
  cat >"$gen_message_path" <<EOF
syntax = "proto$proto_syntax";

message PerfMessage {
EOF

  for field_number in $(seq 1 "$field_count"); do
    print_proto_field "$field_number" "$field_type" >>"$gen_message_path"
  done

  cat >>"$gen_message_path" <<EOF
}
EOF
}

# ---------------------------------------------------------------
# Functions for running harnesses and collecting results.

# Executes the test harness for a language under Instruments and concatenates
# its results to the partial results file.
function run_harness_and_concatenate_results() {
  language="$1"
  harness="$2"
  partial_results="$3"

  cat >> "$partial_results" <<EOF
    "$language": {
EOF

  echo "Running $language test harness in Instruments..."
  instruments -t "$script_dir/Protobuf" -D "$results_trace" \
      "$harness" -e DYLD_LIBRARY_PATH "$script_dir/_generated" \
      "$partial_results"

  cp "$harness" "${harness}_stripped"
  strip -u -r "${harness}_stripped"
  unstripped_size=$(stat -f "%z" "$harness")
  stripped_size=$(stat -f "%z" "${harness}_stripped")

  echo "${language} harness size before stripping: $unstripped_size bytes"
  echo "${language} harness size after stripping:  $stripped_size bytes"
  echo

  cat >> "$partial_results" <<EOF
      harnessSize: {
        "Unstripped": $unstripped_size,
        "Stripped": $stripped_size,
      },
    },
EOF
}

# Inserts the partial visualization results from all the languages tested into
# the final results.js file.
function insert_visualization_results() {
  while IFS= read -r line
  do
    if [[ "$line" =~ ^//NEW-DATA-HERE$ ]]; then
      cat "$partial_results"
    fi
    echo "$line"
  done < "$results_js" > "${results_js}.new"

  rm "$results_js"
  mv "${results_js}.new" "$results_js"
}

# ---------------------------------------------------------------
# Pull in language specific helpers.
source "$script_dir/perf_runner_cpp.sh"
source "$script_dir/perf_runner_swift.sh"

# ---------------------------------------------------------------
# Script main logic.

packed=""
proto_syntax="3"

while getopts "p:s:" arg; do
  case "${arg}" in
    p)
      packed="$OPTARG"
      ;;
    s)
      proto_syntax="$OPTARG"
      ;;
  esac
done
shift "$((OPTIND-1))"

if [[ "$proto_syntax" != "2" ]] && [[ "$proto_syntax" != "3" ]]; then
  usage
fi

if [[ "$#" -lt 2 ]]; then
  usage
fi

readonly field_count="$1"; shift
if [[ "$1" == "all" ]]; then
  readonly requested_field_types=( \
    int32 sint32 uint32 fixed32 sfixed32 \
    int64 sint64 uint64 fixed64 sfixed64 \
    float double string \
  )
else
  readonly requested_field_types=( "$@" )
fi

# Make sure the runtime and plug-in are up to date first.
( cd "$script_dir/.." >/dev/null; swift build -c release )

# Copy the newly built plugin with a new name so that we can ensure that we're
# invoking the correct one when we pass it on the command line.
cp "$script_dir/../.build/release/protoc-gen-swift" \
    "$script_dir/../.build/release/protoc-gen-swiftForPerf"

mkdir -p "$script_dir/_generated"
mkdir -p "$script_dir/_results"

# If the visualization results file isn't there, copy it from the template so
# that the harnesses can populate it.
results_js="$script_dir/_results/results.js"
if [[ ! -f "$results_js" ]]; then
  cp "$script_dir/js/results.js.template" "$results_js"
fi

# Iterate over the requested field types and run the harnesses.
for field_type in "${requested_field_types[@]}"; do
  gen_message_path="$script_dir/_generated/message.proto"
  results_trace="$script_dir/_results/$field_count fields of $field_type"

  echo "Generating test proto with $field_count fields of type $field_type..."
  generate_test_proto "$field_count" "$field_type"

  protoc --plugin="$script_dir/../.build/release/protoc-gen-swiftForPerf" \
      --swiftForPerf_out=FileNaming=DropPath:"$script_dir/_generated" \
      --cpp_out="$script_dir" \
      "$gen_message_path"

  # Start a session.
  partial_results="$script_dir/_results/partial.js"
  cat > "$partial_results" <<EOF
  {
    date: "$(date -u +"%FT%T.000Z")",
    type: "$field_count fields of type $field_type",
    branch: "$(git rev-parse --abbrev-ref HEAD)",
    commit: "$(git rev-parse HEAD)",
    uncommitted_changes: $([[ -z $(git status -s) ]] && echo false || echo true),
EOF

  harness_swift="$script_dir/_generated/harness_swift"
  run_swift_harness "$harness_swift"

  harness_cpp="$script_dir/_generated/harness_cpp"
  run_cpp_harness "$harness_cpp"

  # Close out the session.
  cat >> "$partial_results" <<EOF
  },
EOF

  insert_visualization_results "$partial_results" "$results_js"

  open -g "$results_trace.trace"
done

# Open the HTML once at the end.
open -g "$script_dir/harness-visualization.html"
