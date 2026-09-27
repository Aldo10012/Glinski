// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GlinskiKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "GlinskiEngine", targets: ["GlinskiEngine"]),
        .library(name: "GlinskiFeature", targets: ["GlinskiFeature"]),
        .library(name: "BoardUI", targets: ["BoardUI"]),
    ],
    dependencies: [
        // Pinned: 0.10.4's manifest uses .visionOS(.v2) with tools 5.9, which Xcode 26 rejects.
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.10.3"),
    ],
    targets: [
        .target(name: "GlinskiEngine"),
        .testTarget(name: "GlinskiEngineTests", dependencies: ["GlinskiEngine"]),
        .target(name: "GlinskiFeature", dependencies: ["GlinskiEngine"]),
        .testTarget(name: "GlinskiFeatureTests", dependencies: ["GlinskiFeature"]),
        .target(name: "BoardUI", dependencies: ["GlinskiFeature"], resources: [.process("Resources")]),
        .testTarget(name: "BoardUITests", dependencies: ["BoardUI", "ViewInspector"]),
    ]
)
