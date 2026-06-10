// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "FuzzTesting",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(name: "SwiftProtobuf", path: "..", traits: ["BinaryDelimitedStreams"])
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
