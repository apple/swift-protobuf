// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Subpackage",
    products: [
        .library(
            name: "Nonexhaustive",
            targets: ["Nonexhaustive"]
        )
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "Nonexhaustive",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        )
    ]
)
