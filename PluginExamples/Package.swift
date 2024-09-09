// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "PluginExamples",
    dependencies: [
        .package(path: "../")
    ],
    targets: targets()
)

private func targets() -> [Target] {
    var testDependencies: [Target.Dependency] = [
        .target(name: "Simple"),
        .target(name: "Nested"),
        .target(name: "Import"),
    ]
    #if compiler(>=5.9)
    testDependencies.append(.target(name: "AccessLevelOnImport"))
    #endif
    var targets: [Target] = [
        .testTarget(
            name: "ExampleTests",
            dependencies: testDependencies
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
    #if compiler(>=5.9)
    targets.append(
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
        )
    )
    #endif
    return targets
}
