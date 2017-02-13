<img src="https://swift.org/assets/images/swift.svg" alt="Swift logo" height="70" >
# Swift Protobuf

---

> :warning: **WARNING** :warning: This project is in a _prerelease_ state. There
> is active work going on that will result in API changes that can/will break
> code while things are finished. Use with caution.

---

**Welcome to Swift Protobuf!**

[Apple's Swift programming language](https://swift.org/) is a perfect
complement to [Google's Protocol
Buffer](https://developers.google.com/protocol-buffers/) serialization
technology.
They both emphasize high performance and programmer safety.

This project provides both the command-line program that adds Swift
code generation to Google's `protoc` and the runtime library that is
necessary for using the generated code.
After using the protoc plugin to generate Swift code from your .proto
files, you will need to add this library to your project.

## Documentation

More information is available in the associated documentation:

 * [PLUGIN.md](Documentation/PLUGIN.md) documents the `protoc-gen-swift`
   plugin that adds Swift support to the `protoc` program
 * [API.md](Documentation/API.md) documents the API you should use
 * [GENERATED_CODE.md](Documentation/GENERATED_CODE.md) documents the structure
   of the generated code
 * [STYLE_GUIDELINES.md](Documentation/STYLE_GUIDELINES.md) documents the style
   guidelines we have adopted in our codebase if you are interested in
   contributing
 * [cocoadocs.org](http://cocoadocs.org/docsets/SwiftProtobuf/) has the latest
   full API documentation

## Getting Started

If you've worked with Protocol Buffers before, adding Swift support is very
simple:  you just need to build the `protoc-gen-swift` program and copy it into
your PATH.
The `protoc` program will find and use it automatically, allowing you
to build Swift sources for your proto files.
You will also, of course, need to add the Swift runtime library to
your project.

### System Requirements

To use Swift with Protocol buffers, you'll need:

* A recent Swift 3 compiler that includes the Swift Package Manager.  The Swift
protobuf project is being developed and tested against the release version of
Swift 3.0 available from [Swift.org](https://swift.org)

* Google's protoc compiler.  The Swift protoc plugin is being actively developed
and tested against the latest protobuf 3.x sources; in particular, the tests need a version
of protoc which supports the `swift_prefix` option.  It may work with earlier versions
of protoc.  You can get recent versions from
[Google's github repository](https://github.com/google/protobuf).

### Build and Install

Building the plugin should be simple on any supported Swift platform:

```
$ git clone https://github.com/apple/swift-protobuf.git
$ cd swift-protobuf
```

Pick what released version of SwiftProtobuf you are going to use.  You can get
a list of tags with:

```
$ git tag -l
```

Once you pick the version you will use, set your local state to match, and
build the protoc plugin:

```
$ git checkout tags/[tag_name]
$ swift build
```

This will create a binary called `protoc-gen-swift` in the `.build/debug`
directory.  To install, just copy this one executable anywhere in your `PATH`.

### Converting .proto files into Swift

To generate Swift output for your .proto files, you run the `protoc` command as
usual, using the `--swift_out=<directory>` option:

```
$ protoc --swift_out=. my.proto
```

The `protoc` program will automatically look for `protoc-gen-swift` in your
`PATH` and use it.

Each `.proto` input file will get translated to a corresponding `.pb.swift`
file in the output directory.

## Building your project with `swift build`

After copying the `.pb.swift` files into your project, you will need to add the
[SwiftProtobuf library](https://github.com/apple/swift-protobuf) to your
project to support the generated code.
If you are using the Swift Package Manager, add a dependency to your
`Package.swift` file.  Adjust the `Version()` here to match the `[tag_name]`
you used to build the plugin above:

```swift
dependencies: [
        .Package(url: "https://github.com/apple/swift-protobuf.git", Version(0,9,24))
]
```

## Building your project with Xcode

If you are using Xcode, then you should:

* Add the `.pb.swift` source files generated from your protos directly to your
  project
* Add the Protobuf target from the Xcode project in this package to your project.

## Using the library with CocoaPods

If you're using CocoaPods, add this to your `Podfile` but adjust the `:tag` to
match the `[tag_name]` you used to build the plugin above:

```ruby
pod 'SwiftProtobuf', git: 'https://github.com/apple/swift-protobuf.git', :tag => '0.9.24'
```

And run `pod install`.

(Swift 3 frameworks require CocoaPods 1.1 or newer)

## Using the library with Carthage

If you're using Carthage, add this to your `Cartfile` but adjust the tag to match the `[tag_name]` you used to build the plugin above:

```ruby
github "apple/swift-protobuf" "0.9.24"
```

Run `carthage update` and drag `SwiftProtobuf.framework` into your Xcode.project.

# Quick Example

Here is a quick example to illustrate how you can use Swift Protocol Buffers in
your program, and why you might want to.  Create a file `DataModel.proto` with
the following contents:

```protobuf
syntax = "proto3";

message BookInfo {
   int64 id = 1;
   string title = 2;
   string author = 3;
}

message MyLibrary {
   int64 id = 1;
   string name = 2;
   repeated BookInfo books = 3;
   map<string,string> keys = 4;
}
```

After saving the above, you can generate Swift code using the following command:

```
$ protoc --swift_out=. DataModel.proto
```

This will create a file `DataModel.pb.swift` with a `struct BookInfo` and a
`struct MyLibrary` with corresponding Swift fields for each of the proto fields
and a host of other capabilities:

* Full mutable Swift copy-on-write value semantics
* CustomDebugStringConvertible:  The generated struct has a debugDescription
  method that can dump a full representation of the data
* Hashable, Equatable:  The generated struct can be put into a `Set<>` or
  `Dictionary<>`
* Binary serializable:  The `.serializeProtobuf()` method returns a `Data` with
  a compact binary form of your data.  You can deserialize the data using the
  `init(protobuf:)` initializer.
* JSON serializable:  The `.serializeJSON()` method returns a flexible JSON
  representation of your data that can be parsed with the `init(json:)`
  initializer.
* Portable:  The binary and JSON formats used by the serializers here are
  identical to those supported by protobuf for many other platforms and
  languages, making it easy to talk to C++ or Java servers, share data with
  desktop apps written in Objective-C or C++, or work with system applications
  developed in Python or Go.

And of course, you can define your own Swift extensions to the generated
`MyLibrary` struct to augment it with additional custom capabilities.

Best of all, you can take the same `DataModel.proto` file and generate Java,
C++, Python, or Objective-C for use on other platforms. Those platforms can all
then exchange serialized data in binary or JSON forms, with no additional
effort on your part.

## Report any issues

If you run into problems, please send us a detailed report.
At a minimum, please include:

* The specific operating system and version (for example, "macOS 10.12.1" or
  "Ubuntu 15.10")
* The version of Swift you have installed (from `swift --version`)
* The version of the protoc compiler you are working with from
  `protoc --version`
* The specific version of this source code (you can use `git log -1` to get the
  latest commit ID)
* Any local changes you may have
