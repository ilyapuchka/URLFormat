// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "URLFormat",
    products: [
        .library(name: "URLFormat", targets: ["URLFormat"]),
        ],
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/common-parsers.git", .branch("master"))
        ],
    targets: [
        .target(name: "URLFormat", dependencies: ["CommonParsers"]),
        .testTarget(name: "URLFormatTests", dependencies: ["URLFormat"]),
    ]
)
