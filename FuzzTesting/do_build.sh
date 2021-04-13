#!/bin/bash

set -eu

readonly FuzzTestingDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")

cd "${FuzzTestingDir}"

if [ "$(uname)" == "Darwin" ]; then
  xcrun \
    --toolchain swift \
    swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
else
  swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
fi
