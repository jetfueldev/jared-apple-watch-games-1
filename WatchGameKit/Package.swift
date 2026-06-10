// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WatchGameKit",
    platforms: [.watchOS(.v10)],
    products: [
        .library(name: "WatchGameKit", targets: ["WatchGameKit"])
    ],
    targets: [
        .target(name: "WatchGameKit")
    ]
)
