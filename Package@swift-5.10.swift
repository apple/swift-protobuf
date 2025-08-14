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
        .testTarget(
            name: "SwiftProtobufTests",
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
