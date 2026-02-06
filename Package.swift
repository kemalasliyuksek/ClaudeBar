// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeBar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ClaudeBar",
            path: "Sources/ClaudeBar",
            resources: [.process("Resources")]
        )
    ]
)
