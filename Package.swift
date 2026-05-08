// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarCalendar",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "MenuBarCalendar",
            targets: ["MenuBarCalendar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MenuBarCalendar",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
