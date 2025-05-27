// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnKeysTCP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LearnKeysTCP",
            targets: ["LearnKeysTCP"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LearnKeysTCP",
            dependencies: [],
            path: ".",
            exclude: [
                "Tests/",
                "Views/ContentView.swift",
                "README.md",
                "config.kbd",
                "Archive/",
                "docs/",
                "STATUS.md",
                ".build-learnkeys/"
            ],
            sources: [
                "App/LearnKeysTCPApp.swift",
                "Core/TCPKeyTracker.swift",
                "Core/AnimationController.swift", 
                "Core/LayerManager.swift",
                "Views/KeyboardView.swift",
                "Views/KeyView.swift",
                "Views/LayerIndicator.swift",
                "Models/KeyState.swift",
                "Models/KanataConfig.swift",
                "Utils/KeyCodeMapper.swift",
                "Utils/LogManager.swift",
                "Utils/KanataManager.swift",
            ]
        ),
    ]
) 