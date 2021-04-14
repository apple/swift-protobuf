# FuzzTesting

This subpackage build binaries to be use with Fuzz testing.

The Swift binaries distributed with Xcode do not include the fuzzing support, so
for macOS, one need to install the swift.org toolchain and use that instead.

To build on macOS:

```
xcrun --toolchain swift swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
```

To build on linux:

```
swift build -c debug -Xswiftc -sanitize=fuzzer,address -Xswiftc -parse-as-library
```

Then the binaries will be found in `.build/release`.

Note: You can also use `-c release` to build/test in release instead as that
could find different issues.

If/When issues are found, please consider adding them to
`Tests/SwiftProtobufTests/Test_FuzzTests.swift`, not only does this make it
easier to make sure things don't regres, but it also provides an easy way to
debug them while working on the fix.
