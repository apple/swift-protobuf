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

cd "$(dirname $0)"

# Directory containing this script
readonly script_dir="."

# Change this if your checkout of github.com/google/protobuf is in a different
# location.
readonly GOOGLE_PROTOBUF_CHECKOUT=${GOOGLE_PROTOBUF_CHECKOUT:-"$script_dir/../../protobuf"}

function usage() {
  cat >&2 <<EOF
SYNOPSIS
    $0 [-c <rev|c++> -c <rev|c++> ...] [-p <true|false>] [-s2|-s3] <field count> <field types...>

    Currently supported field types:
        int32, sint32, uint32, fixed32, sfixed32,
        int64, sint64, uint64, fixed64, sfixed64,
        float, double, string,
        ...and repeated variants of the above.

        Additionally, you can specify "all" to run the harness multiple
        times with all of the (non-repeated) field types listed above.
        ("all" is not compatible with revision comparisons.)

OPTIONS
    -c <rev|c++> [-c <rev|c++> ...]
        A git revision (a commit hash, branch name, or tag) or the
        string "c++" that will be performance tested and added as a
        series in the result plot to compare against the current
        working tree state. Can be specified multiple times. The current
        working tree is always tested and included as the final series.

        If no "-c" options are specified, the working tree is compared
        against the C++ implementation.

    -p <true|false>
        If true, the generator adds a packed option to each field.
        Defaults to false.

    -s2, -s3
        Indicates whether proto2 or proto3 syntax should be generated.
        The default is proto3.

EXAMPLES
    $0 100 fixed32
        Runs the C++ harness and Swift harness in the current working
        tree using a message with 100 fixed32 fields.

    $0 -c string-speedup -p true 100 "repeated string"
        Runs the Swift harness in its state at branch "string-speedup"
        and then again in the current working tree, using a message
        with 100 packed repeated string fields.

    $0 -c 4d0b78 -c c++ -s2 100 bytes
        Runs the Swift harness in its state at commit 4d0b78, the C++
        harness, and then the Swift harness in the current working tree,
        using a proto2 message with 100 bytes fields.
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
    {
      name: "$language",
      data: {
EOF

  echo "Running $language test harness alone..."
  sleep 3
  DYLD_LIBRARY_PATH="$script_dir/_generated" "$harness" "$partial_results"
  sleep 3

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
    },
EOF
}

function profile_harness() {
  description="$1"
  harness="$2"
  perf_dir="$3"

  echo "Running $description test harness in Instruments..."
  instruments -t "$script_dir/Protobuf" -D "$results_trace" \
      "$harness" -e DYLD_LIBRARY_PATH "$perf_dir/_generated"
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

# build_swift_packages <workdir> <plugin_suffix>
#
# Builds the runtime and plug-in with Swift Package Manager, assuming the
# package manifest and sources are in <workdir>. After being built, the
# plug-in will be copied and renamed to "protoc-gen-swift<plugin_suffix>"
# in the same release directory, so that it can be guaranteed unique when
# running protoc.
function build_swift_packages() {
  workdir="$1"
  plugin_suffix="$2"
  (
    echo "Building runtime and plug-in with Swift Package Manager..."

    cd "$workdir" >/dev/null
    swift build -c release >/dev/null
    cp .build/release/protoc-gen-swift \
        ".build/release/protoc-gen-swift${plugin_suffix}"
  )
}

# ---------------------------------------------------------------
# Process command line options.

declare -a comparisons
packed=""
proto_syntax="3"

while getopts "c:p:s:" arg; do
  case "${arg}" in
    c)
      comparisons+=("$OPTARG")
      ;;
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
  # if [[ "$comparison" != "c++" ]]; then
  #   echo "ERROR: Commit-based comparison cannot be used with 'all'."
  #   echo
  #   usage
  # fi
  readonly requested_field_types=( \
    int32 sint32 uint32 fixed32 sfixed32 \
    int64 sint64 uint64 fixed64 sfixed64 \
    float double string \
  )
else
  readonly requested_field_types=( "$@" )
fi

# ---------------------------------------------------------------
# Pull in language-specific runners.
source "$script_dir/runners/swift.sh"

# ---------------------------------------------------------------
# Script main logic.

mkdir -p "$script_dir/_generated"
mkdir -p "$script_dir/_results"

# If the visualization results file isn't there, copy it from the template so
# that the harnesses can populate it.
results_js="$script_dir/_results/results.js"
if [[ ! -f "$results_js" ]]; then
  cp "$script_dir/js/results.js.template" "$results_js"
fi

# Iterate over the requested field types and run the harnesses.
# TODO: Get rid of this multi-run; instead, just create a proto like
# TestAllTypes that tests multiple field types in one message. This is more
# realistic.
for field_type in "${requested_field_types[@]}"; do
  gen_message_path="$script_dir/_generated/message.proto"

  echo "Generating test proto with $field_count fields of type $field_type..."
  generate_test_proto "$field_count" "$field_type"

  # Start a session.
  partial_results="$script_dir/_results/partial.js"
  pretty_head_rev="$(git rev-parse --abbrev-ref HEAD)"
  cat > "$partial_results" <<EOF
  {
    date: "$(date -u +"%FT%T.000Z")",
    type: "$field_count fields of type $field_type",
    branch: "$pretty_head_rev",
    commit: "$(git rev-parse HEAD)",
    uncommitted_changes: $([[ -z $(git status -s) ]] && echo false || echo true),
    series: [
EOF

  for comparison in "${comparisons[@]}"; do
    if [[ "$comparison" == "c++" ]]; then
      source "$script_dir/runners/cpp.sh"

      echo
      echo "==== Building/running C++ harness ===================="
      echo

      protoc --cpp_out="$script_dir" "$gen_message_path"

      harness_cpp="$script_dir/_generated/harness_cpp"
      results_trace="$script_dir/_results/$field_count fields of $field_type (cpp)"
      run_cpp_harness "$harness_cpp"
    else
      commit_hash="$(git rev-parse $comparison)"
      commit_results="$script_dir/_results/${commit_hash}_${field_type}_${field_count}.js"

      # Check to see if we have past results from that commit cached. If so, we
      # don't need to run it again.
      if [[ ! -f "$commit_results" ]]; then
        echo
        echo "==== Building/running Swift harness ($comparison) ===================="
        echo

        # Check out the commit to a temporary directory and create its _generated
        # directory. (Results will still go in the working tree.)
        tmp_checkout="$(mktemp -d -t swiftprotoperf)"
        git --work-tree="$tmp_checkout" checkout "$comparison" -- .
        mkdir "$tmp_checkout/Performance/_generated"

        build_swift_packages "$tmp_checkout" "ForRev"
        protoc --plugin="$tmp_checkout/.build/release/protoc-gen-swiftForRev" \
            --swiftForRev_out=FileNaming=DropPath:"$tmp_checkout/Performance/_generated" \
            "$gen_message_path"

        harness_swift="$tmp_checkout/Performance/_generated/harness_swift"
        results_trace="$script_dir/_results/$field_count fields of $field_type (swift)"
        run_swift_harness "$tmp_checkout" "$comparison" "$commit_results"

        rm -r "$tmp_checkout"
      else
        echo
        echo "==== Found cached results for Swift ($comparison) ===================="
      fi

      cat "$commit_results" >> "$partial_results"
    fi
  done

  echo
  echo "==== Building/running Swift harness (working tree) ===================="
  echo

  build_swift_packages "$script_dir/.." "ForWorkTree"
  protoc --plugin="$script_dir/../.build/release/protoc-gen-swiftForWorkTree" \
      --swiftForWorkTree_out=FileNaming=DropPath:"$script_dir/_generated" \
      --cpp_out="$script_dir" \
      "$gen_message_path"

  harness_swift="$script_dir/_generated/harness_swift"
  results_trace="$script_dir/_results/$field_count fields of $field_type (swift)"
  display_results_trace="$results_trace"
  run_swift_harness "$script_dir/.." "working tree" "$partial_results"

  # Close out the session.
  cat >> "$partial_results" <<EOF
    ],
  },
EOF

  insert_visualization_results "$partial_results" "$results_js"

  open -g "$display_results_trace.trace"
done

# Open the HTML once at the end.
open -g "$script_dir/harness-visualization.html"
