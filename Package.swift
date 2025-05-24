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
                "Core/AnimationController.swift", 
                "Core/UDPKeyTracker.swift",
                "Views/KeyboardView.swift",
                "Views/KeyView.swift",
                "Models/KeyState.swift",
                "Models/KanataConfig.swift",
                "Utils/KeyCodeMapper.swift"
            ]
        ),
    ]
) 