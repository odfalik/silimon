// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "silimon",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "silimon", targets: ["silimon"])
    ],
    targets: [
        .executableTarget(
            name: "silimon",
            path: "Sources/silimon"
        )
    ]
)
