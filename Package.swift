// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnKeys",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LearnKeys",
            targets: ["LearnKeys"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LearnKeys",
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
                "App/LearnKeyApp.swift",
                "Core/TCPKeyTracker.swift",
                "Core/AnimationController.swift", 
                "Core/LayerManager.swift",
                "Core/ProcessChecker.swift",
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