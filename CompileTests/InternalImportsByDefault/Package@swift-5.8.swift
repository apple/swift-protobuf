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
    targets: [
        .executableTarget(
            name: "InternalImportsByDefault",
            exclude: [
                "swift-protobuf-config.json",
                "Protos/SomeProtoWithBytes.proto",
                "Protos/ServiceOnly.proto",
            ]
        )
    ]
)
