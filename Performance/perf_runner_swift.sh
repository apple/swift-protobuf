#!/bin/bash

# SwiftProtobuf/Performance/perf_runner_swift.sh - Swift test harness generator
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

set -eu

function print_swift_set_field() {
  num=$1
  type=$2

  case "$type" in
    repeated\ string)
      echo "        for _ in 0..<repeatedCount {"
      echo "          message.field$num.append(\"$((200+num))\")"
      echo "        }"
      ;;
    repeated\ *)
      echo "        for _ in 0..<repeatedCount {"
      echo "          message.field$num.append($((200+num)))"
      echo "        }"
      ;;
    string)
      echo "        message.field$num = \"$((200+num))\""
      ;;
    *)
      echo "        message.field$num = $((200+num))"
      ;;
  esac
}

function generate_swift_harness() {
  cat >"$gen_harness_path" <<EOF
extension Harness {
  func run() {
    measure {
      // Loop enough times to get meaningfully large measurements.
      for _ in 0..<runCount {
        var message = PerfMessage()
        measureSubtask("Populate message fields") {
          populateFields(of: &message)
        }

        // Exercise binary serialization.
        let data = try measureSubtask("Encode binary") {
          return try message.serializeProtobuf()
        }
        message = try measureSubtask("Decode binary") {
          return try PerfMessage(protobuf: data)
        }

        // Exercise JSON serialization.
        let json = try measureSubtask("Encode JSON") {
          return try message.serializeJSON()
        }
        let jsonDecodedMessage = try measureSubtask("Decode JSON") {
          return try PerfMessage(json: json)
        }

        // Exercise equality.
        measureSubtask("Test equality") {
          guard message == jsonDecodedMessage else {
            fatalError("Binary- and JSON-decoded messages were not equal!")
          }
        }
      }
    }
  }

  private func populateFields(of message: inout PerfMessage) {
EOF

  for field_number in $(seq 1 "$field_count"); do
    print_swift_set_field "$field_number" "$field_type" >>"$gen_harness_path"
  done

  cat >> "$gen_harness_path" <<EOF
  }
}
EOF
}

function build_swift_harness() {
  harness="$1"

  echo "Generating Swift harness source..."
  gen_harness_path="$script_dir/_generated/Harness+Generated.swift"
  generate_swift_harness "$field_count" "$field_type"

  echo "Building Swift test harness..."
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
}

function print_swift_harness_sizes() {
  harness="$1"

  echo "Swift harness size before stripping: $(stat -f "%z" "$harness") bytes"
  strip -u -r "$harness"
  echo "Swift harness size after stripping:  $(stat -f "%z" "$harness") bytes"
  echo
}
