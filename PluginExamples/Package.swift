// swift-tools-version: 6.2

import PackageDescription

var packageDependencies: [Package.Dependency] = [
    .package(path: "../")
]
var exampleTestDependencies: [Target.Dependency] = [
    .target(name: "Simple"),
    .target(name: "Nested"),
    .target(name: "Import"),
    .target(name: "AccessLevelOnImport"),
    .target(name: "CustomProtoPath"),
    .target(name: "UsesWKTs"),
    .target(name: "PathToUnderscores"),
]
#if compiler(>=6.2.3)
packageDependencies.append(.package(path: "Subpackage"))
exampleTestDependencies.append(.product(name: "Nonexhaustive", package: "Subpackage"))
#endif

let package = Package(
    name: "PluginExamples",
    dependencies: packageDependencies,
    targets: [
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
        .target(
            name: "AccessLevelOnImport",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "CustomProtoPath",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "UsesWKTs",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .target(
            name: "PathToUnderscores",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
        .testTarget(
            name: "ExampleTests",
            dependencies: exampleTestDependencies
        ),
    ],
    swiftLanguageModes: [.v6]
)
