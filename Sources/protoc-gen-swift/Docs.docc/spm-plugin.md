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

1. If you are on macOS, installing it via `brew install protobuf`
2. Download the binary from [Google's github repository](https://github.com/protocolbuffers/protobuf).

### Adding the plugin to your manifest

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
            .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
        ]
    ),
    ...
)

```

### Configuring the plugin

Configuring the plugin is done by adding a `swift-protobuf-config.json` file anywhere in your target's sources.
Before you start configuring the plugin, you need to add the `.proto` files to your sources. You should also commit these
files to your git repository since the generated types are now generated on demand.
It's also important to note that the proto files in your configuration should be in
the same directory as the config file. Let's see an example to have a better understanding.

Here's an example file structure that looks like this:

```text
Sources
├── main.swift
├── ProtoBuf
    ├── swift-protobuf-config.json
    ├── foo.proto
    └── Bar
        └── Bar.proto
```

So, the configuration file would look something like this:

```json
{
    "invocations": [
        {
            "protoFiles": [
                "Foo.proto",
            ],
            "visibility": "internal",
            "implementationOnlyImports": true
        },
        {
            "protoFiles": [
                "Bar/Bar.proto"
            ],
            "visibility": "public",
            "fileNaming": "pathToUnderscores"
        }
    ]
}

```
As you can see in the above configuration, the paths are relative with respect to the `ProtoBuf` folder and not the root folder.
If you add a file in the `Sources` folder, the plugin would be unable to access it as the path is computed relative to
the `swift-protobuf-config.json` file.

> Note: paths to your `.proto` files will have to include the relative path from the config file directory to the `.proto` file location.
> Files **must** be contained within the same directory as the config file.

In the above configuration, you declared two invocations to the `protoc` compiler. The first invocation
is generating Swift types for the `Foo.proto` file with `internal` visibility. The second invocation
is generating Swift types for the `Bar.proto` file with the `public` visibility. Furthermore, the second
invocation is using the `pathToUnderscores` file naming option. This option can be used to solve
problems where a single target contains two or more proto files with the same name.

### Defining the path to the protoc binary

The plugin needs to be able to invoke the `protoc` binary to generate the Swift types. There are several ways to achieve this.

First, by default, the package manager looks into the `$PATH` to find binaries named `protoc`.
This works immediately if you use `swift build` to build your package and `protoc` is installed
in the `$PATH` (`brew` is adding it to your `$PATH` automatically).
However, this doesn't work if you want to compile from Xcode since Xcode is not passed the `$PATH`.

If compiling from Xcode, you have **three options** to set the path of `protoc` that the plugin is going to use:

* You can start Xcode by running `$ xed .` from the command line from the directory your project is located - this should make `$PATH` visible to Xcode.

* Set an environment variable `PROTOC_PATH` that gets picked up by the plugin. Here are two examples of how you can achieve this:

```shell
# swift build
env PROTOC_PATH=/opt/homebrew/bin/protoc swift build

# To start Xcode (Xcode MUST NOT be running before invoking this)
env PROTOC_PATH=/opt/homebrew/bin/protoc xed .

# xcodebuild
env PROTOC_PATH=/opt/homebrew/bin/protoc xcodebuild <Here goes your command>
```

* Point the plugin to the concrete location of the `protoc` compiler is by changing the configuration file like this:

```json
{
    "protocPath": "/path/to/protoc",
    "invocations": [...]
}
```

### Known Issues

- The configuration file _must not_ be excluded from the list of sources for the
  target in the package manifest (that is, it should not be present in the
  `exclude` argument for the target). The build system does not have access to
  the file if it is excluded, however, `swift build` will result in a warning
  that the file should be excluded.
- The plugin should only be used for leaf packages. The configuration file option
  only solves the problem for leaf packages that are using the Swift package
  manager plugin since there you can point the package manager to the right
  binary. The environment variable does solve the problem for transitive
  packages as well; however, it requires your users to set the variable now.
