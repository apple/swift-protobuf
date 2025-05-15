// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "PluginExamples",
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .testTarget(
            name: "ExampleTests",
            dependencies: [
                .target(name: "Simple"),
                .target(name: "Nested"),
                .target(name: "Import"),
            ]
        ),
        .target(
            name: "Simple",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "Nested",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "Import",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
    ]
)
