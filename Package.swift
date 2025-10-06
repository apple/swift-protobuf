// swift-tools-version:5.10

// Package.swift
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//

import PackageDescription

// Including protoc as a binary artifact can cause build issues in some environments. As a
// temporary measure offer an opt-out by setting PROTOBUF_NO_PROTOC=true.
let includeProtoc: Bool
if let noProtoc = Context.environment["PROTOBUF_NO_PROTOC"] {
    includeProtoc = !(noProtoc.lowercased() == "true" || noProtoc == "1")
} else {
    includeProtoc = true
}

let package = Package(
    name: "SwiftProtobuf",
    products: [
        .executable(
            name: "protoc-gen-swift",
            targets: ["protoc-gen-swift"]
        ),
        .library(
            name: "SwiftProtobuf",
            targets: ["SwiftProtobuf"]
        ),
        .library(
            name: "SwiftProtobufPluginLibrary",
            targets: ["SwiftProtobufPluginLibrary"]
        ),
        .plugin(
            name: "SwiftProtobufPlugin",
            targets: ["SwiftProtobufPlugin"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftProtobuf",
            exclude: ["CMakeLists.txt"],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: .packageSettings
        ),
        .target(
            name: "SwiftProtobufPluginLibrary",
            dependencies: ["SwiftProtobuf"],
            exclude: ["CMakeLists.txt"],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: .packageSettings
        ),
        .target(
            name: "SwiftProtobufTestHelpers",
            dependencies: ["SwiftProtobuf"],
            swiftSettings: .packageSettings
        ),
        .executableTarget(
            name: "protoc-gen-swift",
            dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"],
            exclude: ["CMakeLists.txt"],
            swiftSettings: .packageSettings
        ),
        .executableTarget(
            name: "Conformance",
            dependencies: ["SwiftProtobuf"],
            exclude: ["failure_list_swift.txt", "text_format_failure_list_swift.txt"],
            swiftSettings: .packageSettings
        ),
        .plugin(
            name: "SwiftProtobufPlugin",
            capability: .buildTool(),
            dependencies: ["protoc-gen-swift"]
        ),
        // TODO: Eventually, the existing tests should just work with table-driven protos. For now,
        // limit ourselves to a much smaller set that we know will run and pass during development.
        // .testTarget(
        //     name: "SwiftProtobufTests",
        //     dependencies: ["SwiftProtobuf"],
        //     swiftSettings: .packageSettings
        // ),
        .testTarget(
            name: "ExperimentalTableDrivenSwiftProtobufTests",
            dependencies: ["SwiftProtobuf"],
            swiftSettings: .packageSettings
        ),
        .testTarget(
            name: "SwiftProtobufPluginLibraryTests",
            dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobufTestHelpers"],
            swiftSettings: .packageSettings
        ),
        .testTarget(
            name: "protoc-gen-swiftTests",
            dependencies: ["protoc-gen-swift", "SwiftProtobufTestHelpers"],
            swiftSettings: .packageSettings
        ),
    ],
    swiftLanguageVersions: [.v5]
)

if includeProtoc {
    package.products.append(
        .executable(
            name: "protoc",
            targets: ["protoc"]
        )
    )

    package.targets.append(
        .binaryTarget(
            name: "protoc",
            url:
                "https://github.com/apple/swift-protobuf/releases/download/protoc-artifactbundle-v31.1/protoc-31.1.artifactbundle.zip",
            checksum: "f18bf2cfbbebd83133a4c29733b01871e3afdc73c102d62949a841d4f9bab86f"
        )
    )

    if let target = package.targets.first(where: { $0.name == "SwiftProtobufPlugin" }) {
        target.dependencies.append("protoc")
    }
}

// Settings for every Swift target in this package, like project-level settings
// in an Xcode project.
extension Array where Element == PackageDescription.SwiftSetting {
    static var packageSettings: Self {
        [
            .enableExperimentalFeature("StrictConcurrency=complete"),
            .enableUpcomingFeature("ExistentialAny"),
        ]
    }
}
