// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "CompileTests",
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "InternalImportsByDefault",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("InternalImportsByDefault"),
                // Enable warnings as errors so the build fails if warnings are
                // present in generated code.
                .unsafeFlags(["-warnings-as-errors"])
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
    ]
)
