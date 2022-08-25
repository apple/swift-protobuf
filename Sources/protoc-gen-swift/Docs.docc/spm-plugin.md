# Using the Swift Package Manager plugin

The Swift Package Manager introduced new plugin capabilities in Swift 5.6, enabling the extension of
the build process with custom build tools. Learn how to use the SwiftProtobuf plugin for the
Swift Package Manager.

## Overview

> Warning: Due to limitations of binary executable discovery with Xcode we only recommend using the Swift Package Manager
plugin in leaf packages. For more information, read the `Defining the path to the protoc binary` section of
this article.

The plugin works by running the system installed `protoc` compiler with the `protoc-gen-swift` plugin
for specified `.proto` files in your targets source folder. Furthermore, the plugin allows defining a
configuration file which will be used to customize the invocation of `protoc`.

### Installing the protoc compiler

First, you must ensure that you have the `protoc` compiler installed.
There are multiple ways to do this. Some of the easiest are:

1. If you are on MacOS, installing it via `brew install protoc`
2. Download the binary from [Google's github repository](https://github.com/protocolbuffers/protobuf).

### Adding the proto files to your target

Next, you need to add the `.proto` files for which you want to generate your Swift types to your target's
source directory. You should also commit these files to your git repository since the generated types
are now generated on demand.

### Adding the plugin to your manifest

After adding the `.proto` files you can now add the plugin to the target inside your `Package.swift` manifest.
First, you need to add a dependency on `swift-protobuf`. Afterwards, you can declare the usage of the plugin
for your target. Here is an example snippet of a `Package.swift` manifest:

```swift
let package = Package(
  name: "YourPackage",
  products: [...],
  dependencies: [
    ...
    .package(url: "https://github.com/apple/swift-protobuf", from: "2.0.0"),
    ...
  ],
  targets: [
    ...
    .executableTarget(
        name: "YourTarget",
        plugins: [
            .plugin(name: "SwiftProtobufPlugin")
        ]
    ),
    ...
)

```

### Configuring the plugin

Lastly, after you have added the `.proto` files and modified your `Package.swift` manifest, you can now
configure the plugin to invoke the `protoc` compiler. This is done by adding a `swift-protobuf-config.json`
to the root of your target's source folder. An example configuration file looks like this:

```json
{
    "invocations": [
        {
            "protoFiles": [
                "Foo.proto",
            ],
            "visibility": "internal"
        },
        {
            "protoFiles": [
                "Bar.proto"
            ],
            "visibility": "public"
        }
    ]
}

```

In the above configuration, you declared two invocations to the `protoc` compiler. The first invocation
is generating Swift types for the `Foo.proto` file with `internal` visibility. The second invocation
is generating Swift types for the `Bar.proto` file with the `public` visibility.

### Defining the path to the protoc binary


The plugin needs to be able to invoke the `protoc` binary to generate the Swift types. 
There are three ways how this can be achieved. First, by default, the package manager looks into
the `$PATH` to find binaries named `protoc`. This works immediately if you use `swift build` to build
your package and `protoc` is installed in the `$PATH` (`brew` is adding it to your `$PATH` automatically).
However, this doesn't work if you want to compile from Xcode since Xcode is not passed the `$PATH`.
You have to options to set the path of `protoc` that the plugin is going to use. Either you can set
an environment variable `PROTOC_PATH` that gets picked up by the plugin. Here are two example how you
can set the variable so that it gets picked up:

```shell
# swift build
env PROTOC_PATH=/opt/homebrew/bin/protoc swift build

# To start Xcode (Xcode MUST NOT be running before invoking this)
env PROTOC_PATH=/opt/homebrew/bin/protoc xed .

# xcodebuild
env PROTOC_PATH=/opt/homebrew/bin/protoc xcodebuild <Here goes your command>
```

The other way to point the plugin to the concrete location of the `protoc`
compiler is by changing the configuration file like this:

```json
{
    "protoCPath": "/path/to/protoc",
    "invocations": [...]
}

```

> Warning: The configuration file option only solves the problem for leaf packages that are using the Swift package manager
plugin since there you can point the package manager to the right binary. The environment variable
does solve the problem for transitive packages as well; however, it requires your users to set
the variable now. In general we advise against adopting the plugin as a non-leaf package!
