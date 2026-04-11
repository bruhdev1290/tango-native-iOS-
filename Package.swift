// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaigaClient",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "TaigaCore", targets: ["TaigaCore"]),
        .library(name: "TaigaUI", targets: ["TaigaUI"]),
        .executable(name: "TaigaMobileApp", targets: ["TaigaApp"])
    ],
    dependencies: [
        // Add third-party dependencies here if needed
    ],
    targets: [
        .target(
            name: "TaigaCore",
            path: "Sources/TaigaCore"
        ),
        .target(
            name: "TaigaUI",
            dependencies: ["TaigaCore"],
            path: "Sources/TaigaUI"
        ),
        .executableTarget(
            name: "TaigaApp",
            dependencies: ["TaigaUI", "TaigaCore"],
            path: "Sources/TaigaApp"
        ),
        .testTarget(
            name: "TaigaCoreTests",
            dependencies: ["TaigaCore"],
            path: "Tests/TaigaCoreTests"
        )
    ]
)
