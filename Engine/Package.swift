// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CarpetMaticEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CarpetMaticEngine",
            targets: ["CarpetMaticEngine"]
        ),
    ],
    targets: [
        .target(name: "CarpetMaticEngine"),
        .testTarget(
            name: "CarpetMaticEngineTests",
            dependencies: ["CarpetMaticEngine"]
        ),
    ]
)
