# Swift Protobuf Plugin

---

The protoc _plugin_ works with protoc to translate proto files into Swift code.

## Getting Started

If you've worked with Protocol Buffers before, adding Swift support is very
simple:  you just need to build the `protoc-gen-swift` program and copy it into
your PATH.  The protoc program will find and use it automatically, allowing you
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

# Examples

Following are a number of examples demonstrating how to use the code generated
by protoc in a Swift program.

## Basic Protobuf Serialization

Consider this simple proto file:

```protobuf
// file foo.proto
package project.basics;
syntax = "proto3";
message Foo {
   int32 id = 1;
   string label = 2;
   repeated string alternates = 3;
}
```

After running protoc, you will have a Swift source file `foo.pb.swift` that
contains a `struct Project_Basics_Foo`.  The name here includes a prefix derived
from the package name; you can override this prefix with the `swift_prefix`
option.

You can use the generated struct much as you would any other struct.  It has
properties corresponding to the fields defined in the proto.  You can provide
values for those properties in the initializer as well:

```swift
var foo = Project_Basics_Foo(id: 12)
foo.label = "Excellent"
foo.alternates = ["Good", "Better", "Best"]
```

The generated struct also includes standard definitions of hashValue, equality,
and other basic utility methods:

```swift
var foos = Set<Project_Basics_Foo>()
foos.insert(foo)
```

You can serialize the object to a compact binary protobuf format or a legible
JSON format:

```swift
print(try foo.serializeJSON())
network.write(try foo.serializeProtobuf())
```

(Note that serialization can fail if the objects contain data that cannot be
represented in the target serialization.  Currently, these failures can only
occur if your proto is taking advantage of the proto3 well-known Timestamp,
Duration, or Any types which impose additional restrictions on the range and
type of data.)

Conversely, if you have a string containing a JSON or protobuf serialized form,
you can convert it back into an object using the generated initializers:

```swift
let foo1 = try Project_Basics_Foo(json: inputString)
let foo2 = try Project_Basics_Foo(protobuf: inputBytes)
```

## Customizing the generated structs

You can customize the generated structs by using Swift extensions.

Most obviously, you can add new methods as necessary:

```swift
extension Project_Basics_Foo {
   mutating func invert() {
      id = 1000 - id
      label = "Inverted " + label
   }
}
```

For very specialized applications, you can also override the generated methods
in this way.  For example, if you want to change how the `hashValue` property is
computed, you can redefine it as follows:

```swift
extension Project_Basics_Foo {
   // I only want to hash based on the id.
   var hashValue: Int { return Int(id) }
}
```

Note that the `hashValue` property generated by the compiler is actually called
`_protoc_generated_hashValue`, so you can still access the generated version
even with the override.  Similarly, you can override other methods:

* `hashValue` property: as described above
* `customMirror` property: alter how mirrors are constructed
* `debugDescription` property: alter the text form shown when debugging
* `isEqualTo(other:)` test: Used by `==`
* `serializeJSON()` method: JSON serialization is generated
* `serializeAnyJSON()` method: generates a JSON serialization of an Any object
  containing this type
* `decodeFromJSONToken()` method: decodes an object of this type from a single
  JSON token (ignore this if your custom JSON format does not consist of a
  single token)
* `decodeFromJSONNull()`, `decodeFromJSONObject()`, `decodeFromJSONArray()`:
  decode an object of this type from the corresponding JSON data

Overriding the protobuf serialization is not fully supported at this time.

To see how this is used, you might examine the ProtobufRuntime implementation
of `Google_Protobuf_Duration`.  The core of that type is compiled from
`duration.proto`, but the library also includes a file
`Google_Protobuf_Duration_Extensions.swift` which extends the generated code
with a variety of specialized behaviors.

## Generated JSON serializers

Consider the following simple proto file:

```protobuf
message Foo {
  int32 id = 1;
  string name = 2;
  int64 my_my = 3;
}
```

A typical JSON message might look like the following:
```json
{
  "id": 1732789,
  "name": "Alice",
  "myMy": "1.7e3"
}
```

In particular, note that the "my\_my" field name in the proto file gets
translated to "myMy" in the JSON serialized form.  You can override this with a
`json_name` property on fields as needed.

To decode such a message, you would use Swift code similar to the following
```swift
let jsonString = ... string read from somewhere ...
let f = try Foo(json: jsonString)
print("id: \(f.id)  name: \(f.name)  myMy: \(f.myMy)")
```

Similarly, you can serialize a message object in memory to a JSON string
```swift
let f = Foo(id: 777, name: "Bob")
let json = try f.serializeJSON()
print("json: \(json)")
// json: {"id": 777, "name": "Bob"}
```

## Ad hoc JSON Deserialization

**TODO** Example Swift code that uses the generic JSON wrapper types to parse
anonymous JSON input.

## Decoding With Proto2 Extensions

(Note that extensions are a proto2 feature that is no longer supported in
proto3.)

Suppose you have the following simple proto file defining a message Foo:

```protobuf
// file base.proto
package my.project;
message Foo {
   extensions 100-1000;
}
```

And suppose another file defines an extension of that message:

```protobuf
// file more.proto
package my.project;
extend Foo {
   optional int32 extra_info = 177;
}
```

As described above, protoc will create an extension object in more.pb.swift and
a Swift extension that adds an `extraInfo` property to the `My_Project_Foo`
struct.

You can decode a Foo message containing this extension as follows.  Note that
the extension object here includes the package name and the name of the message
being extended:

```swift
let extensions: ProtobufExtensionSet = [My_Project_Foo_extraInfo]
let m = My_Project_Foo(protobuf: data, extensions: extensions)
print(m.extraInfo)
```

If you had many extensions defined in bar.proto, you can avoid having to list
them all yourself by using the preconstructed extension set included in the
generated file.  Note that the name of the preconstructed set includes the
package name and the name of the input file to ensure that extensions from
different files do not collide:

```swift
let extensions = Project_Additions_More_Extensions
let m = My_Project_Foo(protobuf: data, extensions: extensions)
```

To serialize an extension value, just set the value on the message and serialize
the result as usual:

```swift
var m = My_Project_Foo()
m.extraInfo = 12
m.serializeProtobuf()
```

## Swift Options

```swift
import "swift-options.proto";
option (apple_swift_prefix)=<prefix> (no default)
```

This value will be prepended to all struct, class, and enums that are generated
in the global scope.  Nested types will not have this string added.  By default,
this is generated from the package name by converting each package element to
UpperCamelCase and combining them with underscores.  For example, the package
"foo\_bar.baz" would lead to a default Swift prefix of "FooBar\_Baz\_".

**CAVEAT:** This requires you have `swift-options.proto`
available when you run protoc.

We are discussing with Google adding a standard `option swift_prefix` that would
have the same behavior but without this requirement. If that happens, the plugin
will be updated to support both the `option (apple_swift_prefix)` and
`option swift_prefix`.

# TODO

**RawMessage:** There should be a generic wrapper around the binary protobuf
decode machinery that provides a way for clients to disassemble encoded messages
into raw field data accessible by field tag.

**Embedded Descriptors:** There should be an option to include embedded
descriptors and a standard way to access them.

**Dynamic Messages:** There should be a generic wrapper that can accept a
Descriptor or Type and provide generic decoding of a message.  This will likely
build on RawMessage.

**Text PB:**  There is an old text PB format that is supported by the old
proto2 Java and C++ backends.  A few folks like it; it might be easy to add.


# Differences From other implementations

Google's spec for JSON serialization of Any objects requires that
JSON-to-protobuf and protobuf-to-JSON transcoding of well-formed messages fail
if the full type of the object contained in the Any is not available.  Google
has opined that this should always occur on the JSON side, in particular, they
think that JSON-to-protobuf transcoding should fail the JSON decode.  I don't
like this, since this implies that JSON-to-JSON recoding will also fail in this
case.  Instead, I have the reserialization fail when transcoding with
insufficient type information.

This implementation fully supports JSON encoding for proto2 types. Google has
not specified how this should work, so the implementation here may not fully
interoperate with other implementations.  Currently, groups are handled as if
they were messages.  Proto2 extensions are serialized to JSON automatically,
they are deserialized from JSON if you provide the appropriate ExtensionSet
when deserializing.

The protobuf serializer currently always writes all required fields in proto2
messages. This differs from the behavior of Google's C++ and Java
implementations, which omit required fields that have not been set or whose
value is the default.  This may change.

Unlike proto2, proto3 does not provide a standard way to tell if a field has
"been set" or not.  This is standard proto3 behavior across all languages and
implementations.  If you need to distinguish an empty field, you can model this
in proto3 using a oneof group with a single element:

```protobuf
message Foo {
  oneof HasName {
     string name = 432;
  }
}
```
This will cause the `name` field to be generated as a Swift `Optional<String>`
which will be nil if no value was provided for `name`.
