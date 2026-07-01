// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "linkage-test",
    dependencies: [
        .package(name: "swift-protobuf", path: "../..", traits: [])
    ],
    targets: [
        .executableTarget(
            name: "linkageTest",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        )
    ]
)
