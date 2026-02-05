// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Usagem",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Usagem",
            path: "Sources/Usagem"
        )
    ]
)
