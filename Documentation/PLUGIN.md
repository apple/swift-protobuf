# Swift Protobuf Plugin

---

The `protoc-gen-swift` program is a _plugin_ to Google's protoc
compiler that works with protoc to translate proto files into
Swift code.

## Getting Started

If you've worked with Protocol Buffers before, adding Swift support is very
simple:  you just need to build the `protoc-gen-swift` program and copy it into
any directory in your PATH.  The protoc program will find and use it automatically, allowing you
to build Swift sources for your proto files.  You will also, of course, need to
add the corresponding Swift runtime library to your project.

### System Requirements

To use Swift with Protocol buffers, you'll need:

* A recent Swift 3 compiler that includes the Swift Package Manager.  The Swift
protobuf project is being developed and tested against the Swift 3.0 developer
preview available from [Swift.org](https://swift.org)

* Google's protoc compiler.  The Swift protoc plugin is being actively
developed and tested against the protobuf 3.0 release.  It may work with earlier
versions of protoc.  You can get recent versions from
[Google's github repository](https://github.com/google/protobuf).

### Build and Install

Building the plugin should be simple on any supported Swift platform:

```
$ git clone https://github.com/apple/swift-protobuf
$ cd swift-protobuf
$ swift build
```

This will create a binary called `protoc-gen-swift` in the `.build/debug`
directory.  To install, just copy this one executable anywhere in your PATH.

### Converting .proto files into Swift

To generate Swift output for your .proto files, you run the `protoc` command as
usual, using the `--swift_out=<directory>` option:

```
$ protoc --swift_out=. my.proto
```

The `protoc` program will automatically look for `protoc-gen-swift` in your
`PATH` and use it.

Each `.proto` input file will get translated to a corresponding `.pb.swift` file
in the output directory.

#### Changing how Source is Generated

The plugin tries to use reasonable default behaviors for the code it generates,
but there are a few things that can be configured to specific needs.

`protoc` supports passing generator options to the plugins, and the Swift plugin
uses these to communicate changes from the default behaviors.

The options are given with a `--swift_opt` argument like this:

```
$ protoc --swift_opt=[NAME]=[VALUE] --swift_out:. foo/bar/*.proto mumble/*.proto
```

And more than one _NAME/VALUE_ pair can be passed by using the argument multiple times:

```
$ protoc \
    --swift_opt=[NAME1]=[VALUE1] \
    --swift_opt=[NAME2]=[VALUE2] \
    --swift_out=. foo/bar/*.proto mumble/*.proto
```

_NOTE:_ protoc 3.2.0 does not recognize `--swift_opt` if you rely on
`protoc-gen-swift` being found on the `PATH`. To work around this, you need to
explicitly add the argument `--plugin=[PATH-TO-protoc-gen-swift]` to the
command line, then the `--swift-opt` argument will be understood.  If you are
using protoc 3.2.1 or later, then this workaround is _not_ needed.

##### Generation Option: `FileNaming` - Naming of Generated Sources

By default, the paths to the proto files are maintained on the generated files.
So if you pass `foo/bar/my.proto`, you will get `foo/bar/my.pb.swift` in the
output directory. The Swift plugin supports an option to control the generated
file names, the option is given as part of the `--swift_out` argument like this:

```
$ protoc --swift_opt=FileNaming=[value]: --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `FileNaming` are:

 * `FullPath` (default): Like all other languages, "foo/bar/baz.proto" makes
   "foo/bar/baz.pb.swift.
 * `PathToUnderscores`: To help with things like the Swift Package Manager
   where someone might want all the files in one directory; "foo/bar/baz.proto"
   makes "foo_bar_baz.pb.swift".
 * `DropPath`: Drop the path from the input and just write all files into the
   output directory; "foo/bar/baz.proto" makes "baz.pb.swift".

##### Generation Option: `Visibility` - Visibility of Generated Types

By default, the types created in the generated source will end up as internal
because no visibility is set on them.  If you want the types to be made public
the option can be given as:

```
$ protoc --swift_opt=Visibility=[value] --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `Visibility` are:

 * `Internal` (default): No visibility is set for the types, so they get the
   default internal visibility.
 * `Public`: The visibility on the types is set to `public` so the types will
   be exposed outside the module they are compiled into.

### Building your project

After copying the `.pb.swift` files into your project, you will need to add the
[SwiftProtobuf library](https://github.com/apple/swift-protobuf) to your project
to support the generated code.  If you are using the Swift Package Manager, you
should first check what version of `protoc-gen-swift` you are currently using:

```
$ protoc-gen-swift --version
protoc-gen-swift 0.9.12
```

And then add a dependency to your Package.swift file.  Adjust the `Version()`
here to match the `protoc-gen-swift` version you checked above:

```swift
dependencies: [
        .Package(url: "https://github.com/apple/swift-protobuf.git", Version(0,9,12))
]
```

If you are using Xcode, then you should:

* Add the Swift source files generated from your protos directly to your
  project.
* Clone the SwiftProtobuf package.
* Add the SwiftProtobuf target from the Xcode project from that package to your
  project.

