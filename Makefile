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
# Until the flag isn't needed, add the flag to enable proto3 optional.
GENERATE_SRCS=${GENERATE_SRCS_BASE} -I Protos --experimental_allow_proto3_optional

# Where to find the Swift conformance test runner executable.
SWIFT_CONFORMANCE_PLUGIN=.build/debug/Conformance

# Where to find the conformance-test-runner. Defaults to being in your protobuf
# checkout. Invoke make with CONFORMANCE_TEST_RUNNER=[PATH_TO_BINARY] to
# override this value.
CONFORMANCE_TEST_RUNNER?=${GOOGLE_PROTOBUF_CHECKOUT}/conformance/conformance-test-runner

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
	Protos/generated_swift_names_enums.proto \
	Protos/generated_swift_names_enum_cases.proto \
	Protos/generated_swift_names_fields.proto \
	Protos/generated_swift_names_messages.proto \
	Protos/google/protobuf/any_test.proto \
	Protos/google/protobuf/map_proto2_unittest.proto \
	Protos/google/protobuf/map_unittest.proto \
	Protos/google/protobuf/test_messages_proto3.proto \
	Protos/google/protobuf/unittest.proto \
	Protos/google/protobuf/unittest_arena.proto \
	Protos/google/protobuf/unittest_custom_options.proto \
	Protos/google/protobuf/unittest_drop_unknown_fields.proto \
	Protos/google/protobuf/unittest_embed_optimize_for.proto \
	Protos/google/protobuf/unittest_empty.proto \
	Protos/google/protobuf/unittest_import.proto \
	Protos/google/protobuf/unittest_import_lite.proto \
	Protos/google/protobuf/unittest_import_public.proto \
	Protos/google/protobuf/unittest_import_public_lite.proto \
	Protos/google/protobuf/unittest_lite.proto \
	Protos/google/protobuf/unittest_lite_imports_nonlite.proto \
	Protos/google/protobuf/unittest_mset.proto \
	Protos/google/protobuf/unittest_mset_wire_format.proto \
	Protos/google/protobuf/unittest_no_field_presence.proto \
	Protos/google/protobuf/unittest_no_generic_services.proto \
	Protos/google/protobuf/unittest_optimize_for.proto \
	Protos/google/protobuf/unittest_preserve_unknown_enum.proto \
	Protos/google/protobuf/unittest_preserve_unknown_enum2.proto \
	Protos/google/protobuf/unittest_proto3.proto \
	Protos/google/protobuf/unittest_proto3_arena.proto \
	Protos/google/protobuf/unittest_proto3_optional.proto \
	Protos/google/protobuf/unittest_well_known_types.proto \
	Protos/fuzz_testing.proto \
	Protos/unittest_swift_all_required_types.proto \
	Protos/unittest_swift_cycle.proto \
	Protos/unittest_swift_enum.proto \
	Protos/unittest_swift_enum_optional_default.proto \
	Protos/unittest_swift_enum_proto3.proto \
	Protos/unittest_swift_extension.proto \
	Protos/unittest_swift_extension2.proto \
	Protos/unittest_swift_extension3.proto \
	Protos/unittest_swift_extension4.proto \
	Protos/unittest_swift_fieldorder.proto \
	Protos/unittest_swift_groups.proto \
	Protos/unittest_swift_json.proto \
	Protos/unittest_swift_naming.proto \
	Protos/unittest_swift_naming_no_prefix.proto \
	Protos/unittest_swift_naming_number_prefix.proto \
	Protos/unittest_swift_oneof_all_required.proto \
	Protos/unittest_swift_oneof_merging.proto \
	Protos/unittest_swift_performance.proto \
	Protos/unittest_swift_reserved.proto \
	Protos/unittest_swift_reserved_ext.proto \
	Protos/unittest_swift_runtime_proto2.proto \
	Protos/unittest_swift_runtime_proto3.proto \
	Protos/unittest_swift_startup.proto

# TODO: The library and plugin Protos come directly from google sources.
# There should be an easy way to copy the Google versions from a protobuf
# checkout into this project.

# Protos that are embedded into the SwiftProtobuf runtime library module
LIBRARY_PROTOS= \
	Protos/google/protobuf/any.proto \
	Protos/google/protobuf/api.proto \
	Protos/google/protobuf/descriptor.proto \
	Protos/google/protobuf/duration.proto \
	Protos/google/protobuf/empty.proto \
	Protos/google/protobuf/field_mask.proto \
	Protos/google/protobuf/source_context.proto \
	Protos/google/protobuf/struct.proto \
	Protos/google/protobuf/timestamp.proto \
	Protos/google/protobuf/type.proto \
	Protos/google/protobuf/wrappers.proto

# Protos that are used internally by the plugin
PLUGIN_PROTOS= \
	Protos/google/protobuf/compiler/plugin.proto \
	Protos/SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto

# Protos that are used by the conformance test runner.
CONFORMANCE_PROTOS= \
	Protos/conformance/conformance.proto \
	Protos/google/protobuf/test_messages_proto2.proto \
	Protos/google/protobuf/test_messages_proto3.proto

SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS= \
	Protos/pluginlib_descriptor_test.proto \
	Protos/pluginlib_descriptor_test2.proto \
	${PLUGIN_PROTOS}

SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS= \
	Protos/plugin_descriptor_test.proto

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
	update-proto-files

default: build

all: build

# This generates a LinuxMain.swift to include all of the test cases.
# It is needed for all builds before 5.4.x
# NOTE: This doesn't include Tests/protoc-gen-swiftTests because the older
# SwiftPM versions could have a test depend on an executable target.
generate-linux-main:
	@${AWK} -f DevTools/CollectTests.awk \
	    Tests/SwiftProtobufPluginLibraryTests/Test_*.swift \
	    Tests/SwiftProtobufTests/Test_*.swift \
	  > Tests/LinuxMain.swift.new
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
	rm -rf .build _test ${PROTOC_GEN_SWIFT} *DescriptorTestData.bin \
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

# Test everything (runtime, plugin)
test-all test-everything: test

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
	@rm -rf _test && mkdir _test
	for p in `find Protos/ -type f -name '*.proto'`; do \
		${GENERATE_SRCS} --tfiws_out=_test $$p || exit 1; \
	done
	diff -ru _test Reference

#
# Rebuild the reference files by running the local version of protoc-gen-swift
# against our menagerie of sample protos.
#
# If you do this, you MUST MANUALLY verify these files before checking them in,
# since the new checkin will become the new main reference.
#
# Note: Some of these protos define the same package.(message|enum)s, so they
# can't be done in a single protoc/proto-gen-swift invoke and have to be done
# one at a time instead.
reference: build ${PROTOC_GEN_SWIFT}
	@rm -rf Reference && mkdir Reference
	for p in `find Protos/ -type f -name '*.proto'`; do \
		${GENERATE_SRCS} --tfiws_out=Reference $$p || exit 1; \
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
	Tests/protoc-gen-swiftTests/DescriptorTestData.swift \
	Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift

# Rebuild just the protos included in the runtime library
regenerate-library-protos: build ${PROTOC_GEN_SWIFT}
	find Sources/SwiftProtobuf -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobuf \
		${LIBRARY_PROTOS}

# Rebuild just the protos used by the plugin
regenerate-plugin-protos: build ${PROTOC_GEN_SWIFT}
	find Sources/SwiftProtobufPluginLibrary -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobufPluginLibrary \
		${PLUGIN_PROTOS}

# Rebuild just the protos used by the runtime test suite
# Note: Some of these protos define the same package.(message|enum)s, so they
# can't be done in a single protoc/proto-gen-swift invoke and have to be done
# one at a time instead.
regenerate-test-protos: build ${PROTOC_GEN_SWIFT} Protos/generated_swift_names_enums.proto Protos/generated_swift_names_enum_cases.proto Protos/generated_swift_names_fields.proto Protos/generated_swift_names_messages.proto
	find Tests/SwiftProtobufTests -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Tests/SwiftProtobufTests \
		${TEST_PROTOS}

# Rebuild just the protos used by the plugin
regenerate-fuzz-protos: build ${PROTOC_GEN_SWIFT}
	find FuzzTesting/Sources/FuzzCommon -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=FuzzTesting/Sources/FuzzCommon \
		Protos/fuzz_testing.proto

Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS}
	# Until the flag isn't needed, add the flag to enable proto3 optional.
	@${PROTOC} \
		--experimental_allow_proto3_optional \
		--include_imports \
		--descriptor_set_out=PluginLibDescriptorTestData.bin \
		-I Protos \
		${SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS}
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let fileDescriptorSetBytes: [UInt8] = [' >> $@
	@xxd -i < PluginLibDescriptorTestData.bin >> $@
	@echo ']' >> $@
	@echo 'let fileDescriptorSetData = Data(fileDescriptorSetBytes)' >> $@

Tests/protoc-gen-swiftTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS}
	# Until the flag isn't needed, add the flag to enable proto3 optional.
	@${PROTOC} \
		--experimental_allow_proto3_optional \
		--include_imports \
		--descriptor_set_out=PluginDescriptorTestData.bin \
		-I Protos \
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
#
# Selecting lines with 'public', 'func' or 'var' ensures we get every
# public protocol, struct, enum, or class name, as well as every
# method or property defined in a public protocol, struct, or class.
# It also gives us a large collection of Swift names.
Protos/mined_words.txt: Sources/SwiftProtobuf/*.swift
	@echo Building $@
	@cat $^ | \
	grep -E '\b(public|func|var)\b' | \
	grep -vE '\b(private|internal|fileprivate)\b' | \
	sed -e 's|//.*$$||g' | \
	sed -e 's/[^a-zA-Z0-9_]/ /g' | \
	tr " " "\n" | \
	sed -e 's/^_//' | \
	sort -uf | \
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
Protos/generated_swift_names_fields.proto: Protos/mined_words.txt
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

Protos/generated_swift_names_enum_cases.proto: Protos/mined_words.txt
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

Protos/generated_swift_names_messages.proto: Protos/mined_words.txt
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

Protos/generated_swift_names_enums.proto: Protos/mined_words.txt
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
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Sources/Conformance \
		${CONFORMANCE_PROTOS}

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
	@rm -rf Protos/conformance && mkdir Protos/conformance
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/conformance/*.proto Protos/conformance/
	@rm -rf Protos/google && mkdir -p Protos/google/protobuf/compiler
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/*.proto Protos/google/protobuf/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/compiler/*.proto Protos/google/protobuf/compiler/

#
# Helper to see if update-proto-files should be done
#
check-proto-files: check-for-protobuf-checkout
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT} && ls conformance/*.proto`; do \
		diff -u "Protos/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/*.proto | grep -v test`; do \
		diff -u "Protos/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/compiler/*.proto`; do \
		diff -u "Protos/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" \
		  || (echo "ERROR: Time to do a 'make update-proto-files'" && exit 1); \
	done

# Runs the conformance tests.
test-conformance: build check-for-protobuf-checkout Sources/Conformance/failure_list_swift.txt Sources/Conformance/text_format_failure_list_swift.txt
	$(CONFORMANCE_TEST_RUNNER) \
	  --enforce_recommended \
	  --failure_list Sources/Conformance/failure_list_swift.txt \
	  --text_format_failure_list Sources/Conformance/text_format_failure_list_swift.txt\
	  $(SWIFT_CONFORMANCE_PLUGIN)
