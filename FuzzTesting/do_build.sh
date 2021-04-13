#!/bin/bash

set -eu

readonly FuzzTestingDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")

cd "${FuzzTestingDir}"

if [ "$(uname)" == "Darwin" ]; then
  xcrun \
    --toolchain swift \
    swift build -c release -Xswiftc -sanitize=fuzzer -Xswiftc -parse-as-library
else
  swift build -c release -Xswiftc -sanitize=fuzzer -Xswiftc -parse-as-library
fi
