// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WeakImports",
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "ModuleA",
            dependencies: [
                .target(name: "ModuleB"),
                .target(name: "ModuleC"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
        .target(
            name: "ModuleB",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "ModuleC",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        ),
        .executableTarget(
            name: "Client",
            dependencies: [
                .target(name: "ModuleA")
            ]
        ),
    ]
)
