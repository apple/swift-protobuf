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

# How to run a working version of protoc. By default, we build our own copy
# from the submodule using Swift Package Manager. Invoke make with PROTOC=[path]
# to override this value, i.e. -
#   make [TARGET] PROTOC=../protobuf/src/protoc
PROTOC?=.build/debug/protoc

# How to run awk on your system
AWK=awk

# Installation directory
BINDIR=/usr/local/bin

# Install tool name
INSTALL=install

# Where to find a google/protobuf checkout. Defaults to the submodule.
# Invoke make with GOOGLE_PROTOBUF_CHECKOUT=[PATH_TO_CHECKOUT] to
# override this value, i.e. -
#   make [TARGET] GOOGLE_PROTOBUF_CHECKOUT=[PATH_TO_CHECKOUT]
GOOGLE_PROTOBUF_CHECKOUT?=Sources/protobuf/protobuf

# Helpers for the common parts of source generation.
#
# To ensure that the local version of the plugin is always used (and not a
# previously installed one), we use a custom output name (-tfiws_out).
PROTOC_GEN_SWIFT=.build/debug/protoc-gen-swift
# Need to provide paths to find the language specific editions features files
# also. If we used a released protoc distro, they would be bundled like the WKTs.
GENERATE_SRCS_BASE=${PROTOC} --plugin=protoc-gen-tfiws=${PROTOC_GEN_SWIFT} -I Protos/upstream/go -I Protos/upstream/java/core/src/main/resources
# Search 'Protos/Sources/SwiftProtobuf/' so the WKTs can be found (google/protobuf/*).
GENERATE_SRCS=${GENERATE_SRCS_BASE} -I Protos/Sources/SwiftProtobuf

# Where to find the Swift conformance test runner executable.
SWIFT_CONFORMANCE_PLUGIN=.build/debug/Conformance

# Where to find the conformance-test-runner. Defaults to being in your protobuf
# checkout when built with CMake. Invoke make with
# CONFORMANCE_TEST_RUNNER=[PATH_TO_BINARY] to override this value.
CONFORMANCE_TEST_RUNNER?=${GOOGLE_PROTOBUF_CHECKOUT}/cmake_build/conformance_test_runner

# Hook to pass arge to swift build|test (mainly for the CI setup)
SWIFT_BUILD_TEST_HOOK?=

# The directories within Protos/ with the exception of "upstream". Use for the
# maintenance of the 'Reference' target and test-plugin.
PROTOS_DIRS=Sources/Conformance Sources/SwiftProtobuf Sources/SwiftProtobufPluginLibrary Tests/protoc-gen-swiftTests Tests/SwiftProtobufPluginLibraryTests Tests/SwiftProtobufTests

.PHONY: \
	all \
	build \
	check \
	check-for-conformance-runner \
	check-for-protobuf-checkout \
	check-proto-files \
	check-version-numbers \
	clean \
	compile-tests \
	compile-tests-multimodule \
	compile-tests-internalimportsbydefault \
	default \
	docs \
	install \
	pod-lib-lint \
	reference \
	regenerate \
	regenerate-compiletests-multimodule-protos \
	copy-compiletests-internalimportsbydefault-protos \
	regenerate-compiletests-protos \
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
	test-spm-plugin \
	update-proto-files

default: build

all: build

# Builds all the targets of the package.
build:
	${SWIFT} build ${SWIFT_BUILD_TEST_HOOK}

# Anything that needs the plugin should do a build.
${PROTOC_GEN_SWIFT}: build

# Build our local copy of protoc from the submodule
${PROTOC}: build

# Does it really make sense to install a debug build, or should this be forcing
# a release build and then installing that instead?
install: build
	${INSTALL} ${PROTOC_GEN_SWIFT} ${BINDIR}

clean:
	${SWIFT} package clean
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
	${SWIFT} test ${SWIFT_BUILD_TEST_HOOK}

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
test-plugin: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	@rm -rf _test && mkdir -p _test/upstream
	for p in `find Protos/upstream -type f -name '*.proto'`; do \
		${GENERATE_SRCS_BASE} \
		  -I Protos/upstream \
		  --tfiws_out=_test/upstream $$p || exit 1; \
	done
	for d in ${PROTOS_DIRS}; do \
	    mkdir -p _test/$$d ; \
		${GENERATE_SRCS_BASE} \
		  -I Protos/Sources/SwiftProtobuf \
		  -I Protos/Sources/SwiftProtobufPluginLibrary \
		  -I Protos/$$d \
		  --tfiws_out=_test/$$d \
		  `find Protos/$$d -type f -name "*.proto"` || exit 1; \
	done
	@mkdir -p _test/CompileTests/MultiModule
	${GENERATE_SRCS} \
	    -I Protos/CompileTests/MultiModule \
		--tfiws_opt=Visibility=Public \
		--tfiws_opt=ProtoPathModuleMappings=Protos/CompileTests/MultiModule/module_mappings.pbascii \
		--tfiws_out=_test/CompileTests/MultiModule \
		`(find Protos/CompileTests/MultiModule -type f -name "*.proto")`
	@mkdir -p _test/CompileTests/InternalImportsByDefault
	${GENERATE_SRCS} \
	    -I Protos/CompileTests/InternalImportsByDefault \
		--tfiws_opt=Visibility=Public \
		--tfiws_opt=UseAccessLevelOnImports=true \
		--tfiws_out=_test/CompileTests/InternalImportsByDefault \
		`(find Protos/CompileTests/InternalImportsByDefault -type f -name "*.proto")`
	diff -ru _test Reference

# Test the SPM plugin.
test-spm-plugin:
	${SWIFT} test --package-path PluginExamples

compile-tests: \
	compile-tests-multimodule \
	compile-tests-internalimportsbydefault

# Test that ensures generating public into multiple modules with `import public`
# yields buildable code.
compile-tests-multimodule:
	${SWIFT} test --package-path CompileTests/MultiModule

# Test that ensures that using access level modifiers on imports yields code that's buildable
# when `InternalImportsByDefault` is enabled on the module.
compile-tests-internalimportsbydefault:
	${SWIFT} build --package-path CompileTests/InternalImportsByDefault


# Rebuild the reference files by running the local version of protoc-gen-swift
# against our menagerie of sample protos.
#
# If you do this, you MUST MANUALLY verify these files before checking them in,
# since the new checkin will become the new main reference.
#
# Note: Some of the upstream protos define the same package.(message|enum)s, so
# they can't be done in a single protoc/proto-gen-swift invoke and have to be
# done one at a time instead.
reference: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	@rm -rf Reference && mkdir -p Reference/upstream
	for p in `find Protos/upstream -type f -name '*.proto'`; do \
		${GENERATE_SRCS_BASE} \
		  -I Protos/upstream \
		  --tfiws_out=Reference/upstream $$p || exit 1; \
	done
	for d in ${PROTOS_DIRS}; do \
	    mkdir -p Reference/$$d ; \
		${GENERATE_SRCS_BASE} \
		  -I Protos/Sources/SwiftProtobuf \
		  -I Protos/Sources/SwiftProtobufPluginLibrary \
		  -I Protos/$$d \
		  --tfiws_out=Reference/$$d \
		  `find Protos/$$d -type f -name "*.proto"` || exit 1; \
	done
	@mkdir -p Reference/CompileTests/MultiModule
	${GENERATE_SRCS} \
	    -I Protos/CompileTests/MultiModule \
		--tfiws_opt=Visibility=Public \
		--tfiws_opt=ProtoPathModuleMappings=Protos/CompileTests/MultiModule/module_mappings.pbascii \
		--tfiws_out=Reference/CompileTests/MultiModule \
		`(find Protos/CompileTests/MultiModule -type f -name "*.proto")`
	@mkdir -p Reference/CompileTests/InternalImportsByDefault
	${GENERATE_SRCS} \
	    -I Protos/CompileTests/InternalImportsByDefault \
		--tfiws_opt=Visibility=Public \
		--tfiws_opt=UseAccessLevelOnImports=true \
		--tfiws_out=Reference/CompileTests/InternalImportsByDefault \
		`(find Protos/CompileTests/InternalImportsByDefault -type f -name "*.proto")`

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
	regenerate-compiletests-protos \
	regenerate-conformance-protos \
	Sources/SwiftProtobufPluginLibrary/PluginLibEditionDefaults.swift \
	Tests/protoc-gen-swiftTests/DescriptorTestData.swift \
	Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift \
	Tests/SwiftProtobufPluginLibraryTests/PluginLibTestingEditionDefaults.swift

# Rebuild just the protos included in the runtime library
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-library-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	find Sources/SwiftProtobuf -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobuf \
		`find Protos/Sources/SwiftProtobuf -type f -name "*.proto"`

# Rebuild just the protos used by the plugin
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-plugin-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	find Sources/SwiftProtobufPluginLibrary -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/Sources/SwiftProtobufPluginLibrary \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=Sources/SwiftProtobufPluginLibrary \
		`find Protos/Sources/SwiftProtobufPluginLibrary -type f -name "*.proto"`

# Is this based on the upstream bazel rules `compile_edition_defaults` and
# `embed_edition_defaults`.
Sources/SwiftProtobufPluginLibrary/PluginLibEditionDefaults.swift: build ${PROTOC_GEN_SWIFT} ${PROTOC} Protos/Sources/SwiftProtobuf/google/protobuf/descriptor.proto
	@${PROTOC} \
		--edition_defaults_out=PluginLibEditionDefaults.bin \
		--edition_defaults_minimum=PROTO2 \
		--edition_defaults_maximum=2024 \
		-I Protos/Sources/SwiftProtobuf \
		Protos/Sources/SwiftProtobuf/google/protobuf/descriptor.proto
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let bundledFeatureSetDefaultBytes: [UInt8] = [' >> $@
	@xxd -i < PluginLibEditionDefaults.bin >> $@
	@echo ']' >> $@

# Some defaults for the testing of custom features
Tests/SwiftProtobufPluginLibraryTests/PluginLibTestingEditionDefaults.swift: build ${PROTOC_GEN_SWIFT} ${PROTOC} Protos/Tests/SwiftProtobufPluginLibraryTests/test_features.proto
	@${PROTOC} \
		--edition_defaults_out=PluginLibTestingEditionDefaults.bin \
		--edition_defaults_minimum=PROTO2 \
		--edition_defaults_maximum=2024 \
		-I Protos/Sources/SwiftProtobuf \
		-I Protos/Tests/SwiftProtobufPluginLibraryTests \
		Protos/Tests/SwiftProtobufPluginLibraryTests/test_features.proto
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let testFeatureSetDefaultBytes: [UInt8] = [' >> $@
	@xxd -i < PluginLibTestingEditionDefaults.bin >> $@
	@echo ']' >> $@

# Rebuild just the protos used by the tests
# NOTE: dependencies doesn't include the source .proto files, should fix that;
# would also need to list all the outputs.
regenerate-test-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC} Protos/Tests/SwiftProtobufTests/generated_swift_names_enums.proto Protos/Tests/SwiftProtobufTests/generated_swift_names_enum_cases.proto Protos/Tests/SwiftProtobufTests/generated_swift_names_fields.proto Protos/Tests/SwiftProtobufTests/generated_swift_names_messages.proto
	find Tests/SwiftProtobufTests -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/Tests/SwiftProtobufTests \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Tests/SwiftProtobufTests \
		`find Protos/Tests/SwiftProtobufTests -type f -name "*.proto"`
	find Tests/SwiftProtobufPluginLibraryTests -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
		-I Protos/Tests/SwiftProtobufPluginLibraryTests \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Tests/SwiftProtobufPluginLibraryTests \
		`find Protos/Tests/SwiftProtobufPluginLibraryTests -type f -name "*.proto"`

# Rebuild the protos for FuzzTesting/Sources/FuzzCommon, the file lives in the
# Protos/Tests/SwiftProtobufTests to have just one copy.
regenerate-fuzz-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	find FuzzTesting/Sources/FuzzCommon -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/Tests/SwiftProtobufTests \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_opt=Visibility=Public \
		--tfiws_out=FuzzTesting/Sources/FuzzCommon \
		Protos/Tests/SwiftProtobufTests/fuzz_testing.proto

SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS= \
	Protos/Tests/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_test.proto \
	Protos/Tests/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_test2.proto \
	Protos/Tests/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_test_import.proto \
	Protos/Tests/SwiftProtobufPluginLibraryTests/pluginlib_descriptor_delimited.proto \
	Protos/Tests/SwiftProtobufPluginLibraryTests/unittest_delimited.proto \
	Protos/Tests/SwiftProtobufPluginLibraryTests/unittest_delimited_import.proto \
	Protos/Sources/SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto

Tests/SwiftProtobufPluginLibraryTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${PROTOC} ${SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS}
	@${PROTOC} \
		--include_source_info \
		--descriptor_set_out=PluginLibDescriptorTestData.bin \
		-I Protos/Sources/SwiftProtobuf \
		-I Protos/Sources/SwiftProtobufPluginLibrary \
		-I Protos/Tests/SwiftProtobufPluginLibraryTests \
		${SWIFT_PLUGINLIB_DESCRIPTOR_TEST_PROTOS}
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let fileDescriptorSetBytes: [UInt8] = [' >> $@
	@xxd -i < PluginLibDescriptorTestData.bin >> $@
	@echo ']' >> $@

SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS= \
       Protos/Tests/protoc-gen-swiftTests/plugin_descriptor_test.proto

Tests/protoc-gen-swiftTests/DescriptorTestData.swift: build ${PROTOC_GEN_SWIFT} ${PROTOC} ${SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS}
	@${PROTOC} \
		--descriptor_set_out=PluginDescriptorTestData.bin \
		-I Protos/Tests/protoc-gen-swiftTests \
		${SWIFT_PLUGIN_DESCRIPTOR_TEST_PROTOS}
	@rm -f $@
	@echo '// See Makefile how this is generated.' >> $@
	@echo '// swift-format-ignore-file' >> $@
	@echo 'import Foundation' >> $@
	@echo 'let fileDescriptorSetBytes: [UInt8] = [' >> $@
	@xxd -i < PluginDescriptorTestData.bin >> $@
	@echo ']' >> $@

#
# Collect a list of words that appear in the SwiftProtobuf library
# source.  These are words that may cause problems for generated code.
#
# The logic here builds a word list as follows:
#  = Look at every Swift source file in the library
#  = Take every line with the word 'public', 'func', or 'var'
#  = Remove any comments from the line.
#  = Remove any string literals from the line.
#  = Break each such line into words (stripping all punctuation)
#  = Remove words that differ only in case
#  = Remove anything that will cause proto parsing issues (things named "reserved")
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
	sed -e 's|"\([^"\\]*\\.\)*[^"]*"||g' | \
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
Protos/Tests/SwiftProtobufTests/generated_swift_names_fields.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package swift_proto_testing.generated;' >> $@
	@echo 'message GeneratedSwiftReservedFields {' >> $@
	@cat Protos/mined_words.txt | ${AWK} 'BEGIN{n = 1} {print "  int32 " $$1 " = " n ";"; n += 1 }' >> $@
	@echo '}' >> $@

Protos/Tests/SwiftProtobufTests/generated_swift_names_enum_cases.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package swift_proto_testing.generated;' >> $@
	@echo 'enum GeneratedSwiftReservedEnum {' >> $@
	@echo '  NONE = 0;' >> $@
	@cat Protos/mined_words.txt | ${AWK} 'BEGIN{n = 1} {print "  " $$1 " = " n ";"; n += 1 }' >> $@
	@echo '}' >> $@

Protos/Tests/SwiftProtobufTests/generated_swift_names_messages.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package swift_proto_testing.generated;' >> $@
	@echo 'message GeneratedSwiftReservedMessages {' >> $@
	@cat Protos/mined_words.txt | ${AWK} '{print "  message " $$1 " { int32 " $$1 " = 1; }"}' >> $@
	@echo '}' >> $@

Protos/Tests/SwiftProtobufTests/generated_swift_names_enums.proto: Protos/mined_words.txt
	@echo Building $@
	@rm $@
	@echo '// See Makefile for the logic that generates this' >> $@
	@echo '// Protoc errors imply this file is being generated incorrectly' >> $@
	@echo '// Swift compile errors are probably bugs in protoc-gen-swift' >> $@
	@echo 'syntax = "proto3";' >> $@
	@echo 'package swift_proto_testing.generated;' >> $@
	@echo 'message GeneratedSwiftReservedEnums {' >> $@
	@cat Protos/mined_words.txt | ${AWK} '{print "  enum " $$1 " { NONE_" $$1 " = 0; }"}' >> $@
	@echo '}' >> $@

# Rebuild just the protos used by the conformance test runner.
regenerate-conformance-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	find Sources/Conformance -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/Sources/Conformance \
		--tfiws_opt=FileNaming=DropPath \
		--tfiws_out=Sources/Conformance \
		`find Protos/Sources/Conformance -type f -name "*.proto"`

# Rebuild just the protos used by the CompileTests.
regenerate-compiletests-protos: \
	regenerate-compiletests-multimodule-protos \
	copy-compiletests-internalimportsbydefault-protos

# Update the CompileTests/MultiModule files.
# NOTE: Any changes here must also be done on the "test-plugin" target so it
# generates in the same way.
regenerate-compiletests-multimodule-protos: build ${PROTOC_GEN_SWIFT} ${PROTOC}
	find CompileTests/MultiModule -name "*.pb.swift" -exec rm -f {} \;
	${GENERATE_SRCS} \
	    -I Protos/CompileTests/MultiModule \
		--tfiws_opt=Visibility=Public \
		--tfiws_opt=ProtoPathModuleMappings=Protos/CompileTests/MultiModule/module_mappings.pbascii \
		--tfiws_out=CompileTests/MultiModule \
		`(find Protos/CompileTests/MultiModule -type f -name "*.proto")`

# We use the plugin for the InternalImportsByDefault test, so we don't actually need to regenerate
# anything. However, to keep the protos centralised in a single place (the Protos directory),
# this simply copies those files to the InternalImportsByDefault package in case they change.
copy-compiletests-internalimportsbydefault-protos:
	@cp Protos/CompileTests/InternalImportsByDefault/* CompileTests/InternalImportsByDefault/Sources/InternalImportsByDefault/Protos

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
# (We also have to pick up some the the [LANG]_features.proto files for language
# specific Editions, if when generating we used a release protoc, then they would
# be copied like the WKTs to live "next too" the compiler and we wouldn't need to
# provide them on input paths.)
#
update-proto-files: check-for-protobuf-checkout
	@rm -rf Protos/upstream
	@mkdir -p \
	  Protos/upstream/conformance/test_protos \
	  Protos/upstream/google/protobuf/compiler \
	  Protos/upstream/editions/golden \
	  Protos/upstream/go/google/protobuf \
	  Protos/upstream/java/core/src/main/resources/google/protobuf
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/conformance/*.proto Protos/upstream/conformance/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/conformance/test_protos/*.proto Protos/upstream/conformance/test_protos/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/*.proto Protos/upstream/google/protobuf/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/src/google/protobuf/compiler/*.proto Protos/upstream/google/protobuf/compiler/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/editions/golden/test_messages_proto?_editions.proto Protos/upstream/editions/golden/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/go/google/protobuf/*_features.proto Protos/upstream/go/google/protobuf/
	@cp -v "${GOOGLE_PROTOBUF_CHECKOUT}"/java/core/src/main/resources/google/protobuf/*_features.proto Protos/upstream/java/core/src/main/resources/google/protobuf/
	# Now copy into the Proto directories for the local targets.
	@rm -rf Protos/Sources/Conformance/conformance/test_protos && mkdir -p Protos/Sources/Conformance/conformance/test_protos
	@cp -v Protos/upstream/conformance/*.proto Protos/Sources/Conformance/conformance
	@cp -v Protos/upstream/conformance/test_protos/*.proto Protos/Sources/Conformance/conformance/test_protos
	@rm -rf Protos/Sources/Conformance/google && mkdir -p Protos/Sources/Conformance/google/protobuf Protos/Sources/Conformance/editions
	@cp -v \
	  Protos/upstream/google/protobuf/test_messages_proto2.proto \
	  Protos/upstream/google/protobuf/test_messages_proto3.proto \
	  Protos/Sources/Conformance/google/protobuf/
	@cp -v \
	  Protos/upstream/editions/golden/test_messages_proto2_editions.proto \
	  Protos/upstream/editions/golden/test_messages_proto3_editions.proto \
	  Protos/Sources/Conformance/editions/
	@rm -rf Protos/Sources/SwiftProtobuf/google && mkdir -p Protos/Sources/SwiftProtobuf/google/protobuf
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
	  Protos/Sources/SwiftProtobuf/google/protobuf
	@rm -rf Protos/Sources/SwiftProtobufPluginLibrary/google && mkdir -p Protos/Sources/SwiftProtobufPluginLibrary/google/protobuf/compiler
	@cp -v Protos/upstream/google/protobuf/compiler/*.proto Protos/Sources/SwiftProtobufPluginLibrary/google/protobuf/compiler

#
# Helper to see if update-proto-files should be done
#
# Usually want to also provide `GOOGLE_PROTOBUF_CHECKOUT=some_local_head_protobuf` so
# you are checking against a state this project hasn't adopted yet.
#
# Since there are multiple things to check we direct the diffs all into a file and check
# at the end.
check-proto-files: check-for-protobuf-checkout
	@rm -f _check_protos.txt && touch _check_protos.txt
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT} && ls conformance/*.proto conformance/test_protos/*.proto`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/$$p" >> _check_protos.txt; \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/*.proto | grep -v test`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" >> _check_protos.txt; \
	done
	@for p in `cd ${GOOGLE_PROTOBUF_CHECKOUT}/src && ls google/protobuf/compiler/*.proto`; do \
		diff -u "Protos/upstream/$$p" "${GOOGLE_PROTOBUF_CHECKOUT}/src/$$p" >> _check_protos.txt; \
	done
	@if [ -s _check_protos.txt ] ; then \
	    cat _check_protos.txt; \
	    rm -f _check_protos.txt; \
	    echo "ERROR: Time to do a 'make update-proto-files'"; \
	    exit 1; \
	else \
	    rm -f _check_protos.txt; \
	fi

check-for-conformance-runner:
	@if [ ! -x "${CONFORMANCE_TEST_RUNNER}" ]; then \
	  echo "ERROR: ${CONFORMANCE_TEST_RUNNER} does not appear to exist"; \
	  echo "ERROR:   built build it or set CONFORMANCE_TEST_RUNNER to point"; \
	  echo "ERROR:   a runner."; \
	  exit 1; \
	fi

# Runs the conformance tests.
test-conformance: check-for-conformance-runner build Sources/Conformance/failure_list_swift.txt Sources/Conformance/text_format_failure_list_swift.txt
	$(CONFORMANCE_TEST_RUNNER) \
	  --enforce_recommended \
	  --failure_list Sources/Conformance/failure_list_swift.txt \
	  --text_format_failure_list Sources/Conformance/text_format_failure_list_swift.txt \
	  --maximum_edition 2024 \
	  $(SWIFT_CONFORMANCE_PLUGIN)

# Validate the CocoaPods podspec file against the current tree state.
pod-lib-lint:
	@if [ `uname -s` = "Darwin" ] ; then \
	  pod lib lint SwiftProtobuf.podspec ; \
	fi
