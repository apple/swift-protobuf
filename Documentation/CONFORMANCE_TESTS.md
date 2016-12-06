# Swift Protobuf Conformance Tester

**Welcome to Swift Protobuf!**

Apple's Swift programming language is a perfect complement to Google's Protocol
Buffer serialization technology.  They both emphasize high performance
and programmer safety.

Google's protobuf project includes a conformance checking host program that generates a large number of test cases, feeds them to a test program that executes those test cases, then verifies the results.  This project provides the test program for Swift Protobuf that works with Google's conformance checking host to verify that Swift Protobuf is completely compatible with other implementations of Google's protobuf specification.

## Requirements

This test suite requires Swift 3.0, standard command-line tools such as make and awk, and a full source checkout of [Google's protobuf project](https://github.com/google/protobuf).

## Building the Tests

You should start by editing the `Makefile` and adjusting these two lines to match your system:
```Makefile
PROTOC=protoc
PROTOBUF_PROJECT_DIR=../protobuf
```

These lines specify how to run the installed `protoc` program on your system, and where to find the Google protobuf source tree.

After setting these variables, you can type:
```console
$ make test
```

which will build Google's conformance host program (which manages the conformance test process) and the Swift Protobuf conformance checker (which executes the individual test cases).

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

The conformance test may print out a non-zero of "expected failures".  For more details on these, please look at `failure_list_swift.txt` which lists the tests that are expected to fail and includes some explanation.

## Report any issues

If the conformance test prints out any "unexpected failures", please look in the Github Issues to see if the problem you're seeing was already reported.  If not, please send us a detailed report, including:
* The specific operating system and version (for example, "macOS 10.12.1" or "Ubuntu 15.10")
* The version of Swift you have installed (from `swift --version`)
* The version of the protobuf source code you are working with (look at the AC_INIT line near the top of configure.ac)
* The full output of the conformance test run, starting with "CONFORMANCE TEST BEGIN"

