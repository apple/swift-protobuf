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
#   make [TARGET] PROTOC=../protobuf/src/protoc
PROTOC=protoc

# How to run awk on your system
AWK=awk

# Installation directory
BINDIR=/usr/local/bin

# Install tool name
INSTALL=install

# Where to find a google/protobufs checkout. Defaults be being beside this
# checkout. Invoke make with GOOGLE_PROTOBUFS_CHECKOUT=[PATH_TO_CHECKOUT] to
# override this value, i.e. -
#   make [TARGET] GOOGLE_PROTOBUFS_CHECKOUT=[PATH_TO_CHECKOUT]
GOOGLE_PROTOBUFS_CHECKOUT=../protobuf

# Helpers for the common parts of source generation.
#
# To ensure that the local version of the plugin is always used (and not a
# previously installed one), we use a custom output name (-tfiws_out).
PROTOC_GEN_SWIFT=.build/debug/protoc-gen-swift
GENERATE_SRCS_BASE=${PROTOC} --plugin=protoc-gen-tfiws=${PROTOC_GEN_SWIFT}
GENERATE_SRCS=${GENERATE_SRCS_BASE} -I Protos

# Where to find the Swift conformance test runner executable.
SWIFT_CONFORMANCE_PLUGIN=.build/debug/Conformance

# If you have already build conformance-test-runner in
# a nearby directory, just set the full path here and
# we'll use it instead.
CONFORMANCE_HOST=${GOOGLE_PROTOBUFS_CHECKOUT}/conformance/conformance-test-runner

# NOTE: TEST_PROTOS, LIBRARY_PROTOS, and PLUGIN_PROTOS are all full paths so
# eventually we might be able to do proper dependencies and use them as inputs
# for other rules (we'll also likely need outputs).
#
# But since plugin is also Swift code using the runtime, there's a bit of
# recursion that doesn't lend itself to easily being resolved; as the build
# could create a new plugin that in turn could cause new sources need to
# generated, which in turns means the plugin needs to be rebuilt...
#
# It might be easier in the long run to give up on make, and instead have a
# script that does the build and then generation and checks to see if generated
# source change, and if it doesn't errors out to have the developer restart
# the process so they stabilize.

# Protos used for the unit and functional tests
TEST_PROTOS= \
	Protos/conformance/conformance.proto \
	Protos/google/protobuf/any_test.proto \
	Protos/google/protobuf/descriptor.proto \
	Protos/google/protobuf/map_unittest.proto \
	Protos/google/protobuf/map_unittest_proto3.proto \
	Protos/google/protobuf/unittest.proto \
	Protos/google/protobuf/unittest_arena.proto \
	Protos/google/protobuf/unittest_custom_options.proto \
	Protos/google/protobuf/unittest_drop_unknown_fields.proto \
	Protos/google/protobuf/unittest_embed_optimize_for.proto \
	Protos/google/protobuf/unittest_empty.proto \
	Protos/google/protobuf/unittest_import.proto \
	Protos/google/protobuf/unittest_import_lite.proto \
	Protos/google/protobuf/unittest_import_proto3.proto \
	Protos/google/protobuf/unittest_import_public.proto \
	Protos/google/protobuf/unittest_import_public_lite.proto \
	Protos/google/protobuf/unittest_import_public_proto3.proto \
	Protos/google/protobuf/unittest_lite.proto \
	Protos/google/protobuf/unittest_lite_imports_nonlite.proto \
	Protos/google/protobuf/unittest_mset.proto \
	Protos/google/protobuf/unittest_mset_wire_format.proto \
	Protos/google/protobuf/unittest_no_arena.proto \
	Protos/google/protobuf/unittest_no_arena_import.proto \
	Protos/google/protobuf/unittest_no_arena_lite.proto \
	Protos/google/protobuf/unittest_no_field_presence.proto \
	Protos/google/protobuf/unittest_no_generic_services.proto \
	Protos/google/protobuf/unittest_optimize_for.proto \
	Protos/google/protobuf/unittest_preserve_unknown_enum.proto \
	Protos/google/protobuf/unittest_preserve_unknown_enum2.proto \
	Protos/google/protobuf/unittest_proto3.proto \
	Protos/google/protobuf/unittest_proto3_arena.proto \
	Protos/google/protobuf/unittest_well_known_types.proto \
	Protos/unittest_swift_all_required_types.proto \
	Protos/unittest_swift_cycle.proto \
	Protos/unittest_swift_enum.proto \
	Protos/unittest_swift_enum_optional_default.proto \
	Protos/unittest_swift_extension.proto \
	Protos/unittest_swift_extension2.proto \
	Protos/unittest_swift_extension3.proto \
	Protos/unittest_swift_extension4.proto \
	Protos/unittest_swift_fieldorder.proto \
	Protos/unittest_swift_groups.proto \
	Protos/unittest_swift_naming.proto \
	Protos/unittest_swift_performance.proto \
	Protos/unittest_swift_reserved.proto \
	Protos/unittest_swift_runtime_proto2.proto \
	Protos/unittest_swift_runtime_proto3.proto \
	Protos/unittest_swift_startup.proto

# TODO: The library and plugin Protos come directly from google sources.
# There should be an easy way to copy the Google versions from a protobuf
# checkout into this project.

# Protos that are embedded into the SwiftProtobuf runtime library module
LIBRARY_PROTOS= \
	Protos/google/protobuf/api.proto \
	Protos/google/protobuf/duration.proto \
	Protos/google/protobuf/empty.proto \
	Protos/google/protobuf/field_mask.proto \
	Protos/google/protobuf/source_context.proto \
	Protos/google/protobuf/timestamp.proto \
	Protos/google/protobuf/type.proto \
	Protos/google/protobuf/wrappers.proto

# Protos that are used internally by the plugin
PLUGIN_PROTOS= \
	Protos/google/protobuf/compiler/plugin.proto \
	Protos/google/protobuf/descriptor.proto

# Protos that are used by the conformance test runner.
CONFORMANCE_PROTOS= \
	Protos/conformance/conformance.proto

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
	check-for-protobufs-checkout \
	clean \
	conformance-host \
	default \
	install \
	reference \
	regenerate \
	regenerate-conformance-protos \
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
	test-xcode-watchOS-release \
	update-proto-files

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

# This also rebuilds LinuxMain.swift to include all of the test cases.
# (The awk script is very fast, so re-running it on every build is reasonable,
#  but we only update the file when it changes to avoid extra builds.)
# (Someday, 'swift test' will learn how to auto-discover test cases on Linux,
# at which time this will no longer be needed.)
build:
	@${AWK} -f CollectTests.awk Tests/SwiftProtobufTests/Test_*.swift > Tests/LinuxMain.swift.new
	@if ! cmp -s Tests/LinuxMain.swift.new Tests/LinuxMain.swift; then \
		cp Tests/LinuxMain.swift.new Tests/LinuxMain.swift; \
		echo "FYI: Tests/LinuxMain.swift Updated"; \
	fi
	@rm Tests/LinuxMain.swift.new
	${SWIFT} build

# This will get run by any other rule that tries to use the plugin.  This hacks
# in a check during the library build to ensure that the protoc on the local
# system is one we expect. This was inspired by the findings that lead to
#   https://github.com/apple/swift-protobuf/issues/111
# This likely will need follow up to eventually do a pattern match to ensure it
# is 3.1 or higher.
${PROTOC_GEN_SWIFT}: build
	@if [ "$(shell ${PROTOC} --version)" != "libprotoc 3.1.0" ]; then \
	  echo "WARNING: Unexpected version of protoc: $(shell ${PROTOC} --version)"; \
	  echo "WARNING: The JSON support in generated files may not be correct."; \
	fi

# Does it really make sense to install a debug build, or should this be forcing
# a release build and then installing that instead?
install: build
	${INSTALL} ${PROTOC_GEN_SWIFT} ${BINDIR}

clean:
	swift build --clean
	rm -rf .build _test ${PROTOC_GEN_SWIFT}
	find . -name '*~' | xargs rm

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
# Note: Some of these protos define the same package.(message|enum)s, so they
# can't be done in a single protoc/proto-gen-swift invoke and have to be done
# one at a time instead.
test-plugin: build
	@rm -rf _test && mkdir _test
	for p in `find Protos -type f -name '*.proto'`; do \
		${GENERATE_SRCS} --tfiws_out=_test $$p; \
	done
	diff -ru _test Reference

#
# Rebuild the reference files by running the local version of protoc-gen-swift
# against our menagerie of sample protos.
#
# If you do this, you MUST MANUALLY verify these files before checking them in,
# since the new checkin will become the new master reference.
#
# Note: Some of these protos define the same package.(message|enum)s, so they
# can't be done in a single protoc/proto-gen-swift invoke and have to be done
# one at a time instead.
reference: build
	@rm -rf Reference && mkdir Reference
	for p in `find Protos -type f -name '*.proto'`; do \
		${GENERATE_SRCS} --tfiws_out=Reference $$p; \
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
regenerate: regenerate-library-protos regenerate-plugin-protos regenerate-test-protos regenerate-conformance-protos

# Rebuild just the protos included in the runtime library
regenerate-library-protos: build
	${GENERATE_SRCS} --tfiws_out=FileNaming=DropPath,Visibility=Public:Sources/SwiftProtobuf ${LIBRARY_PROTOS}

# Rebuild just the protos used by the plugin
regenerate-plugin-protos: build
	${GENERATE_SRCS} --tfiws_out=FileNaming=DropPath,Visibility=Public:Sources/PluginLibrary ${PLUGIN_PROTOS}

# Rebuild just the protos used by the runtime test suite
# Note: Some of these protos define the same package.(message|enum)s, so they
# can't be done in a single protoc/proto-gen-swift invoke and have to be done
# one at a time instead.
regenerate-test-protos: build
	for t in ${TEST_PROTOS}; do \
		${GENERATE_SRCS} --tfiws_out=FileNaming=DropPath:Tests/SwiftProtobufTests $$t; \
	done

# Rebuild just the protos used by the conformance test runner.
regenerate-conformance-protos: build
	${GENERATE_SRCS} --tfiws_out=FileNaming=DropPath:Sources/Conformance ${CONFORMANCE_PROTOS}

# Helper to check if there is a protobuf checkout as expected.
check-for-protobufs-checkout:
	@if [ ! -d "${GOOGLE_PROTOBUFS_CHECKOUT}/src/google/protobuf" ]; then \
	  echo "ERROR: ${GOOGLE_PROTOBUFS_CHECKOUT} does not appear to be a checkout of"; \
	  echo "ERROR:   github.com/google/protobuf. Please check it out or set"; \
	  echo "ERROR:   GOOGLE_PROTOBUFS_CHECKOUT to point to a checkout."; \
	  exit 1; \
	fi

#
# Helper to update the .proto files copied from the google/protobufs distro.
#
update-proto-files: check-for-protobufs-checkout
	@rm -rf Protos/conformance && mkdir Protos/conformance
	@cp -v "${GOOGLE_PROTOBUFS_CHECKOUT}"/conformance/*.proto Protos/conformance/
	@rm -rf Protos/google && mkdir -p Protos/google/protobuf/compiler
	@cp -v "${GOOGLE_PROTOBUFS_CHECKOUT}"/src/google/protobuf/*.proto Protos/google/protobuf/
	@cp -v "${GOOGLE_PROTOBUFS_CHECKOUT}"/src/google/protobuf/compiler/*.proto Protos/google/protobuf/compiler/
	# It would be nice to get these added to google/protobuf instead of
	# applying them locally.
	@echo 'option swift_prefix = "Proto3";' >> Protos/google/protobuf/map_unittest_proto3.proto
	@echo 'option swift_prefix = "Proto3";' >> Protos/google/protobuf/unittest_import_proto3.proto
	@echo 'option swift_prefix = "Proto3";' >> Protos/google/protobuf/unittest_import_public_proto3.proto
	@echo 'option swift_prefix = "Proto3";' >> Protos/google/protobuf/unittest_proto3.proto

SWIFT_CONFORMANCE_PLUGIN_SOURCES= \
	Sources/Conformance/conformance.pb.swift \
	Sources/Conformance/main.swift

$(SWIFT_CONFORMANCE_PLUGIN): $(SWIFT_CONFORMANCE_PLUGIN_SOURCES)
	${SWIFT} build

# Runs the conformance tests.
test-conformance: check-for-protobufs-checkout $(SWIFT_CONFORMANCE_PLUGIN) $(CONFORMANCE_HOST) failure_list_swift.txt
	( \
		ABS_PBDIR=`cd ${GOOGLE_PROTOBUFS_CHECKOUT}; pwd`; \
		$${ABS_PBDIR}/conformance/conformance-test-runner --failure_list failure_list_swift.txt $(SWIFT_CONFORMANCE_PLUGIN); \
	)

# The 'conformance-host' program is part of the protobuf project.
# It generates test cases, feeds them to our plugin, and verifies the results:
conformance-host $(CONFORMANCE_HOST): check-for-protobufs-checkout
	( \
		cd ${GOOGLE_PROTOBUFS_CHECKOUT}; \
		./configure; \
		$(MAKE) -C -j src; \
		$(MAKE) -C -j conformance; \
	)


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

# 4s - 32bit, 6s - 64bit
test-xcode-iOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_iOS \
		-configuration Debug \
		-destination "platform=iOS Simulator,name=iPhone 6s,OS=latest" \
		-destination "platform=iOS Simulator,name=iPhone 4s,OS=9.0" \
		test $(XCODEBUILD_EXTRAS)

# 4s - 32bit, 6s - 64bit
test-xcode-iOS-release:
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

# watchOS doesn't support tests, just do a build.
test-xcode-watchOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_watchOS \
		-configuration Debug \
		build $(XCODEBUILD_EXTRAS)

# watchOS doesn't support tests, just do a build.
test-xcode-watchOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_watchOS \
		-configuration Release \
		build $(XCODEBUILD_EXTRAS)
