#!/bin/bash

set -eu

readonly FuzzTestingDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")

printUsage() {
  NAME=$(basename "${0}")
  cat << EOF
usage: ${NAME} [OPTIONS]

This script builds (and can run) the fuzz tests.

OPTIONS:

 General:

   -h, --help
         Show this message
   --debug-only
         Just build the 'debug' configuration.
   --release-only
         Just build the 'release' configuration.
   --both
         Build both the 'debug' and 'release' configurations. This is
         the default.
   --run-regressions, --run
         After building, also run all the fuzz tests against the known fail
         cases.

EOF
}

FUZZ_TESTS=(
  "FuzzBinary"
  "FuzzBinaryDelimited"
  "FuzzAsyncMessageSequence"
  "FuzzJSON"
  "FuzzTextFormat"
)
RUN_TESTS="yes"
CHECK_REGRESSIONS="no"
# Default to both
CMD_CONFIGS=("debug" "release")

while [[ $# != 0 ]]; do
  case "${1}" in
    -h | --help )
      printUsage
      exit 0
      ;;
    --debug-only )
      CMD_CONFIGS=("debug")
      ;;
    --release-only )
      CMD_CONFIGS=("release")
      ;;
    --both )
      CMD_CONFIGS=("debug" "release")
      ;;
    --run-regressions | --run )
      CHECK_REGRESSIONS="yes"
      ;;
    --skip-tests )
      RUN_TESTS="no"
      ;;
    -*)
      echo "ERROR: Unknown option: ${1}" 1>&2
      printUsage
      exit 1
      ;;
    *)
      echo "ERROR: Unknown argument: ${1}" 1>&2
      printUsage
      exit 1
      ;;
  esac
  shift
done

cd "${FuzzTestingDir}"

if [[ "${RUN_TESTS}" == "yes" ]] ; then
  echo "------------------------------------------------------------------------------------------"
  echo "Testing: swift test"
  swift test
fi

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
