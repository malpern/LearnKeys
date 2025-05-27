// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnKeysTCP",
    platforms: [
        .macOS(.v14)
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
            sources: [
                "App/LearnKeysTCPApp.swift",
                "Core/AnimationController.swift", 
                "Core/LayerManager.swift",
                "Services/TCPKeyTracker.swift",
                "Views/KeyboardView.swift",
                "Views/KeyView.swift",
                "Views/LayerIndicator.swift",
                "Models/KeyState.swift",
                "Models/KanataConfig.swift",
                "Utils/KeyCodeMapper.swift",
                "Utils/LogManager.swift",
                "Utils/KanataManager.swift"
            ]
        ),
    ]
) 