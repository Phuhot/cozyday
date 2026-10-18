// swift-tools-version:5.9
// Gói Swift chỉ dùng để biên dịch + chạy test phần logic thuần Foundation (Cozyday/Core)
// trên Linux hoặc macOS mà không cần Xcode. App iOS thật được build bằng project.yml.
import PackageDescription

let package = Package(
    name: "CozyCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "CozyCore", targets: ["CozyCore"])
    ],
    targets: [
        .target(
            name: "CozyCore",
            path: "Cozyday/Core"
        ),
        .testTarget(
            name: "CozyCoreTests",
            dependencies: ["CozyCore"],
            path: "Tests/CoreTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
