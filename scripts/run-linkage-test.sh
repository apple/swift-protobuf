#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the AsyncHTTPClient open source project
##
## Copyright (c) 2026 Apple Inc. and the AsyncHTTPClient project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of AsyncHTTPClient project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##
set -eu

# Validate that we're running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: This script must be run on Linux. Current OS: $(uname -s)" >&2
    exit 1
fi

echo "Running on Linux - proceeding with linkage test..."

# Build the linkage test package
echo "Building linkage test package..."
swift build --package-path Tests/LinkageTest

# Construct build path
build_path=$(swift build --package-path Tests/LinkageTest --show-bin-path)
binary_path=$build_path/linkageTest

# Verify the binary exists
if [[ ! -f "$binary_path" ]]; then
    echo "Error: Built binary not found at $binary_path" >&2
    exit 1
fi

echo "Checking linkage for binary: $binary_path"

# Run ldd and check if libFoundation.so is linked
ldd_output=$(ldd "$binary_path")
echo "LDD output:"
echo "$ldd_output"

if echo "$ldd_output" | grep -q "libFoundation.so"; then
    echo "Error: Binary is linked against libFoundation.so - this indicates incorrect linkage. Ensure the full Foundation is not linked on Linux when default traits are disabled." >&2
    exit 1
else
    echo "Success: Binary is not linked against libFoundation.so - linkage test passed."
fi
