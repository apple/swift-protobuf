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
    repeated\ bytes)
      echo "        for _ in 0..<repeatedCount {"
      echo "          message.field$num.append(Data(repeating:$((num)), count: 20))"
      echo "        }"
      ;;
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
    bytes)
      echo "        message.field$num = Data(repeating:$((num)), count: 20)"
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
import Foundation

extension Harness {
  func run() {
    measure {
      // Loop enough times to get meaningfully large measurements.
      var message = PerfMessage()
      measureSubtask("Populate fields") {
        populateFields(of: &message)
      }

      // Exercise binary serialization.
      let data = try measureSubtask("Encode binary") {
        return try message.serializedData()
      }
      message = try measureSubtask("Decode binary") {
        return try PerfMessage(serializedData: data)
      }

      // Exercise JSON serialization.
      let json = try measureSubtask("Encode JSON") {
        return try message.jsonString()
      }
      let jsonDecodedMessage = try measureSubtask("Decode JSON") {
        return try PerfMessage(jsonString: json)
      }

      // Exercise text serialization.
      let text = try measureSubtask("Encode text") {
        return try message.textFormatString()
      }
      _ = try measureSubtask("Decode text") {
        return try PerfMessage(textFormatString: text)
      }

      // Exercise equality.
      measureSubtask("Equality") {
        guard message == jsonDecodedMessage else {
          fatalError("Binary- and JSON-decoded messages were not equal!")
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

function run_swift_harness() {
  harness="$1"

  echo "Generating Swift harness source..."
  gen_harness_path="$script_dir/_generated/Harness+Generated.swift"
  generate_swift_harness "$field_count" "$field_type"

  # Build the dynamic library to use in the tests from the .o files that were
  # already built for the plug-in.
  echo "Building SwiftProtobuf dynamic library..."
  swiftc -emit-library -O -wmo -target x86_64-apple-macosx10.10 \
      -o "$script_dir/_generated/libSwiftProtobuf.dylib" \
      "$script_dir/../Sources/SwiftProtobuf/"*.swift

  echo "Building Swift test harness..."
  time ( swiftc -O -target x86_64-apple-macosx10.10 \
      -o "$harness" \
      -I "$script_dir/../.build/release" \
      -L "$script_dir/_generated" \
      -lSwiftProtobuf \
      "$gen_harness_path" \
      "$script_dir/Harness.swift" \
      "$script_dir/_generated/message.pb.swift" \
      "$script_dir/main.swift"
  )
  echo

  dylib="$script_dir/_generated/libSwiftProtobuf.dylib"
  echo "Swift dylib size before stripping: $(stat -f "%z" "$dylib") bytes"
  cp "$dylib" "${dylib}_stripped"
  strip -u -r "${dylib}_stripped"
  echo "Swift dylib size after stripping:  $(stat -f "%z" "${dylib}_stripped") bytes"
  echo

  run_harness_and_concatenate_results "Swift" "$harness_swift" "$partial_results"
  profile_harness "Swift" "$harness_swift"
}
