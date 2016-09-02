
# How to run a 'swift' executable that supports the 'swift build', 'swift test', etc commands.
SWIFT=swift

# How to run a working version of protoc
PROTOC=protoc

# How to run awk on your system
AWK=awk

# Protos from Google's source tree that are used for testing purposes
GOOGLE_TEST_PROTOS= \
	any_test \
	descriptor \
	map_unittest \
	map_unittest_proto3 \
	unittest \
	unittest_arena \
	unittest_custom_options \
	unittest_drop_unknown_fields \
	unittest_embed_optimize_for \
	unittest_empty \
	unittest_import \
	unittest_import_lite \
	unittest_import_proto3 \
	unittest_import_public \
	unittest_import_public_lite \
	unittest_import_public_proto3 \
	unittest_lite_imports_nonlite \
	unittest_lite \
	unittest_mset \
	unittest_mset_wire_format \
	unittest_no_arena \
	unittest_no_arena_import \
	unittest_no_arena_lite \
	unittest_no_field_presence \
	unittest_no_generic_services \
	unittest_optimize_for \
	unittest_preserve_unknown_enum \
	unittest_preserve_unknown_enum2 \
	unittest_proto3 \
	unittest_proto3_arena \
	unittest_well_known_types

# Protos from Google's source tree that are embedded into
# the Protobuf library module
GOOGLE_LIBRARY_PROTOS= api duration empty field_mask source_context timestamp type

.PHONY: default all build check clean test regenerate regenerate-library-protos regenerate-test-protos regenerate-test-protos-local regenerate-test-protos-google

default: build

all: build

# This also rebuilds LinuxMain.swift to include all of the test cases
# (The awk script is very fast, so re-running it on every build is reasonable.)
build:
	${AWK} -f CollectTests.awk Tests/ProtobufTests/Test_*.swift > Tests/LinuxMain.swift
	${SWIFT} build

check test: build
	${SWIFT} test

clean:
	swift build --clean
	rm -rf .build

#
# Rebuild the generated .pb.swift test files by running
# protoc over all the relevant inputs.
#
# Before running this, ensure that:
#  * protoc-gen-swift is built and installed somewhere in your system PATH
#  * protoc is built and installed
#  * PROTOC at the top of this file is set correctly
#
regenerate: regenerate-library-protos regenerate-test-protos

# Rebuild just the protos included in the runtime library
regenerate-library-protos:
	for t in ${GOOGLE_LIBRARY_PROTOS}; do \
		echo google/protobuf/$$t.proto; \
		${PROTOC} --swift_out=Sources/Protobuf -I Protos Protos/google/protobuf/$$t.proto; \
		sed -i~ -e 's/^import Protobuf$$//' Sources/Protobuf/$$t.pb.swift; \
	done

# Rebuild just the protos used by the test suite
regenerate-test-protos: regenerate-test-protos-google regenerate-test-protos-local

# Rebuild just the protos used by the test suite that come from Google's sources
regenerate-test-protos-google:
	for t in ${GOOGLE_TEST_PROTOS}; do \
		echo google/protobuf/$$t.proto; \
		${PROTOC} --swift_out=Tests/ProtobufTests -I Protos Protos/google/protobuf/$$t.proto; \
	done; \
	echo conformance/conformance.proto; \
	${PROTOC} --swift_out=Tests/ProtobufTests -I Protos/conformance -I Protos Protos/conformance/conformance.proto; \

# Rebuild just the protos used by the test suite that come from local sources
regenerate-test-protos-local:
	for t in Protos/*.proto; do \
		echo $$t; \
		${PROTOC} --swift_out=Tests/ProtobufTests -IProtos $$t; \
	done
