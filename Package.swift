// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CSVParser"
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "CSVParser", targets: ["CSVParser"])
    ],
    targets: [
        .target(
            name: "CSVParser",
            path: "."
        )
    ]
)




