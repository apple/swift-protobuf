// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    dependencies: [
        .package(name: "SwiftProtobuf", path: ".."),
    ],
    targets: [
        .target(
            name: "FuzzCommon",
            dependencies: ["SwiftProtobuf"]),
        .target(
            name: "FuzzBinary",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]),
        .target(
            name: "FuzzBinaryDelimited",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]),
        .target(
            name: "FuzzJSON",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]),
        .target(
            name: "FuzzTextFormat",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]),
    ]
)
