import Foundation

// MARK: - Kanata Configuration Models

struct KanataConfig {
    var defsrc: [String] = []
    var layers: [String: [String]] = [:]
    var aliases: [String: KanataAlias] = [:]
    var variables: [String: String] = [:]
    var displayMappings: [String: DisplayMapping] = [:]  // New: display metadata from config
    
    // MARK: - Helper Methods
    
    func getDisplaySymbol(for key: String, in layer: String) -> String {
        // First check for custom display mapping
        if let mapping = displayMappings[key] {
            return mapping.symbol
        }
        
        // Then check layer mappings
        if let layerKeys = layers[layer], 
           let keyIndex = defsrc.firstIndex(of: key),
           keyIndex < layerKeys.count {
            let mappedKey = layerKeys[keyIndex]
            if mappedKey != "_" && mappedKey != key {
                return mappedKey.uppercased()
            }
        }
        
        // Fall back to default symbols
        switch key {
        case "spc": return "⎵"
        case ";": return ";"
        case ",": return ","
        case ".": return "."
        case "/": return "/"
        default: return key.uppercased()
        }
    }
    
    func getKeyDescription(for key: String) -> String? {
        // Return descriptions for modifier keys
        switch key {
        case "a": return "shift"
        case "s": return "ctrl"
        case "d": return "opt"
        case "f": return "nav"
        case "g": return "cmd"
        case "j": return "cmd"
        case "k": return "opt"
        case "l": return "ctrl"
        case ";": return "shift"
        default: return nil
        }
    }
    
    // MARK: - Default Configuration
    
    static let defaultQWERTY = KanataConfig(
        defsrc: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
                 "a", "s", "d", "f", "g", "h", "j", "k", "l", ";",
                 "z", "x", "c", "v", "b", "n", "m", ",", ".", "/",
                 "spc"],
        layers: [
            "base": ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
                     "a", "s", "d", "f", "g", "h", "j", "k", "l", ";",
                     "z", "x", "c", "v", "b", "n", "m", ",", ".", "/",
                     "spc"]
        ]
    )
}

struct DisplayMapping {
    let key: String
    let displayText: String
    let symbol: String
    
    init(key: String, displayText: String, symbol: String) {
        self.key = key
        self.displayText = displayText
        self.symbol = symbol
    }
}

struct KanataAlias {
    let name: String
    let definition: String
    let tapAction: String?
    let holdAction: String?
    let isModifier: Bool
    let isLayer: Bool
    
    init(name: String, definition: String) {
        self.name = name
        self.definition = definition
        
        var tempTapAction: String? = nil
        var tempHoldAction: String? = nil
        var tempIsModifier = false
        var tempIsLayer = false
        
        // Parse tap-hold patterns
        if definition.contains("tap-hold") {
            // Parse tap-hold-release-keys format: tap-hold-release-keys time time (multi key @tap) holdAction keys
            if definition.contains("tap-hold-release-keys") {
                // Extract the tap action from (multi key @tap) pattern
                if let multiRange = definition.range(of: #"\(multi ([a-zA-Z0-9;]+) @tap\)"#, options: .regularExpression) {
                    let multiMatch = String(definition[multiRange])
                    // Extract just the key name from "(multi key @tap)"
                    let keyPattern = #"multi ([a-zA-Z0-9;]+) @tap"#
                    if let keyMatch = multiMatch.range(of: keyPattern, options: .regularExpression) {
                        let keyPart = String(multiMatch[keyMatch])
                        tempTapAction = keyPart.replacingOccurrences(of: "multi ", with: "").replacingOccurrences(of: " @tap", with: "")
                    }
                } else {
                    // Enhanced parsing for simple tap-hold-release-keys format
                    // Format: tap-hold-release-keys time time tapAction holdAction keys
                    let parts = definition.components(separatedBy: " ")
                    
                    // Find the tap action (usually after the timing values)
                    if parts.count >= 4 {
                        let tapActionCandidate = parts[3]
                        if !tapActionCandidate.contains("(") && !tapActionCandidate.isEmpty {
                            tempTapAction = tapActionCandidate
                        } else {
                            print("⚠️  Complex tap action detected for '\(name)': \(tapActionCandidate)")
                        }
                    } else {
                        print("❌ Insufficient parts in tap-hold definition for '\(name)': \(parts.count) parts")
                    }
                }
            } else {
                // Simple parsing for basic tap-hold format
                let parts = definition.components(separatedBy: " ")
                if parts.count >= 4 {
                    tempTapAction = parts[3]
                }
            }
            
            // Extract hold action from various patterns
            if definition.contains("@shift") || definition.contains("lsft") {
                tempHoldAction = "@shift"
                tempIsModifier = true
            } else if definition.contains("@control") || definition.contains("lctl") {
                tempHoldAction = "@control"
                tempIsModifier = true
            } else if definition.contains("@option") || definition.contains("lalt") {
                tempHoldAction = "@option"
                tempIsModifier = true
            } else if definition.contains("@command") || definition.contains("lmet") {
                tempHoldAction = "@command"
                tempIsModifier = true
            } else if definition.contains("@rshift") || definition.contains("rsft") {
                tempHoldAction = "@rshift"
                tempIsModifier = true
            } else if definition.contains("@rcontrol") || definition.contains("rctl") {
                tempHoldAction = "@rcontrol"
                tempIsModifier = true
            } else if definition.contains("@roption") || definition.contains("ralt") {
                tempHoldAction = "@roption"
                tempIsModifier = true
            } else if definition.contains("@rcommand") || definition.contains("rmet") {
                tempHoldAction = "@rcommand"
                tempIsModifier = true
            } else if definition.contains("layer-toggle") || definition.contains("layer-while-held") {
                tempIsModifier = false
                tempIsLayer = true
                tempHoldAction = "layer"
            } else {
                // Log unrecognized hold actions in tap-hold expressions
                if definition.contains("tap-hold") {
                    print("⚠️  Unrecognized hold action in tap-hold definition for '\(name)': \(definition)")
                }
            }
            
            tempIsLayer = definition.contains("layer")
        } else {
            tempTapAction = definition
            tempIsLayer = definition.contains("layer")
        }
        
        self.tapAction = tempTapAction
        self.holdAction = tempHoldAction
        self.isModifier = tempIsModifier
        self.isLayer = tempIsLayer
    }
} 