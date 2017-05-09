# Swift Protobuf Conformance Tester

Google's protobuf project includes an extensive "conformance test suite"
that exercises various encoding and decoding features of protobuf
implementations to help ensure that they are all interoperable.

SwiftProtobuf currently passes Google's entire conformance test suite.
We have integrated the conformance test with the SwiftProtobuf test
suite to help ensure that we remain conformant in the future as well.

## Preparation

The conformance test suite requires Swift 3.0, standard command-line tools such as make and awk, and a full source checkout of [Google's protobuf project](https://github.com/google/protobuf).

## Building the Tests

The `Makefile` at the root of the SwiftProtobuf project has the following lines, which
specify how to run the installed `protoc` program on your system, and where to find
the Google protobuf source tree:
```Makefile
PROTOC=protoc
GOOGLE_PROTOBUF_CHECKOUT=../protobuf
```

If these do not match your system, you can run `make PROTOC=[path] GOOGLE_PROTOBUF_CHECKOUT=[path] [target]`,
or edit the `Makefile` directly if you prefer.

After setting these variables, you can type:
```console
$ make test-conformance
```

which will build Google's conformance host program (which manages the
conformance test process) and the Swift Protobuf conformance checker
(which executes the individual test cases).

It will then run the test suite and print out any discrepancies found by the tool.

## If you have problems

The most common problem area is building Google's conformance host program.  You may find it easier to switch to the directory where you have checked out Google's protobuf sources and build the host program manually:
```console
$ cd protobuf
$ ./configure
$ make -C src
$ make -C conformance
```

You can then manually run the conformance test using the following commands:
```console
$ cd swift-protobuf
$ ../protobuf/conformance/conformance-test-runner --failure_list failure_list_swift.txt .build/debug/Conformance
```

## Known Issues

At this writing, all of the conformance tests succeed.

## Report any issues

If the conformance test prints out any "unexpected failures", please look in the Github Issues to see if the problem you're seeing was already reported.  If not, please send us a detailed report, including:
* The specific operating system and version (for example, "macOS 10.12.1" or "Ubuntu 15.10")
* The version of Swift you have installed (from `swift --version`)
* The version of the protobuf source code you are working with (look at the AC_INIT line near the top of configure.ac)
* The full output of the conformance test run, starting with "CONFORMANCE TEST BEGIN"

