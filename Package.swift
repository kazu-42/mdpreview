// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MDPreview",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "MDPreviewCore",
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "MDPreview",
            dependencies: ["MDPreviewCore"]
        ),
        .testTarget(
            name: "MDPreviewCoreTests",
            dependencies: ["MDPreviewCore"]
        )
    ]
)
