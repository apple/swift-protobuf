#!/bin/bash

set -eu

readonly FuzzTestingDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")

cd "${FuzzTestingDir}"

# Default to both
CMD_CONFIGS=("debug" "release")

while [[ $# != 0 ]]; do
  case "${1}" in
    --debug )
      CMD_CONFIGS=("debug")
      ;;
    --release )
      CMD_CONFIGS=("release")
      ;;
    --both )
      CMD_CONFIGS=("debug" "release")
      ;;
    -*)
      echo "ERROR: Unknown option: ${1}" 1>&2
      exit 1
      ;;
    *)
      echo "ERROR: Unknown argument: ${1}" 1>&2
      exit 1
      ;;
  esac
  shift
done

declare -a CMD_BASE
if [ "$(uname)" == "Darwin" ]; then
  CMD_BASE=(
    xcrun
      --toolchain swift
      swift build -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
  )
else
  CMD_BASE=(
    swift build -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
  )
fi

for CMD_CONFIG in "${CMD_CONFIGS[@]}"; do
  echo "Building: ${CMD_CONFIG}"
  echo "${CMD_BASE[@]}" -c "${CMD_CONFIG}"
  "${CMD_BASE[@]}" -c "${CMD_CONFIG}"
done
