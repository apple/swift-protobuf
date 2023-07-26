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

# Where to find a google/protobuf checkout. Defaults be being beside this
# checkout. Invoke make with GOOGLE_PROTOBUF_CHECKOUT=[PATH_TO_CHECKOUT] to
# override this value, i.e. -
#   make [TARGET] GOOGLE_PROTOBUF_CHECKOUT=[PATH_TO_CHECKOUT]
GOOGLE_PROTOBUF_CHECKOUT?=../protobuf

# Helpers for the common parts of source generation.
#
# To ensure that the local version of the plugin is always used (and not a
# previously installed one), we use a custom output name (-tfiws_out).
PROTOC_GEN_SWIFT=.build/debug/protoc-gen-swift
GENERATE_SRCS_BASE=${PROTOC} --plugin=protoc-gen-tfiws=${PROTOC_GEN_SWIFT}
# Search 'Protos/SwiftProtobuf/' so the WKTs can be found (google/protobuf/*).
GENERATE_SRCS=${GENERATE_SRCS_BASE} -I Protos/SwiftProtobuf

# Where to find the Swift conformance test runner executable.
SWIFT_CONFORMANCE_PLUGIN=.build/debug/Conformance

# Where to find the conformance-test-runner. Defaults to being in your protobuf
# checkout. Invoke make with CONFORMANCE_TEST_RUNNER=[PATH_TO_BINARY] to
# override this value.
CONFORMANCE_TEST_RUNNER?=${GOOGLE_PROTOBUF_CHECKOUT}/conformance_test_runner

# The directories within Protos/ with the exception of "upstream". Use for the
# maintenance of the 'Reference' target and test-plugin.
PROTOS_DIRS=Conformance protoc-gen-swiftTests SwiftProtobuf SwiftProtobufPluginLibrary SwiftProtobufPluginLibraryTests SwiftProtobufTests

.PHONY: \
	all \
	build \
	check \
	check-for-protobuf-checkout \
	check-proto-files \
	check-version-numbers \
	clean \
	default \
	docs \
	install \
	reference \
	regenerate \
	regenerate-conformance-protos \
	regenerate-fuzz-protos \
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

# This generates a LinuxMain.swift to include all of the test cases.
# It is needed for all builds before 5.4.x
generate-linux-main:
	@${AWK} -f DevTools/CollectTests.awk Tests/*/Test_*.swift > Tests/LinuxMain.swift.new
	@if ! cmp -s Tests/LinuxMain.swift.new Tests/LinuxMain.swift; then \
		cp Tests/LinuxMain.swift.new Tests/LinuxMain.swift; \
		echo "FYI: Tests/LinuxMain.swift Updated"; \
	fi
	@rm Tests/LinuxMain.swift.new

# Builds all the targets of the package.
build:
	${SWIFT} build

# Anything that needs the plugin should do a build.
${PROTOC_GEN_SWIFT}: build

# Does it really make sense to install a debug build, or should this be forcing
# a release build and then installing that instead?
install: build
	${INSTALL} ${PROTOC_GEN_SWIFT} ${BINDIR}

clean:
	swift package clean
	rm -rf .build _test ${PROTOC_GEN_SWIFT} DescriptorTestData.bin \
	  Performance/_generated Performance/_results Protos/mined_words.txt \
	  docs build
	find . -name '*~' | xargs rm -f

# Build a local copy of the API documentation, using the same process used
# by cocoadocs.org.
docs:
	@if which jazzy >/dev/null; then \
		jazzy; \
	else \
		echo "Jazzy not installed, use 'gem install jazzy' or download from https://github.com/realm/jazzy"; \
	fi

#
# Test the runtime and the plugin
#
# This must pass before any commit.
#
check test: build test-runtime test-plugin test-conformance check-version-numbers

# Test everything (runtime, plugin, xcode project)
test-all test-everything: test test-xcode

# Check the version numbers are all in sync.
check-version-numbers:
	@DevTools/LibraryVersions.py --validate

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
test-plugin: build ${PROTOC_GEN_SWIFT}
	@rm -rf _test && mkdir -p _test/upstream
	for p in `find Protos/upstream -type f -name '*.proto'`; do \
		${GENERATE_SRCS_BASE} \
		  -I Protos/upstream \
		  --tfiws_out=_test/upstream $$p || exit 1; \
	done
	for d in ${PROTOS_DIRS}; do \
	    mkdir _test/$$d ; \
		${GENERATE_SRCS_BASE} \
		  -I Protos/SwiftProtobuf \
		  -I Protos/SwiftProtobufPluginLibrary \
		  -I Protos/$$d \
		  --tfiws_out=_test/$$d \
		  `find Protos/$$d -type f -name "*.proto"` || exit 1; \
	done
	diff -ru _test Reference

# Rebuild the reference files by running the local version of protoc-gen-swift
# against our menagerie of sample protos.
#
# If you do this, you MUST MANUALLY verify these files before checking them in,
# since the new checkin will become the new main reference.
#
# Note: Some of the upstream protos define the same package.(message|enum)s, so
# they can't be done in a single protoc/proto-gen-swift invoke and have to be
# done one at a time instead.
reference: build ${PROTOC_GEN_SWIFT}
	@rm -rf Reference && mkdir -p Reference/upstream
	for p in `find Protos/upstream -type f -name '*.proto'`; do \
		${GENERATE_SRCS_BASE} \
		  -I Protos/upstream \
		  --tfiws_out=Reference/upstream $$p || exit 1; \
	done
	for d in ${PROTOS_DIRS}; do \
	    mkdir Reference/$$d ; \
		${GENERATE_SRCS_BASE} \
		  -I Protos/SwiftProtobuf \
		  -I Protos/SwiftProtobufPluginLibrary \
		  -I Protos/$$d \
		  --tfiws_out=Reference/$$d \
		  `find Protos/$$d -type f -name "*.proto"` || exit 1; \
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
regenerate: \
	regenerate-library-protos \
	regenerate-fuzz-protos \
	regenerate-plugin-protos \
	regenerate-test-protos \
	regenerate-conformance-protos \
	Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift

# Rebuild just the protos included in the runtime library
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-library-protos: build ${PROTOC_GEN_SWIFT}
	find Sources/SwiftProtobuf -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobuf \
		`find Protos/SwiftProtobuf -type f -name "*.proto"`

# Rebuild just the protos used by the plugin
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-plugin-protos: build ${PROTOC_GEN_SWIFT}
	find Sources/SwiftProtobufPluginLibrary -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/SwiftProtobufPluginLibrary \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobufPluginLibrary \
		`find Protos/SwiftProtobufPluginLibrary -type f -name "*.proto"`

# Rebuild just the protos used by the runtime test suite
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-test-protos: build ${PROTOC_GEN_SWIFT} Protos/SwiftProtobufTests/generated_swift_names_enums.proto Protos/SwiftProtobufTests/generated_swift_names_enum_cases.proto Protos/SwiftProtobufTests/generated_swift_names_fields.proto Protos/SwiftProtobufTests/generated_swift_names_messages.proto
	find Tests/SwiftProtobufTests -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/SwiftProtobufTests \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Tests/SwiftProtobufTests \
		`find Protos/SwiftProtobufTests -type f -name "*.proto"`

# Rebuild the protos for FuzzTesting/Sources/FuzzCommon, the file lives in the
# Protos/SwiftProtobufTests to have just one copy.
regenerate-fuzz-protos: build ${PROTOC_GEN_SWIFT}
	find FuzzTesting/Sources/FuzzCommon -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/SwiftProtobufTests \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=FuzzTesting/Sources/FuzzCommon \
		Protos/SwiftProtobufTests/fuzz_testing.proto

SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS= \
	Protos/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_test.proto \
	Protos/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_test2.proto \
	Protos/SwiftProtobufPluginLibrary/google/protobuf/compiler/plugin.proto \
	Protos/SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto

Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${SWIFT_DESCRIPTOR_TEST_PROTOS}
	# Until the flag isn't needed, add the flag to enable proto3 optional.
	@${PROTOC} \
		--experimental_allow_proto3_optional \
		--include_imports \
		--descriptor_set_out=PluginLibDescriptorTestData.bin \
		-I Protos/SwiftProtobuf \
		-I Protos/SwiftProtobufPluginLibrary \
		-I Protos/SwiftProtobufPluginLibraryTests \
		${SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS}
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let fileDescriptorSetBytes: [UInt8] = [' >> $@
	@xxd -i < PluginLibDescriptorTestData.bin >> $@
	@echo ']' >> $@
	@echo 'let fileDescriptorSetData = Data(fileDescriptorSetBytes)' >> $@

SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS= \
       Protos/protoc-gen-swiftTests/plugin_descriptor_test.proto

Tests/protoc-gen-swiftTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS}
	@${PROTOC} \
		--include_imports \
		--descriptor_set_out=PluginDescriptorTestData.bin \
		-I Protos/protoc-gen-swiftTests \
		${SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS}
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let fileDescriptorSetBytes: [UInt8] = [' >> $@
	@xxd -i < PluginDescriptorTestData.bin >> $@
	@echo ']' >> $@
	@echo 'let fileDescriptorSetData = Data(fileDescriptorSetBytes)' >> $@

#
# Collect a list of words that appear in the SwiftProtobuf library
# source.  These are words that may cause problems for generated code.
#
# The logic here builds a word list as follows:
#  = Look at every Swift source file in the library
#  = Take every line with the word 'public', 'func', or 'var'
#  = Remove any comments from the line.
#  = Break each such line into words (stripping all punctuation)
#  = Remove words that differ only in case
#  = Remove anything that will cause proto parsing issues (things named "reserved")
#
# Selecting lines with 'public', 'func' or 'var' ensures we get every
# public protocol, struct, enum, or class name, as well as every
# method or property defined in a public protocol, struct, or class.
# It also gives us a large collection of Swift names.
Protos/mined_words.txt: Sources/SwiftProtobuf/*
	@echo Building $@
	@cat Sources/SwiftProtobuf/* | \
	grep -E '\b(public|func|var)\b' | \
	grep -vE '\b(private|internal|fileprivate)\b' | \
	sed -e 's|//.*$$||g' | \
	sed -e 's/[^a-zA-Z0-9_]/ /g' | \
	tr " " "\n" | \
	sed -e 's/^_//' | \
	sort -uf | \
	grep -vE '(reserved)' | \
	grep '^[a-zA-Z_]' > $@

# Build some proto files full of landmines
#
# This takes the word list Protos/mined_words.txt and uses
# it to build several proto files:
#  = Build a message with one `int32` field for each word
#  = Build an enum with a case for each such word
#  = Build a message with a submessage named with each word
#  = Build a message with an enum named with each word
#
# If the Swift compiler can actually compile the result, that suggests
# we can correctly handle every symbol in the library itself that
# might cause problems.  Failures compiling this indicate weaknesses
# in protoc-gen-swift's name sanitization logic.
#
Protos/SwiftProtobufTests/generated_swift_names_fields.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package protobuf_unittest_generated;' >> $@
	@echo 'message GeneratedSwiftReservedFields {' >> $@
	@cat Protos/mined_words.txt | awk 'BEGIN{n = 1} {print "  int32 " $$1 " = " n ";"; n += 1 }' >> $@
	@echo '}' >> $@

Protos/SwiftProtobufTests/generated_swift_names_enum_cases.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package protobuf_unittest_generated;' >> $@
	@echo 'enum GeneratedSwiftReservedEnum {' >> $@
	@echo '  NONE = 0;' >> $@
	@cat Protos/mined_words.txt | awk 'BEGIN{n = 1} {print "  " $$1 " = " n ";"; n += 1 }' >> $@
	@echo '}' >> $@

Protos/SwiftProtobufTests/generated_swift_names_messages.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package protobuf_unittest_generated;' >> $@
	@echo 'message GeneratedSwiftReservedMessages {' >> $@
	@cat Protos/mined_words.txt | awk '{print "  message " $$1 " { int32 " $$1 " = 1; }"}' >> $@
	@echo '}' >> $@

Protos/SwiftProtobufTests/generated_swift_names_enums.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package protobuf_unittest_generated;' >> $@
	@echo 'message GeneratedSwiftReservedEnums {' >> $@
	@cat Protos/mined_words.txt | awk '{print "  enum " $$1 " { NONE_" $$1 " = 0; }"}' >> $@
	@echo '}' >> $@

# Rebuild just the protos used by the conformance test runner.
regenerate-conformance-protos: build ${PROTOC_GEN_SWIFT}
	find Sources/Conformance -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/Conformance \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Sources/Conformance \
		`find Protos/Conformance -type f -name "*.proto"`

# Helper to check if there is a protobuf checkout as expected.
check-for-protobuf-checkout:
	@if [ ! -d "${GOOGLE_PROTOBUF_CHECKOUT}/src/google/protobuf" ]; then \
	  echo "ERROR: ${GOOGLE_PROTOBUF_CHECKOUT} does not appear to be a checkout of"; \
	  echo "ERROR:   github.com/protocolbuffers/protobuf. Please check it out or set"; \
	  echo "ERROR:   GOOGLE_PROTOBUF_CHECKOUT to point to a checkout."; \
	  exit 1; \
	fi

#
# Helper to update the .proto files copied from the protocolbuffers/protobuf distro.
#
update-proto-files: check-for-protobuf-checkout
	@rm -rf Protos/upstream
	@mkdir -p Protos/upstream/conformance Protos/upstream/google/protobuf/compiler
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/conformance/*.proto Protos/upstream/conformance/
	@mkdir -p Protos/upstream/google/protobuf/compiler
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/*.proto Protos/upstream/google/protobuf/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/compiler/*.proto Protos/upstream/google/protobuf/compiler/
	# Now copy into the Proto directories for the local targets.
	@rm -rf Protos/Conformance/conformance && mkdir -p Protos/Conformance/conformance
	@cp -v Protos/upstream/conformance/*.proto Protos/Conformance/conformance
	@rm -rf Protos/Conformance/google && mkdir -p Protos/Conformance/google/protobuf
	@cp -v \
	  Protos/upstream/google/protobuf/test_messages_proto2.proto \
	  Protos/upstream/google/protobuf/test_messages_proto3.proto \
	  Protos/Conformance/google/protobuf/
	@rm -rf Protos/SwiftProtobuf/google && mkdir -p Protos/SwiftProtobuf/google/protobuf
	@cp -v \
	  Protos/upstream/google/protobuf/timestamp.proto \
	  Protos/upstream/google/protobuf/field_mask.proto \
	  Protos/upstream/google/protobuf/api.proto \
	  Protos/upstream/google/protobuf/duration.proto \
	  Protos/upstream/google/protobuf/struct.proto \
	  Protos/upstream/google/protobuf/wrappers.proto \
	  Protos/upstream/google/protobuf/source_context.proto \
	  Protos/upstream/google/protobuf/any.proto \
	  Protos/upstream/google/protobuf/type.proto \
	  Protos/upstream/google/protobuf/empty.proto \
	  Protos/upstream/google/protobuf/descriptor.proto \
	  Protos/SwiftProtobuf/google/protobuf
	@rm -rf Protos/SwiftProtobufPluginLibrary/google && mkdir -p Protos/SwiftProtobufPluginLibrary/google/protobuf/compiler
	@cp -v Protos/upstream/google/protobuf/compiler/*.proto Protos/SwiftProtobufPluginLibrary/google/protobuf/compiler

#
# Helper to see if update-proto-files should be done
#
check-proto-files: check-for-protobuf-checkout
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT} && ls conformance/*.proto`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/*.proto | grep -v test`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/compiler/*.proto`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done

# Runs the conformance tests.

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
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_iOS \
		-configuration Debug \
		-destination "platform=iOS Simulator,name=iPhone 8,OS=latest" \
		-disable-concurrent-destination-testing \
		test $(XCODEBUILD_EXTRAS)

# Release defaults to not supporting testing, so add ENABLE_TESTABILITY=YES
# to ensure the main library gets testing support.
test-xcode-iOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_iOS \
		-configuration Release \
		-destination "platform=iOS Simulator,name=iPhone 8,OS=latest" \
		-disable-concurrent-destination-testing \
		test ENABLE_TESTABILITY=YES $(XCODEBUILD_EXTRAS)

test-xcode-macOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_macOS \
		-configuration Debug \
		build test $(XCODEBUILD_EXTRAS)

# Release defaults to not supporting testing, so add ENABLE_TESTABILITY=YES
# to ensure the main library gets testing support.
test-xcode-macOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_macOS \
		-configuration Release \
		build test ENABLE_TESTABILITY=YES $(XCODEBUILD_EXTRAS)

test-xcode-tvOS-debug:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_tvOS \
		-configuration Debug \
		-destination "platform=tvOS Simulator,name=Apple TV,OS=latest" \
		build test $(XCODEBUILD_EXTRAS)

# Release defaults to not supporting testing, so add ENABLE_TESTABILITY=YES
# to ensure the main library gets testing support.
test-xcode-tvOS-release:
	xcodebuild -project SwiftProtobuf.xcodeproj \
		-scheme SwiftProtobuf_tvOS \
		-configuration Release \
		-destination "platform=tvOS Simulator,name=Apple TV,OS=latest" \
		build test ENABLE_TESTABILITY=YES $(XCODEBUILD_EXTRAS)

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

test-conformance: build check-for-protobuf-checkout Sources/Conformance/failure_list_swift.txt Sources/Conformance/text_format_failure_list_swift.txt
	$(CONFORMANCE_TEST_RUNNER) \
	  --enforce_recommended \
	  --failure_list Sources/Conformance/failure_list_swift.txt \
	  --text_format_failure_list Sources/Conformance/text_format_failure_list_swift.txt\
	  $(SWIFT_CONFORMANCE_PLUGIN)
