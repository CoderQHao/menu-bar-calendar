// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarCalendar",
    platforms: [
        .macOS(.v13)
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
            path: ".",
            exclude: [
                ".build",
                ".DerivedData",
                ".git",
                "Assets.xcassets",
                "MenuBarCalendar.xcodeproj",
                "README-assets",
                "Releases",
                "SupportingFiles",
                "Tools",
                ".DS_Store",
                "CHANGELOG.md",
                "README.md"
            ],
            sources: [
                "App",
                "Models",
                "Services",
                "Support",
                "ViewModels",
                "Views"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
