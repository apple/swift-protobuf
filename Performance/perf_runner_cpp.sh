#!/bin/bash

# SwiftProtobuf/Performance/perf_runner_cpp.sh - C++ test harness generator
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
# Functions for generating the C++ harness.
#
# -----------------------------------------------------------------------------

set -eu

function print_cpp_set_field() {
  num=$1
  type=$2

  case "$type" in
    repeated\ string)
      echo "        for (auto i = 0; i < repeated_count; i++) {"
      echo "          message.add_field$num(\"$((200+num))\");"
      echo "        }"
      ;;
    repeated\ bytes)
      echo "        for (auto i = 0; i < repeated_count; i++) {"
      echo "          message.add_field$num(std::string(20, (char)$((num))));"
      echo "        }"
      ;;
    repeated\ *)
      echo "        for (auto i = 0; i < repeated_count; i++) {"
      echo "          message.add_field$num($((200+num)));"
      echo "        }"
      ;;
    string)
      echo "        message.set_field$num(\"$((200+num))\");"
      ;;
    bytes)
      echo "        message.set_field$num(std::string(20, (char)$((num))));"
      ;;
    *)
      echo "        message.set_field$num($((200+num)));"
      ;;
  esac
}

function generate_cpp_harness() {
  cat >"$gen_harness_path" <<EOF
#include "Harness.h"
#include "message.pb.h"

#include <iostream>
#include <google/protobuf/text_format.h>
#include <google/protobuf/util/json_util.h>
#include <google/protobuf/util/message_differencer.h>
#include <google/protobuf/util/type_resolver_util.h>

using google::protobuf::Descriptor;
using google::protobuf::DescriptorPool;
using google::protobuf::TextFormat;
using google::protobuf::util::BinaryToJsonString;
using google::protobuf::util::JsonToBinaryString;
using google::protobuf::util::MessageDifferencer;
using google::protobuf::util::NewTypeResolverForDescriptorPool;
using google::protobuf::util::Status;
using google::protobuf::util::TypeResolver;
using std::cerr;
using std::endl;
using std::string;

static const char kTypeUrlPrefix[] = "type.googleapis.com";

static string GetTypeUrl(const Descriptor* message) {
  return string(kTypeUrlPrefix) + "/" + message->full_name();
}

TypeResolver* type_resolver;
string* type_url;

static void populate_fields(PerfMessage& message, int repeated_count);

void Harness::run() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

  type_resolver = NewTypeResolverForDescriptorPool(
      kTypeUrlPrefix, DescriptorPool::generated_pool());
  type_url = new string(GetTypeUrl(PerfMessage::descriptor()));

  measure([&]() {
      auto message = PerfMessage();

      measure_subtask("Populate fields", [&]() {
        populate_fields(message, repeated_count);
        // Dummy return value since void won't propagate.
        return false;
      });

      // Exercise binary serialization.
      auto data = measure_subtask("Encode binary", [&]() {
        return message.SerializeAsString();
      });
      auto decoded_message = measure_subtask("Decode binary", [&]() {
        auto result = PerfMessage();
        result.ParseFromString(data);
        return result;
      });

      // Exercise JSON serialization.
      auto json = measure_subtask("Encode JSON", [&]() {
        string out_json;
        BinaryToJsonString(type_resolver, *type_url, data, &out_json);
        return out_json;
      });
      auto decoded_binary = measure_subtask("Decode JSON", [&]() {
        string out_binary;
        JsonToBinaryString(type_resolver, *type_url, json, &out_binary);
        return out_binary;
      });

      // Exercise text serialization.
      auto text = measure_subtask("Encode text", [&]() {
        string out_text;
        TextFormat::PrintToString(message, &out_text);
        return out_text;
      });
      measure_subtask("Decode text", [&]() {
        auto result = PerfMessage();
        TextFormat::ParseFromString(text, &result);
        return result;
      });

      // Exercise equality.
      measure_subtask("Equality", [&]() {
        return MessageDifferencer::Equals(message, decoded_message);
      });
  });

  google::protobuf::ShutdownProtobufLibrary();
}

void populate_fields(PerfMessage& message, int repeated_count) {
  (void)repeated_count; /* Possibly unused: Quiet the compiler */

EOF

  for field_number in $(seq 1 "$field_count"); do
    print_cpp_set_field "$field_number" "$field_type" >>"$gen_harness_path"
  done

  cat >> "$gen_harness_path" <<EOF
}
EOF
}

function run_cpp_harness() {
  harness="$1"

  echo "Generating C++ harness source..."
  gen_harness_path="$script_dir/_generated/Harness+Generated.cc"
  generate_cpp_harness "$field_count" "$field_type"

  echo "Building C++ test harness..."
  time ( g++ --std=c++11 -O \
      -o "$harness" \
      -I "$script_dir" \
      -I "$GOOGLE_PROTOBUF_CHECKOUT/src" \
      -L "$GOOGLE_PROTOBUF_CHECKOUT/src/.libs" \
      -lprotobuf \
      "$gen_harness_path" \
      "$script_dir/Harness.cc" \
      "$script_dir/_generated/message.pb.cc" \
      "$script_dir/main.cc" \
  )
  echo

  # Make sure the dylib is loadable from the harness if the user hasn't
  # actually installed them.
  cp "$GOOGLE_PROTOBUF_CHECKOUT"/src/.libs/libprotobuf.*.dylib \
      "$script_dir/_generated"

  run_harness_and_concatenate_results "C++" "$harness" "$partial_results"
}
