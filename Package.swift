// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "appearance-notify",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "appearance-notify",
            targets: ["appearance-notify"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "appearance-notify",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
