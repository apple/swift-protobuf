# FuzzTesting

This subpackage build binaries to be use with Fuzz testing.

NOTE: The Swift toolchain distributed with Xcode do not include the fuzzing
support, so for macOS, one needs to install the swift.org toolchain and use that
instead.

To build on macOS:

```
xcrun \
  --toolchain swift \
  swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
```

To build on linux:

```
swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
```

Then the binaries will be found in `.build/debug`.

Note: You can also use `-c release` to build/test in release instead as that
could find different issues.

In this directory you will also find a `do_build.sh` script.  By default it
builds for both _debug_ and _release_. You can also pass `--run-regressions` to
have it run the the build against the previous failcases to check for
regressions.

When issues are found:

1. Make sure you add a file to `FailCases` subdirectory so regressions can
   easily be watched for. The GitHub workflow runs against there.

2. Consider adding them to `Tests/SwiftProtobufTests/Test_FuzzTests.swift`, this
   help in debugging while working on the failure, but also provides yet another way
   to ensure things don't regress and if they do, it is much easier to immediately
   debug the issue.

A note about memory issues, the address sanitizer is enabled in the fuzz tests
and in that context can find different things that what are found running the
unittests with the address sanitizer. So having test cases in both places can be
needed to help ensure something is less likely to regress.

There are dictionaries to help steer the fuzzing of JSON and TextFormat, to run
with them, just add `-dict=FuzzJSON.dict` or `-dict=FuzzTextFormat.dict` to the
invocation of the fuzz binary.
