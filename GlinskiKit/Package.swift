// swift-tools-version: 6.2
import PackageDescription

var products: [Product] = [
    .library(name: "GlinskiEngine", targets: ["GlinskiEngine"]),
    .library(name: "GlinskiFeature", targets: ["GlinskiFeature"]),
]
var dependencies: [Package.Dependency] = []
var targets: [Target] = [
    .target(name: "GlinskiEngine"),
    .testTarget(name: "GlinskiEngineTests", dependencies: ["GlinskiEngine"]),
    .target(name: "GlinskiFeature", dependencies: ["GlinskiEngine"]),
    .testTarget(name: "GlinskiFeatureTests", dependencies: ["GlinskiFeature"]),
]

// SwiftUI doesn't exist on Linux, where CI builds the engine for the v3 server. `swift test --filter` still
// builds every test target, so the UI targets and ViewInspector are only declared on Apple platforms.
#if !os(Linux)
products.append(.library(name: "BoardUI", targets: ["BoardUI"]))
// Pinned: 0.10.4's manifest uses .visionOS(.v2) with tools 5.9, which Xcode 26 rejects.
dependencies.append(.package(url: "https://github.com/nalexn/ViewInspector", exact: "0.10.3"))
targets += [
    .target(name: "BoardUI", dependencies: ["GlinskiFeature"], resources: [.process("Resources")]),
    .testTarget(name: "BoardUITests", dependencies: ["BoardUI", "ViewInspector"]),
]
#endif

let package = Package(
    name: "GlinskiKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: products,
    dependencies: dependencies,
    targets: targets
)
