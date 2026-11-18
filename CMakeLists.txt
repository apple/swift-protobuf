cmake_minimum_required(VERSION 3.16)
project(protobuf
  LANGUAGES Swift)

if(CMAKE_Swift_COMPILER_VERSION AND CMAKE_Swift_COMPILER_VERSION VERSION_LESS 6.2)
  message(FATAL_ERROR "SwiftProtobuf requires Swift 6.2 or later (found ${CMAKE_Swift_COMPILER_VERSION})")
endif()

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

include(SwiftSupport)

add_subdirectory(Sources)
