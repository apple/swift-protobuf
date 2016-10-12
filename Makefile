#
# Key targets in this makefile:
#
# make build
#   Build the runtime library and plugin
# make test
#   Build everything, run both plugin and library tests:
#   Plugin test verifies that plugin output matches the "Reference" files
#      exactly
#   Library test exercises most features of the generated code
# make regenerate
#   Recompile all the necessary protos
#   (requires protoc in path)
# make test-xcode[-NAME]:
#   Runs the tests in the Xcode project in the requested mode(s).
#
# Caution: 'test' does not 'regenerate', so if you've made changes to the code
# generation, you'll need to do more than just 'test':
#    1. 'make build' to build the plugin
#    2. 'make regenerate' to rebuild the Swift code from protos using the new
#       plugin
#    3. 'make build' again to recompile everything with the regenerated protos
#    4. 'make test' to run the test suites
#

# How to run a 'swift' executable that supports the 'swift update', 'swift build',
# 'swift test', etc commands.
SWIFT=swift

# How to run a working version of protoc. Invoke make with PROTOC=[path] to
# override this value, i.e. -
#   make reference PROTOC=../protobuf/src/protoc
PROTOC=protoc

# How to run awk on your system
AWK=awk

# Installation directory
BINDIR=/usr/local/bin

INSTALL=install

PROTOC_GEN_SWIFT=.build/debug/protoc-gen-swift

# swiftX is renamed so we can ensure we're using the local version
# (instead of a previously-installed version)
PROTOC_GEN_SWIFTX=.build/debug/protoc-gen-swiftX

# Protos used for the unit and functional tests
TEST_PROTOS= \
	conformance/conformance.proto \
	google/protobuf/any_test.proto \
	google/protobuf/descriptor.proto \
	google/protobuf/map_unittest.proto \
	google/protobuf/map_unittest_proto3.proto \
	google/protobuf/unittest.proto \
	google/protobuf/unittest_arena.proto \
	google/protobuf/unittest_custom_options.proto \
	google/protobuf/unittest_drop_unknown_fields.proto \
	google/protobuf/unittest_embed_optimize_for.proto \
	google/protobuf/unittest_empty.proto \
	google/protobuf/unittest_import.proto \
	google/protobuf/unittest_import_lite.proto \
	google/protobuf/unittest_import_proto3.proto \
	google/protobuf/unittest_import_public.proto \
	google/protobuf/unittest_import_public_lite.proto \
	google/protobuf/unittest_import_public_proto3.proto \
	google/protobuf/unittest_lite.proto \
	google/protobuf/unittest_lite_imports_nonlite.proto \
	google/protobuf/unittest_mset.proto \
	google/protobuf/unittest_mset_wire_format.proto \
	google/protobuf/unittest_no_arena.proto \
	google/protobuf/unittest_no_arena_import.proto \
	google/protobuf/unittest_no_arena_lite.proto \
	google/protobuf/unittest_no_field_presence.proto \
	google/protobuf/unittest_no_generic_services.proto \
	google/protobuf/unittest_optimize_for.proto \
	google/protobuf/unittest_preserve_unknown_enum.proto \
	google/protobuf/unittest_preserve_unknown_enum2.proto \
	google/protobuf/unittest_proto3.proto \
	google/protobuf/unittest_proto3_arena.proto \
	google/protobuf/unittest_well_known_types.proto \
	swift-options.proto \
	unittest_swift_all_required_types.proto \
	unittest_swift_cycle.proto \
	unittest_swift_enum.proto \
	unittest_swift_enum_optional_default.proto \
	unittest_swift_extension.proto \
	unittest_swift_fieldorder.proto \
	unittest_swift_groups.proto \
	unittest_swift_naming.proto \
	unittest_swift_performance.proto \
	unittest_swift_reserved.proto \
	unittest_swift_runtime_proto2.proto \
	unittest_swift_runtime_proto3.proto \
	unittest_swift_startup.proto

# TODO: The library and plugin Protos come directly from google sources.
# There should be an easy way to copy the Google versions from a protobuf
# checkout into this project.

# Protos that are embedded into the SwiftProtobuf runtime library module
LIBRARY_PROTOS= \
    api \
    duration \
    empty \
    field_mask \
    source_context \
    timestamp \
    type \
    wrappers

# Protos that are used internally by the plugin
PLUGIN_PROTOS= \
	google/protobuf/compiler/plugin.proto \
	google/protobuf/descriptor.proto \
	swift-options.proto

XCODEBUILD_EXTRAS =
# Invoke make with XCODE_SKIP_OPTIMIZER=1 to suppress the optimizer when
# building the Xcode projects. For Release builds, this is a non trivial speed
# up for compilation
XCODE_SKIP_OPTIMIZER=0
ifeq "$(XCODE_SKIP_OPTIMIZER)" "1"
  XCODEBUILD_EXTRAS += SWIFT_OPTIMIZATION_LEVEL=-Onone
endif

# Invoke make with XCODE_ANALYZE=1 to enable the analyzer while building the
# Xcode projects.
XCODE_ANALYZE=0
ifeq "$(XCODE_ANALYZE)" "1"
  XCODEBUILD_EXTRAS += RUN_CLANG_STATIC_ANALYZER=YES CLANG_STATIC_ANALYZER_MODE=deep
endif

.PHONY: \
	all \
	build \
	check \
	clean \
	default \
	install \
	reference \
	regenerate \
	regenerate-library-protos \
	regenerate-plugin-protos \
	regenerate-test-protos \
	test \
	test-all \
	test-everything \
	test-plugin \
	test-runtime \
	test-xcode \
	test-xcode-debug \
	test-xcode-release \
	test-xcode-iOS \
	test-xcode-iOS-debug \
	test-xcode-iOS-release \
	test-xcode-macOS \
	test-xcode-macOS-debug \
	test-xcode-macOS-release \
	test-xcode-tvOS \
	test-xcode-tvOS-debug \
	test-xcode-tvOS-release \
	test-xcode-watchOS \
	test-xcode-watchOS-debug \
	test-xcode-watchOS-release

.NOTPARALLEL: \
	test-xcode-iOS-debug \
	test-xcode-iOS-release \
	test-xcode-macOS-debug \
	test-xcode-macOS-release \
	test-xcode-tvOS-debug \
	test-xcode-tvOS-release \
	test-xcode-watchOS-debug \
	test-xcode-watchOS-release

default: build

all: build

# This also rebuilds LinuxMain.swift to include all of the test cases
# (The awk script is very fast, so re-running it on every build is reasonable.)
# (Someday, 'swift test' will learn how to auto-discover test cases on Linux,
# at which time this will no longer be needed.)
build:
	${AWK} -f CollectTests.awk Tests/SwiftProtobufTests/Test_*.swift > Tests/LinuxMain.swift
	${SWIFT} build

${PROTOC_GEN_SWIFT}: build

install:
	${INSTALL} ${PROTOC_GEN_SWIFT} ${BINDIR}

clean:
	swift build --clean
	rm -rf .build
	rm -rf _test
	find . -name '*~' | xargs rm
	rm -rf ${PROTOC_GEN_SWIFT} ${PROTOC_GEN_SWIFTX}

#
# Test the runtime and the plugin
#
# This must pass before any commit.
#
check test: build test-runtime test-plugin

# Test everything (runtime, plugin, xcode project)
test-all test-everything: test test-xcode

#
# The Swift test suite includes unit tests for the runtime library
# and functional tests for the Swift code generated by the plugin.
#
test-runtime: build
	${SWIFT} test


${PROTOC_GEN_SWIFTX}: ${PROTOC_GEN_SWIFT}
	cp ${PROTOC_GEN_SWIFT} ${PROTOC_GEN_SWIFTX}

#
# Test the plugin by itself:
#   * Translate every proto in Protos into Swift using local protoc-gen-swift
#   * Put result in _test directory
#   * Compare output with reference output in Reference directory
#   * If generated output and reference output don't match exactly, fail.
#
# Of course, this will fail if you've made any changes to the generated output.
# In that case, you'll need to do the following before committing:
#   * `make regenerate` to rebuild the protos used by the runtime and plugin
#   * `make test-runtime` to verify that the runtime works correctly with the new changes
#   * `make reference` to update the Reference directory
#   * MANUALLY go through `git diff Reference` to verify that the generated Swift changed in the way you expect
#   * `make clean build test` to do a final check
#
test-plugin: ${PROTOC_GEN_SWIFTX}
	rm -rf _test
	for p in `cd Protos; find . -type f -name '*.proto'`; do \
		echo "==> Testing plugin for $$p"; \
		d=`dirname $$p`; b=`basename $$p .proto`; \
		mkdir -p _test/$$d; \
		${PROTOC} --plugin=${PROTOC_GEN_SWIFTX} --swiftX_out=_test/$$d -I Protos Protos/$$p || exit 1; \
		diff -u _test/$$d/$$b.pb.swift Reference/$$d/$$b.pb.swift || exit 1; \
	done

#
# Rebuild the reference files by running the local
# version of protoc-gen-swift against our menagerie
# of sample protos.
#
# If you do this, you MUST MANUALLY verify these files
# before checking them in, since the new checkin will
# become the new master reference.
#
reference: ${PROTOC_GEN_SWIFTX}
	rm -rf Reference; \
	for p in `cd Protos; find . -type f -name '*.proto'`; do \
		d=`dirname $$p`; \
		mkdir -p Reference/$$d; \
		${PROTOC} --plugin=${PROTOC_GEN_SWIFTX} --swiftX_out=Reference/$$d -I Protos Protos/$$p; \
	done

#
# Rebuild the generated .pb.swift test files by running
# protoc over all the relevant inputs.
#
# Before running this, ensure that:
#  * protoc-gen-swift is built and installed somewhere in your system PATH
#  * protoc is built and installed
#  * PROTOC at the top of this file is set correctly
#
regenerate: regenerate-library-protos regenerate-plugin-protos regenerate-test-protos

# Rebuild just the protos included in the runtime library
regenerate-library-protos: ${PROTOC_GEN_SWIFTX}
	for t in ${LIBRARY_PROTOS}; do \
		${PROTOC} --plugin=${PROTOC_GEN_SWIFTX} --swiftX_out=Sources/SwiftProtobuf -I Protos Protos/google/protobuf/$$t.proto; \
		sed -i~ -e 's/^import SwiftProtobuf$$//' Sources/SwiftProtobuf/$$t.pb.swift; \
	done

# Rebuild just the protos used by the plugin
regenerate-plugin-protos: ${PROTOC_GEN_SWIFTX}
	for t in ${PLUGIN_PROTOS}; do \
		${PROTOC} --plugin=${PROTOC_GEN_SWIFTX} --swiftX_out=Sources/PluginLibrary -I Protos Protos/$$t; \
	done

# Rebuild just the protos used by the runtime test suite
regenerate-test-protos: ${PROTOC_GEN_SWIFTX}
	for t in ${TEST_PROTOS}; do \
		${PROTOC} --plugin=${PROTOC_GEN_SWIFTX} --swiftX_out=Tests/SwiftProtobufTests -I Protos Protos/$$t; \
	done;


# Helpers to put the Xcode project through all modes.

# Grouping targets
test-xcode: test-xcode-iOS test-xcode-macOS test-xcode-tvOS test-xcode-watchOS
test-xcode-iOS: test-xcode-iOS-debug test-xcode-iOS-release
test-xcode-macOS: test-xcode-macOS-debug test-xcode-macOS-release
test-xcode-tvOS: test-xcode-tvOS-debug test-xcode-tvOS-release
test-xcode-watchOS: test-xcode-watchOS-debug test-xcode-watchOS-release
test-xcode-debug: test-xcode-iOS-debug test-xcode-macOS-debug test-xcode-tvOS-debug test-xcode-watchOS-debug
test-xcode-release: test-xcode-iOS-release test-xcode-macOS-release test-xcode-tvOS-release test-xcode-watchOS-release

# The individual ones
test-xcode-iOS-debug:
	# 4s - 32bit, 6s - 64bit
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_iOS \
	  -configuration Debug \
	  -destination "platform=iOS Simulator,name=iPhone 6s,OS=latest" \
	  -destination "platform=iOS Simulator,name=iPhone 4s,OS=9.0" \
	  test $(XCODEBUILD_EXTRAS)

test-xcode-iOS-release:
	# 4s - 32bit, 6s - 64bit
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_iOS \
	  -configuration Release \
	  -destination "platform=iOS Simulator,name=iPhone 6s,OS=latest" \
	  -destination "platform=iOS Simulator,name=iPhone 4s,OS=9.0" \
	  test $(XCODEBUILD_EXTRAS)

test-xcode-macOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_macOS \
	  -configuration debug \
	  build test $(XCODEBUILD_EXTRAS)

test-xcode-macOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_macOS \
	  -configuration Release \
	  build test $(XCODEBUILD_EXTRAS)

test-xcode-tvOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_tvOS \
	  -configuration Debug \
	  -destination "platform=tvOS Simulator,name=Apple TV 1080p,OS=latest" \
	  build test $(XCODEBUILD_EXTRAS)

test-xcode-tvOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_tvOS \
	  -configuration Release \
	  -destination "platform=tvOS Simulator,name=Apple TV 1080p,OS=latest" \
	  build test $(XCODEBUILD_EXTRAS)

test-xcode-watchOS-debug:
	# watchOS doesn't support tests
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_watchOS \
	  -configuration Debug \
	  build $(XCODEBUILD_EXTRAS)

test-xcode-watchOS-release:
	# watchOS doesn't support tests
	xcodebuild -project SwiftProtobuf.xcodeproj \
	  -scheme SwiftProtobuf_watchOS \
	  -configuration Release \
	  build $(XCODEBUILD_EXTRAS)
