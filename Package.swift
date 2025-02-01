// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PGMQ",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "pgmq-swift",
            targets: ["PGMQ"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
    ],
    targets: [
        .target(
            name: "PGMQ",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
        .testTarget(
            name: "pgmq-swiftTests",
            dependencies: ["PGMQ"]
        ),
    ]
)
