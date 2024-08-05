// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "PluginExamples",
    dependencies: [
        .package(name: "swift-protobuf", path: "../")
    ],
    targets: [
        .testTarget(
            name: "ExampleTests",
            dependencies: [
                .target(name: "Simple"),
                .target(name: "Nested"),
                .target(name: "Import"),
                .target(name: "AccessLevelOnImport"),
            ]
        ),
        .target(
            name: "Simple",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "Nested",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "Import",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "AccessLevelOnImport",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        )
    ]
)
