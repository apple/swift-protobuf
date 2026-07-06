// swift-tools-version: 6.2

// Package.swift
//
// Copyright (c) 2026 Apple Inc. and the project authors
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
            name: "NonisolatedDeclarations",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
