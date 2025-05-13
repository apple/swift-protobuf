// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(name: "SwiftProtobuf", path: "..")
    ],
    targets: [
        .target(
            name: "FuzzCommon",
            dependencies: ["SwiftProtobuf"]
        ),
        .executableTarget(
            name: "FuzzBinary",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]
        ),
        .executableTarget(
            name: "FuzzBinaryDelimited",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]
        ),
        .executableTarget(
            name: "FuzzAsyncMessageSequence",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]
        ),
        .executableTarget(
            name: "FuzzJSON",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]
        ),
        .executableTarget(
            name: "FuzzTextFormat",
            dependencies: ["SwiftProtobuf", "FuzzCommon"]
        ),
        .testTarget(
            name: "FuzzCommonTests",
            dependencies: ["FuzzCommon"]
        ),
    ]
)
