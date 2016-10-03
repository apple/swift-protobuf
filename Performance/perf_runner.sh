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

function usage() {
  cat >&2 <<EOF
Usage: $0 [-p <true|false>] [-s2|-s3] <field count> <field type>

Currently supported field types:
    int32, sint32, uint32, fixed32, sfixed32,
    int64, sint64, uint64, fixed64, sfixed64,
    float, double, string,
    ...and repeated variants of the above.

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
# Functions for generating the Swift harness.

function print_swift_set_field() {
  num=$1
  type=$2

  case "$type" in
    repeated\ string)
      echo "        for _ in 0..<repeatedCount {"
      echo "          msg.field$num.append(\"$((200+num))\")"
      echo "        }"
      ;;
    repeated\ *)
      echo "        for _ in 0..<repeatedCount {"
      echo "          msg.field$num.append($((200+num)))"
      echo "        }"
      ;;
    string)
      echo "        msg.field$num = \"$((200+num))\""
      ;;
    *)
      echo "        msg.field$num = $((200+num))"
      ;;
  esac
}

function generate_perf_harness() {
  cat >"$gen_harness_path" <<EOF
extension Harness {
  func run() {
    measure {
      // Loop enough times to get meaningfully large measurements.
      for _ in 0..<200 {
        var msg = PerfMessage()
EOF

  for field_number in $(seq 1 "$field_count"); do
    print_swift_set_field "$field_number" "$field_type" >>"$gen_harness_path"
  done

  cat >>"$gen_harness_path" <<EOF
        let data = try msg.serializeProtobuf()
        msg = try PerfMessage(protobuf: data)
      }
    }
  }
}
EOF
}

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

if [[ "$#" -ne 2 ]]; then
  usage
fi

readonly field_count=$1
readonly field_type=$2
readonly script_dir="$(dirname $0)"

# Make sure the runtime and plug-in are up to date first.
( cd "$script_dir/.." >/dev/null; swift build -c release )

# Copy the newly built plugin with a new name so that we can ensure that we're
# invoking the correct one when we pass it on the command line.
cp "$script_dir/../.build/release/protoc-gen-swift" \
    "$script_dir/../.build/release/protoc-gen-swiftForPerf"

mkdir -p "$script_dir/_generated"
mkdir -p "$script_dir/_results"

gen_message_path="$script_dir/_generated/message.proto"
gen_harness_path="$script_dir/_generated/Harness+Generated.swift"
results="$script_dir/_results/$field_count fields of $field_type"
harness="$script_dir/_generated/harness"

echo "Generating test proto with $field_count fields..."
generate_test_proto "$field_count" "$field_type"

echo "Generating test harness..."
generate_perf_harness "$field_count" "$field_type"

protoc --plugin="$script_dir/../.build/release/protoc-gen-swiftForPerf" \
    --swiftForPerf_out="$script_dir/_generated" \
    "$gen_message_path"

echo "Building test harness..."
time ( swiftc -O -target x86_64-apple-macosx10.10 \
    -o "$harness" \
    -I "$script_dir/../.build/release" \
    -L "$script_dir/../.build/release" \
    -lSwiftProtobuf \
    "$gen_harness_path" \
    "$script_dir/Harness.swift" \
    "$script_dir/_generated/message.pb.swift" \
    "$script_dir/main.swift" \
)
echo

echo "Running test harness in Instruments..."
instruments -t "Time Profiler" -D "$results" "$harness"
open "$results.trace"

echo "Harness size before stripping: $(stat -f "%z" "$harness") bytes"
strip "$harness"
echo "Harness size after stripping:  $(stat -f "%z" "$harness") bytes"
