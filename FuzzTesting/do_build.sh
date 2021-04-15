#!/bin/bash

set -eu

readonly FuzzTestingDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")

cd "${FuzzTestingDir}"

FUZZ_TESTS=("FuzzBinary" "FuzzJSON" "FuzzTextFormat")
CHECK_REGRESSIONS="no"
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
    --run-regressions | --run )
      CHECK_REGRESSIONS="yes"
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
  echo "------------------------------------------------------------------------------------------"
  echo "Building: ${CMD_CONFIG}"
  echo "${CMD_BASE[@]}" -c "${CMD_CONFIG}"
  "${CMD_BASE[@]}" -c "${CMD_CONFIG}"

  if [[ "${CHECK_REGRESSIONS}" == "yes" ]] ; then
    for FUZZ_TEST in "${FUZZ_TESTS[@]}"; do
      # Don't worry about running the test cases against the right binaries, they should
      # all be able to handle any input.
      echo "------------------------------------------------------------------------------------------"
      echo "Regressing: ${FUZZ_TEST}"
      ".build/${CMD_CONFIG}/${FUZZ_TEST}" FailCases/*
    done
  fi
done
