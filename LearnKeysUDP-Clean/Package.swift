// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnKeysUDP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LearnKeysUDP",
            targets: ["LearnKeysUDP"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LearnKeysUDP",
            dependencies: [],
            path: ".",
            sources: [
                "App/LearnKeysUDPApp.swift",
                "Core/UDPKeyTracker.swift",
                "Core/AnimationController.swift", 
                "Core/LayerManager.swift",
                "Views/KeyboardView.swift",
                "Views/KeyView.swift",
                "Views/LayerIndicator.swift",
                "Models/KeyState.swift",
                "Models/KanataConfig.swift",
                "Utils/KeyCodeMapper.swift",
                "Utils/LogManager.swift",
            ]
        ),
    ]
) 