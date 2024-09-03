// swift-tools-version: 5.8

// Package.swift
//
// Copyright (c) 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt

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
