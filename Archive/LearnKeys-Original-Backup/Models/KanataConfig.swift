import Foundation

/// Enhanced configuration system for Phase 2 - supports complex layouts and display metadata
struct KanataConfig {
    let physicalKeys: [String]
    let layers: [String: LayerMapping]
    let displayMappings: [String: DisplayMapping]
    let layoutType: KeyboardLayoutType
    let homeRowMods: HomeRowModifiers
    
    struct LayerMapping {
        let name: String
        let displayName: String
        let keys: [String: String] // physical -> display mapping
        let color: LayerColor
        let icon: String
    }
    
    struct DisplayMapping {
        let symbol: String
        let description: String?
        let category: KeyCategory
        let isHomeRowMod: Bool
        let modifierType: String?
    }
    
    struct HomeRowModifiers {
        let leftHand: [String: String] // key -> modifier type
        let rightHand: [String: String]
        
        static let standard = HomeRowModifiers(
            leftHand: ["a": "shift", "s": "control", "d": "option", "f": "nav", "g": "command"],
            rightHand: ["j": "command", "k": "option", "l": "control", ";": "shift"]
        )
    }
    
    enum KeyboardLayoutType {
        case qwerty
        case colemak
        case dvorak
        case custom
    }
    
    enum KeyCategory {
        case letter
        case number
        case symbol
        case modifier
        case navigation
        case function
        case space
        case arrow
        case homeRowMod
    }
    
    enum LayerColor {
        case base
        case navigation
        case navFast
        case function
        case custom(String)
        
        var color: String {
            switch self {
            case .base: return "primary"
            case .navigation: return "blue"
            case .navFast: return "purple"
            case .function: return "green"
            case .custom(let color): return color
            }
        }
    }
    
    // Enhanced default QWERTY layout with Phase 2 features
    static let defaultQWERTY = KanataConfig(
        physicalKeys: [
            // Number row
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
            // Top row
            "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
            // Home row (with home row mods)
            "a", "s", "d", "f", "g", "h", "j", "k", "l", ";",
            // Bottom row
            "z", "x", "c", "v", "b", "n", "m", ",", ".", "/",
            // Space and modifiers
            "spc", "lsft", "rsft", "lctl", "rctl", "lalt", "ralt", "lmet", "rmet",
            // Arrow keys
            "left", "down", "up", "right"
        ],
        layers: [
            "base": LayerMapping(
                name: "base", 
                displayName: "Base Layer",
                keys: [
                    "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
                    "6": "6", "7": "7", "8": "8", "9": "9", "0": "0",
                "q": "Q", "w": "W", "e": "E", "r": "R", "t": "T",
                "y": "Y", "u": "U", "i": "I", "o": "O", "p": "P",
                "a": "A", "s": "S", "d": "D", "f": "F", "g": "G",
                "h": "H", "j": "J", "k": "K", "l": "L", ";": ";",
                "z": "Z", "x": "X", "c": "C", "v": "V", "b": "B",
                "n": "N", "m": "M", ",": ",", ".": ".", "/": "/",
                    "spc": "⎵"
                ],
                color: .base,
                icon: "keyboard"
            ),
            "f-nav": LayerMapping(
                name: "f-nav",
                displayName: "Navigation",
                keys: [
                "h": "←", "j": "↓", "k": "↑", "l": "→",
                    "w": "⌥→", "b": "⌥←", "e": "⌥→", "u": "🏠"
                ],
                color: .navigation,
                icon: "arrow.up.arrow.down.arrow.left.arrow.right"
            ),
            "navfast": LayerMapping(
                name: "navfast",
                displayName: "Fast Navigation",
                keys: [
                    "h": "⇤", "j": "⇟", "k": "⇞", "l": "⇥",
                    "w": "⇢", "u": "🏠"
                ],
                color: .navFast,
                icon: "bolt"
            ),
            "nomods": LayerMapping(
                name: "nomods",
                displayName: "No Modifiers",
                keys: [:], // Transparent layer
                color: .custom("gray"),
                icon: "keyboard.badge.ellipsis"
            )
        ],
        displayMappings: [
            // Home row modifiers (left hand)
            "a": DisplayMapping(symbol: "A", description: "A / Shift", category: .homeRowMod, isHomeRowMod: true, modifierType: "shift"),
            "s": DisplayMapping(symbol: "S", description: "S / Control", category: .homeRowMod, isHomeRowMod: true, modifierType: "control"),
            "d": DisplayMapping(symbol: "D", description: "D / Option", category: .homeRowMod, isHomeRowMod: true, modifierType: "option"),
            "f": DisplayMapping(symbol: "F", description: "F / Nav Layer", category: .homeRowMod, isHomeRowMod: true, modifierType: "nav"),
            "g": DisplayMapping(symbol: "G", description: "G / Command", category: .homeRowMod, isHomeRowMod: true, modifierType: "command"),
            
            // Home row modifiers (right hand)
            "j": DisplayMapping(symbol: "J", description: "J / Command", category: .homeRowMod, isHomeRowMod: true, modifierType: "command"),
            "k": DisplayMapping(symbol: "K", description: "K / Option", category: .homeRowMod, isHomeRowMod: true, modifierType: "option"),
            "l": DisplayMapping(symbol: "L", description: "L / Control", category: .homeRowMod, isHomeRowMod: true, modifierType: "control"),
            ";": DisplayMapping(symbol: ";", description: "; / Shift", category: .homeRowMod, isHomeRowMod: true, modifierType: "shift"),
            
            // Special keys
            "spc": DisplayMapping(symbol: "⎵", description: "Space / Nav Layer", category: .space, isHomeRowMod: true, modifierType: "nav"),
            
            // Navigation symbols
            "h": DisplayMapping(symbol: "←", description: "Left", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "←": DisplayMapping(symbol: "←", description: "Left Arrow", category: .arrow, isHomeRowMod: false, modifierType: nil),
            "↓": DisplayMapping(symbol: "↓", description: "Down Arrow", category: .arrow, isHomeRowMod: false, modifierType: nil),
            "↑": DisplayMapping(symbol: "↑", description: "Up Arrow", category: .arrow, isHomeRowMod: false, modifierType: nil),
            "→": DisplayMapping(symbol: "→", description: "Right Arrow", category: .arrow, isHomeRowMod: false, modifierType: nil),
            
            // Fast navigation symbols
            "⇤": DisplayMapping(symbol: "⇤", description: "Line Start", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "⇟": DisplayMapping(symbol: "⇟", description: "Page Down", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "⇞": DisplayMapping(symbol: "⇞", description: "Page Up", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "⇥": DisplayMapping(symbol: "⇥", description: "Line End", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "⇢": DisplayMapping(symbol: "⇢", description: "Word Right", category: .navigation, isHomeRowMod: false, modifierType: nil),
            "🏠": DisplayMapping(symbol: "🏠", description: "HomeRow App", category: .navigation, isHomeRowMod: false, modifierType: nil)
        ],
        layoutType: .qwerty,
        homeRowMods: .standard
    )
    
    // Enhanced parsing with display metadata support
    static func parseDisplayMappings(from configText: String) -> [String: DisplayMapping] {
        var mappings: [String: DisplayMapping] = [:]
        let lines = configText.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix(";;DISPLAY:") {
                // Parse: ;;DISPLAY: alias-name "display-text" "symbol"
                let components = trimmed.components(separatedBy: "\"")
                if components.count >= 4 {
                    let aliasLine = components[0].replacingOccurrences(of: ";;DISPLAY:", with: "").trimmingCharacters(in: .whitespaces)
                    let aliasName = aliasLine.trimmingCharacters(in: .whitespaces)
                    let displayText = components[1]
                    let symbol = components[3]
                    
                    mappings[aliasName] = DisplayMapping(
                        symbol: symbol,
                        description: displayText,
                        category: categorizeKey(symbol),
                        isHomeRowMod: false,
                        modifierType: nil
                    )
                }
            }
        }
        
        return mappings
    }
    
    private static func categorizeKey(_ symbol: String) -> KeyCategory {
        switch symbol {
        case "←", "↓", "↑", "→":
            return .arrow
        case "⇤", "⇟", "⇞", "⇥", "⇢":
            return .navigation
        case "⎵":
            return .space
        case "🏠":
            return .function
        default:
            if symbol.count == 1 && symbol.rangeOfCharacter(from: .letters) != nil {
                return .letter
            } else if symbol.count == 1 && symbol.rangeOfCharacter(from: .decimalDigits) != nil {
                return .number
            } else {
                return .symbol
            }
        }
    }
    
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
    
    func getLayerInfo(_ layer: String) -> LayerMapping? {
        return layers[layer]
    }
    
    func isHomeRowModifier(_ physicalKey: String) -> Bool {
        return displayMappings[physicalKey]?.isHomeRowMod ?? false
    }
    
    func getModifierType(_ physicalKey: String) -> String? {
        return displayMappings[physicalKey]?.modifierType
    }
    
    // Enhanced parsing from full Kanata config
    static func load(from configPath: String) -> KanataConfig {
        guard let configText = try? String(contentsOfFile: configPath) else {
            print("⚠️ Could not load config file, using default QWERTY")
            return defaultQWERTY
        }
        
        let physicalKeys = parsePhysicalKeys(from: configText)
        let displayMappings = parseDisplayMappings(from: configText)
        
        // Merge with defaults
        var enhancedMappings = defaultQWERTY.displayMappings
        for (key, mapping) in displayMappings {
            enhancedMappings[key] = mapping
        }
        
        print("📋 Loaded enhanced config with \(physicalKeys.count) keys and \(displayMappings.count) display mappings")
        
        return KanataConfig(
            physicalKeys: physicalKeys,
            layers: defaultQWERTY.layers,
            displayMappings: enhancedMappings,
            layoutType: .qwerty,
            homeRowMods: .standard
        )
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
} 