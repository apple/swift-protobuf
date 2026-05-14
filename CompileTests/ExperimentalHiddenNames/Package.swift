// swift-tools-version: 6.1

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
        .package(name: "swift-protobuf", path: "../..")
    ],
    targets: [
        .testTarget(
            name: "ExperimentalHiddenNamesTests",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
