import Foundation

/// Simple key code mapping utilities
/// In UDP-first architecture, this is mainly for display purposes
struct KeyCodeMapper {
    
    /// Map physical key names to display symbols
    static let keySymbolMap: [String: String] = [
        // Letters
        "a": "A", "b": "B", "c": "C", "d": "D", "e": "E",
        "f": "F", "g": "G", "h": "H", "i": "I", "j": "J",
        "k": "K", "l": "L", "m": "M", "n": "N", "o": "O",
        "p": "P", "q": "Q", "r": "R", "s": "S", "t": "T",
        "u": "U", "v": "V", "w": "W", "x": "X", "y": "Y", "z": "Z",
        
        // Numbers
        "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
        "6": "6", "7": "7", "8": "8", "9": "9", "0": "0",
        
        // Special keys
        "spc": "Space",
        "ret": "Return",
        "tab": "Tab",
        "esc": "Esc",
        "bspc": "⌫",
        "del": "⌦",
        
        // Arrows
        "left": "←",
        "down": "↓",
        "up": "↑",
        "right": "→",
        
        // Modifiers
        "lsft": "⇧",
        "rsft": "⇧",
        "lctl": "⌃",
        "rctl": "⌃",
        "lalt": "⌥",
        "ralt": "⌥",
        "lmet": "⌘",
        "rmet": "⌘",
        
        // Symbols
        ";": ";",
        "'": "'",
        ",": ",",
        ".": ".",
        "/": "/",
        "\\": "\\",
        "[": "[",
        "]": "]",
        "-": "-",
        "=": "=",
        "`": "`"
    ]
    
    /// Navigation symbols for different layers
    static let navigationSymbolMap: [String: String] = [
        "h": "←",
        "j": "↓",
        "k": "↑",
        "l": "→",
        "w": "⌥→",
        "b": "⌥←",
        "e": "⌥→"
    ]
    
    /// Fast navigation symbols
    static let fastNavSymbolMap: [String: String] = [
        "h": "⌘←",
        "j": "PgDn",
        "k": "PgUp",
        "l": "⌘→"
    ]
    
    /// Get display symbol for a key
    static func getDisplaySymbol(for key: String) -> String {
        return keySymbolMap[key.lowercased()] ?? key.uppercased()
    }
    
    /// Get navigation symbol for a key
    static func getNavigationSymbol(for key: String) -> String {
        return navigationSymbolMap[key.lowercased()] ?? getDisplaySymbol(for: key)
    }
    
    /// Get fast navigation symbol for a key
    static func getFastNavSymbol(for key: String) -> String {
        return fastNavSymbolMap[key.lowercased()] ?? getNavigationSymbol(for: key)
    }
    
    /// Check if a key is a modifier
    static func isModifier(_ key: String) -> Bool {
        let modifierKeys = ["lsft", "rsft", "lctl", "rctl", "lalt", "ralt", "lmet", "rmet",
                           "shift", "ctrl", "alt", "cmd", "control", "option", "command"]
        return modifierKeys.contains(key.lowercased())
    }
    
    /// Check if a key is navigation-related
    static func isNavigation(_ key: String) -> Bool {
        let navKeys = ["h", "j", "k", "l", "w", "b", "e", "left", "down", "up", "right"]
        return navKeys.contains(key.lowercased())
    }
    
    /// Get key category
    static func getKeyCategory(_ key: String) -> KanataConfig.KeyCategory {
        let lowercased = key.lowercased()
        
        if isModifier(lowercased) {
            return .modifier
        } else if isNavigation(lowercased) {
            return .navigation
        } else if lowercased == "spc" {
            return .space
        } else if "abcdefghijklmnopqrstuvwxyz".contains(lowercased) {
            return .letter
        } else if "1234567890".contains(lowercased) {
            return .number
        } else {
            return .symbol
        }
    }
    
    /// Convert Kanata key name to display name
    static func kanataToDisplay(_ kanataKey: String) -> String {
        // Handle common Kanata key name mappings
        switch kanataKey.lowercased() {
        case "spc":
            return "Space"
        case "ret", "enter":
            return "Return"
        case "bspc":
            return "⌫"
        case "del":
            return "⌦"
        case "tab":
            return "Tab"
        case "esc":
            return "Esc"
        case "caps":
            return "Caps"
        case "lsft", "rsft":
            return "⇧"
        case "lctl", "rctl":
            return "⌃"
        case "lalt", "ralt":
            return "⌥"
        case "lmet", "rmet":
            return "⌘"
        default:
            return getDisplaySymbol(for: kanataKey)
        }
    }
} 