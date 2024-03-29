// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "mkfont",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mkfont", targets: ["mkfont"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.2"),
        .package(url: "https://github.com/apparata/SystemKit", exact: "1.7.0"),
        .package(url: "https://github.com/apparata/AssetCatalogKit", exact: "1.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "mkfont",
            dependencies: [
                "MakeFontKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(
            name: "MakeFontKit",
            dependencies: [
                "SystemKit",
                "AssetCatalogKit"
            ]),
    ]
)
