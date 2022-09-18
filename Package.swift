// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "sc23-swift-client",
    targets: [
        .executableTarget(name: "simple-client")
    ],
    swiftLanguageVersions: [.v5]
)