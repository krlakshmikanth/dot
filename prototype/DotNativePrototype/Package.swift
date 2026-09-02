// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "DotNativePrototype",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DotPrototypeApp", targets: ["DotPrototypeApp"])
    ],
    targets: [
        .executableTarget(name: "DotPrototypeApp")
    ]
)
