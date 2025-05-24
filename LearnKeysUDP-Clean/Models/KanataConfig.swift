import Foundation

/// Minimal config parsing - only what's needed for display
/// Behavior is handled by UDP messages, not config parsing
struct KanataConfig {
    let physicalKeys: [String]
    let layers: [String: LayerMapping]
    let displayMappings: [String: DisplayMapping]
    
    struct LayerMapping {
        let name: String
        let keys: [String: String] // physical -> display mapping
    }
    
    struct DisplayMapping {
        let symbol: String
        let description: String?
        let category: KeyCategory
    }
    
    enum KeyCategory {
        case letter
        case number
        case symbol
        case modifier
        case navigation
        case function
        case space
    }
    
    // Default QWERTY layout for display
    static let defaultQWERTY = KanataConfig(
        physicalKeys: [
            "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
            "a", "s", "d", "f", "g", "h", "j", "k", "l", ";",
            "z", "x", "c", "v", "b", "n", "m", ",", ".", "/",
            "spc"
        ],
        layers: [
            "base": LayerMapping(name: "Base", keys: [
                "q": "Q", "w": "W", "e": "E", "r": "R", "t": "T",
                "y": "Y", "u": "U", "i": "I", "o": "O", "p": "P",
                "a": "A", "s": "S", "d": "D", "f": "F", "g": "G",
                "h": "H", "j": "J", "k": "K", "l": "L", ";": ";",
                "z": "Z", "x": "X", "c": "C", "v": "V", "b": "B",
                "n": "N", "m": "M", ",": ",", ".": ".", "/": "/",
                "spc": "Space"
            ]),
            "f-nav": LayerMapping(name: "Navigation", keys: [
                "h": "←", "j": "↓", "k": "↑", "l": "→",
                "w": "⌥→", "b": "⌥←", "e": "⌥→"
            ]),
            "navfast": LayerMapping(name: "Fast Nav", keys: [
                "h": "⌘←", "j": "PgDn", "k": "PgUp", "l": "⌘→"
            ])
        ],
        displayMappings: [
            "a": DisplayMapping(symbol: "A", description: "Letter A / Shift", category: .letter),
            "s": DisplayMapping(symbol: "S", description: "Letter S / Control", category: .letter),
            "d": DisplayMapping(symbol: "D", description: "Letter D / Option", category: .letter),
            "f": DisplayMapping(symbol: "F", description: "Letter F / Nav Layer", category: .letter),
            "j": DisplayMapping(symbol: "J", description: "Letter J / Command", category: .letter),
            "k": DisplayMapping(symbol: "K", description: "Letter K / Option", category: .letter),
            "l": DisplayMapping(symbol: "L", description: "Letter L / Control", category: .letter),
            ";": DisplayMapping(symbol: ";", description: "Semicolon / Shift", category: .symbol),
            "spc": DisplayMapping(symbol: "Space", description: "Space / Nav Layer", category: .space),
            "h": DisplayMapping(symbol: "←", description: "Left Arrow", category: .navigation),
            "↓": DisplayMapping(symbol: "↓", description: "Down Arrow", category: .navigation),
            "↑": DisplayMapping(symbol: "↑", description: "Up Arrow", category: .navigation),
            "→": DisplayMapping(symbol: "→", description: "Right Arrow", category: .navigation)
        ]
    )
    
    func getDisplaySymbol(for physicalKey: String, in layer: String = "base") -> String {
        // First check layer-specific mapping
        if let layerMapping = layers[layer],
           let symbol = layerMapping.keys[physicalKey] {
            return symbol
        }
        
        // Fall back to display mapping
        if let displayMapping = displayMappings[physicalKey] {
            return displayMapping.symbol
        }
        
        // Fall back to physical key name
        return physicalKey.uppercased()
    }
    
    func getKeyDescription(for physicalKey: String) -> String? {
        return displayMappings[physicalKey]?.description
    }
    
    func getKeyCategory(for physicalKey: String) -> KeyCategory {
        return displayMappings[physicalKey]?.category ?? .letter
    }
    
    func getKeysForLayer(_ layer: String) -> [String: String] {
        return layers[layer]?.keys ?? [:]
    }
    
    func getAllLayers() -> [String] {
        return Array(layers.keys).sorted()
    }
    
    // Simple parsing from defsrc (physical keys only)
    static func parsePhysicalKeys(from configText: String) -> [String] {
        let lines = configText.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("(defsrc") {
                // Extract keys from defsrc line
                let components = trimmed.components(separatedBy: .whitespaces)
                return Array(components.dropFirst().dropLast()).filter { !$0.isEmpty }
            }
        }
        
        return defaultQWERTY.physicalKeys
    }
    
    // Create minimal config from file (display only)
    static func load(from configPath: String) -> KanataConfig {
        guard let configText = try? String(contentsOfFile: configPath) else {
            print("⚠️ Could not load config file, using default QWERTY")
            return defaultQWERTY
        }
        
        let physicalKeys = parsePhysicalKeys(from: configText)
        
        // For the UDP-first architecture, we only need physical key layout
        // All behavior comes from UDP messages, not config parsing
        print("📋 Loaded config with \(physicalKeys.count) physical keys")
        
        return KanataConfig(
            physicalKeys: physicalKeys,
            layers: defaultQWERTY.layers,
            displayMappings: defaultQWERTY.displayMappings
        )
    }
} 