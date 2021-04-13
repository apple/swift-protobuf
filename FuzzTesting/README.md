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
