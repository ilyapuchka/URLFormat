// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "URLFormat",
    products: [
        .library(name: "URLFormat", targets: ["URLFormat"]),
        .library(name: "VaporURLFormat", targets: ["VaporURLFormat"]),
        ],
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/common-parsers.git", .branch("master")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "3.3.3"))
        ],
    targets: [
        .target(name: "URLFormat", dependencies: ["CommonParsers"]),
        .target(name: "VaporURLFormat", dependencies: ["URLFormat", "Vapor"]),
        .testTarget(name: "URLFormatTests", dependencies: ["URLFormat"]),
        .testTarget(name: "VaporURLFormatTests", dependencies: ["VaporURLFormat", "Vapor"]),
    ]
)
