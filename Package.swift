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
        .target(
            name: "IOReportLib",
            path: "Sources/IOReportLib",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("Foundation"),
                .linkedLibrary("IOReport")
            ]
        ),
        .executableTarget(
            name: "silimon",
            dependencies: ["IOReportLib"],
            path: "Sources/silimon",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        )
    ]
)
