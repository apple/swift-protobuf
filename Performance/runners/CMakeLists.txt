#
# cmake configuration file for building the C++ test harness
#
# This assumes you have a protobuf source checkout handy,
# and have used `git submodule update` to obtain all the
# related source repos.
#
# This script uses the protobuf sources to build libprotobuf and
# statically links it into the test harness executable.
# (This is probably not necessary; updates to this file to
# use a better strategy would be appreciated.)
#
# Also assumes that you have abseil_cpp and googletest installed
# locally via e.g.,
#   brew install googletest
#   brew install abseil
#

cmake_minimum_required(VERSION 3.10...3.26)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

project(swiftprotobuf-perf C CXX)

# Update this with the appropriate path to the protobuf source
# checkout, starting from the directory holding this file.
# Default here assumes that `protobuf` is checked out beside
# `swift-protobuf`
set(protobuf_SOURCE_DIR ${CMAKE_SOURCE_DIR}/../../../protobuf)
set(protobuf_VERSION "999.999")

# Use protobuf cmake scripts to locate suitable abseil package:
set(protobuf_ABSL_PROVIDER "package")
include(${protobuf_SOURCE_DIR}/cmake/abseil-cpp.cmake)

# Use protobuf cmake scripts for building libprotobuf
include(${protobuf_SOURCE_DIR}/cmake/libprotobuf.cmake)

# Use utf8_range from protobuf checkout
set(utf8_range_SOURCE_DIR ${protobuf_SOURCE_DIR}/third_party/utf8_range)
add_subdirectory(${utf8_range_SOURCE_DIR} third_party/utf8_range)

include_directories(
  ${protobuf_SOURCE_DIR}/src
  ${utf8_range_SOURCE_DIR}
)

add_executable(harness_cpp
  ../main.cc
  ../Harness.cc
  ../_generated/Harness+Generated.cc
  ../_generated/message.pb.cc
)

target_include_directories(harness_cpp PRIVATE
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/..
  ${ABSL_ROOT_DIR}
  ${utf8_range_SOURCE_DIR}
)

target_link_libraries(harness_cpp PRIVATE libprotobuf)
