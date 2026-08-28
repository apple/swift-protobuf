// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // Ensure that public symbols are not unconditionally `llvm.used` so that
    // the linker can strip them from the final binary.
    //
    // This isn't a standard build configuration, but clients who care enough
    // about minimizing binary size to use weak imports would likely also be
    // setting this.
    .unsafeFlags(["-Xfrontend", "-internalize-at-link"])
]

let linkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-export-dynamic"], .when(platforms: [.linux, .android]))
]

let package = Package(
    name: "WeakImports",
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "ModuleA",
            dependencies: [
                .target(name: "ModuleB"),
                .target(name: "ModuleC"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ModuleB",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ModuleC",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "Client",
            dependencies: [
                .target(name: "ModuleA")
            ],
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        ),
    ]
)
