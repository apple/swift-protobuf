// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "CompileTests",
    dependencies: [
        .package(name: "swift-protobuf", path: "../..")
    ],
    targets: [
        .testTarget(
            name: "Test1",
            dependencies: ["ImportsAPublicly"]
        ),
        .testTarget(
            name: "Test2",
            dependencies: ["ImportsImportsAPublicly"]
        ),
        .target(
            name: "ModuleA",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
        .target(
            name: "ImportsAPublicly",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .target(name: "ModuleA"),
            ]
        ),
        .target(
            name: "ImportsImportsAPublicly",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .target(name: "ImportsAPublicly"),
            ]
        ),
    ]
)
