// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Selecto",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "Selecto",
            targets: ["Selecto"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "Selecto",
            dependencies: [],
            path: "Selecto/Selecto",
            exclude: ["Info.plist"],
            resources: []
        )
    ]
)
