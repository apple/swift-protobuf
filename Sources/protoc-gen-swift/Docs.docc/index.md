# ``protoc_gen_swift``

@Metadata {
  @DisplayName("protoc-gen-swift")
}

Code generation helper for use with Google's `protoc` command.

## Overview

The `protoc-gen-swift` program is a _plugin_ to Google's protoc
compiler that works with protoc to translate proto files into
Swift code.

## Getting Started

If you've worked with Protocol Buffers in other programming
languages before, adding Swift support is
very simple: you just need to build the `protoc-gen-swift` program and
copy it into any directory in your PATH.  The protoc program will find
and use it automatically, allowing you to build Swift sources for your
proto files.  You will also, of course, need to add the corresponding
Swift runtime library to your project.

### System Requirements

To use Swift with Protocol buffers, you'll need:

* A recent Swift compiler that includes the Swift Package Manager.
  We recommend using the latest release build from
  [Swift.org](https://swift.org) or the command-line tools included
  with the latest version of Xcode.

* Google's protoc compiler.  You can get recent versions from
  [Google's github repository](https://github.com/protocolbuffers/protobuf).

### Build and Install

Building the plugin should be simple on any supported Swift platform:

```sh
$ git clone https://github.com/apple/swift-protobuf
$ cd swift-protobuf
$ swift build -c release
```

This will create a binary called `protoc-gen-swift` in the
`.build/release` directory.  To install, just copy this one executable
anywhere in your PATH.

### Converting .proto files into Swift

To generate Swift output for your .proto files, you run the `protoc`
command as usual, using the `--swift_out=<directory>` option:

```sh
$ protoc --swift_out=. my.proto
```

The `protoc` program will automatically look for `protoc-gen-swift` in your
`PATH` and use it.

Each `.proto` input file will get translated to a corresponding `.pb.swift` file
in the output directory.

#### How to Specify Code-Generation Options

The plugin tries to use reasonable default behaviors for the code it
generates, but there are a few things that can be configured to
specific needs.

You can use the `--swift_opt` argument to `protoc` to pass options to the
Swift code generator as follows:
```sh
$ protoc --swift_opt=[NAME]=[VALUE] --swift_out:. foo/bar/*.proto mumble/*.proto
```

If you need to specify multiple options, you can use more than one
`--swift_opt` argument:
```
$ protoc \
    --swift_opt=[NAME1]=[VALUE1] \
    --swift_opt=[NAME2]=[VALUE2] \
    --swift_out=. foo/bar/*.proto mumble/*.proto
```

_NOTE:_ protoc 3.2.0 does not recognize `--swift_opt` if you rely on
`protoc-gen-swift` being found on the `PATH`. To work around this, you need to
explicitly add the argument `--plugin=[PATH-TO-protoc-gen-swift]` to the
command line, then the `--swift_opt` argument will be understood.  If you are
using protoc 3.2.1 or later, then this workaround is _not_ needed.

##### Generation Option: `FileNaming` - Naming of Generated Sources

By default, the paths to the proto files are maintained on the
generated files.  So if you pass `foo/bar/my.proto`, you will get
`foo/bar/my.pb.swift` in the output directory. The Swift plugin
supports an option to control the generated file names, the option is
given as part of the `--swift_opt` argument like this:

```
$ protoc --swift_opt=FileNaming=[value] --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `FileNaming` are:

* `FullPath` (default): Like all other languages, "foo/bar/baz.proto" makes
  "foo/bar/baz.pb.swift.
* `PathToUnderscores`: To help with things like the Swift Package
  Manager where someone might want all the files in one directory;
  "foo/bar/baz.proto" makes "foo_bar_baz.pb.swift".
* `DropPath`: Drop the path from the input and just write all files
  into the output directory; "foo/bar/baz.proto" makes "baz.pb.swift".

##### Generation Option: `Visibility` - Visibility of Generated Types

By default, SwiftProtobuf does not specify a visibility for the
generated types, methods, and properties.  As a result, these will end
up with the default (`internal`) access.  You can change this with the
`Visibility` option:

```
$ protoc --swift_opt=Visibility=[value] --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `Visibility` are:

* `Internal` (default): No visibility is set for the types, so they get the
  default internal visibility.
* `Public`: The visibility on the types is set to `public` so the types will
  be exposed outside the module they are compiled into.


##### Generation Option: `ProtoPathModuleMappings` - Swift Module names for proto paths

By default, the code generator assumes all of the resulting Swift files will
be put into the same module. However, since protos can reference types from
another proto file, those generated files might end up in different modules.
This option allows you to specify that the code generated from the proto
files will be distributed in multiple modules. This data is used during
generation to then `import` the module and scope the types. This option
takes the path of a file providing the mapping:

```
$ protoc --swift_opt=ProtoPathModuleMappings=[path.asciipb] --swift_out=. foo/bar/*.proto
```

The format of that mapping file is defined in
[swift_protobuf_module_mappings.proto](../Protos/SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto),
and files would look something like:

```
mapping {
  module_name: "MyModule"
  proto_file_path: "foo/bar.proto"
}
mapping {
  module_name: "OtherModule"
  proto_file_path: "mumble.proto"
  proto_file_path: "other/file.proto"
}
```

The `proto_file_path` values here should match the paths used in the proto file
`import` statements.


##### Generation Option: `ImplementationOnlyImports` - `@_implementationOnly`-annotated imports

By default, the code generator does not annotate any imports with `@_implementationOnly`.
However, in some scenarios, such as when distributing an `XCFramework`, imports 
for types used only internally should be annotated as `@_implementationOnly` to 
avoid exposing internal symbols to clients.
You can change this with the `ImplementationOnlyImports` option:

```
$ protoc --swift_opt=ImplementationOnlyImports=[value] --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `ImplementationOnlyImports` are:

* `false` (default): The `@_implementationOnly` annotation will never be used.
* `true`: Imports of internal dependencies and any modules defined in the module
mappings will be annotated as `@_implementationOnly`. 

**Important:** Modules cannot be imported as implementation-only if they're 
exposed via public API, so even if `ImplementationOnlyImports` is set to `true`,
this will only work if the `Visibility` is set to `internal`. 


##### Generation Option: `UseAccessLevelOnImports` - imports preceded by a visibility modifier (`public`, `package`, `internal`)

The default behavior depends on the Swift version the plugin is compiled with. 
For Swift versions below 6.0 the default is `false` and the code generator does not precede any imports with a visibility modifier. 
You can change this by explicitly setting the `UseAccessLevelOnImports` option:

```
$ protoc --swift_opt=UseAccessLevelOnImports=[value] --swift_out=. foo/bar/*.proto mumble/*.proto
```

The possible values for `UseAccessLevelOnImports` are:

* `false`: Generates plain import directives without a visibility modifier.
* `true`: Imports of internal dependencies and any modules defined in the module
mappings will be preceded by a visibility modifier corresponding to the visibility of the generated types - see `Visibility` option. 

**Important:** It is strongly encouraged to use `internal` imports instead of `@_implementationOnly` imports. 
Hence `UseAccessLevelOnImports` and `ImplementationOnlyImports` options exclude each other. 


### Building your project

After copying the `.pb.swift` files into your project, you will need
to add the
[SwiftProtobuf library](https://github.com/apple/swift-protobuf) to
your project to support the generated code.  If you are using the
Swift Package Manager, you should first check what version of
`protoc-gen-swift` you are currently using:

```
$ protoc-gen-swift --version
protoc-gen-swift 1.0.1
```

And then add a dependency to your Package.swift file.  Adjust the
`Version()` here to match the `protoc-gen-swift` version you checked
above:

```swift
dependencies: [
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
]
```

If you are using Xcode, then you should:

* Add the Swift source files generated from your protos directly to your
  project.
* Add this SwiftPM package as dependency of your xcode project:
  [Apple Docs](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)



## Internals

When you give `protoc` an option of the form `--XYZ-out`,
it will find and run a program called `protoc-gen-XYZ`.

The `protoc` program then proceeds to read, parse, and validate
all of your proto files.
It feeds this information (as a set of "Descriptor" objects)
to the `protoc-gen-XYZ` program and expects the program to
produce one or more source code files
that `protoc` will then save to the correct output location.

The `protoc-gen-swift` program relies heavily
on the `SwiftProtobuf` library to handle serializing and
deserializing the protobuf-encoded data used to
communicate with `protoc`.
It also relies on another library called `SwiftProtobufPluginLibrary`
that incorporates a lot of the key knowledge about how
to produce Swift source code.
