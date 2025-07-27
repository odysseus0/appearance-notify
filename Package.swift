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
    targets: [
        .executableTarget(
            name: "appearance-notify",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)