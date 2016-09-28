import PackageDescription

let package = Package(
        name: "SwiftProtobuf",
        targets: [
            Target(name: "PluginLibrary", dependencies: ["SwiftProtobuf"]),
            Target(name: "protoc-gen-swift", dependencies: ["PluginLibrary", "SwiftProtobuf"]),
        ]
)
