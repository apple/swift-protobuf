import PackageDescription

let package = Package(
    name: "SwiftProtobuf",
    targets: [
        Target(name: "PluginLibrary", dependencies: ["SwiftProtobuf"]),
        Target(name: "protoc-gen-swift", dependencies: ["PluginLibrary", "SwiftProtobuf"]),
    ]
)

// Ensure that the dynamic library is created for the performance test harness.
products.append(
    Product(name: "SwiftProtobuf", type: .Library(.Dynamic), modules: "SwiftProtobuf")
)
