// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "real_liquid_glass",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "real-liquid-glass", targets: ["real_liquid_glass"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "real_liquid_glass",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
