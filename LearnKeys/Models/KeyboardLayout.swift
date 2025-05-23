import SwiftUI

// MARK: - Keyboard Layout Models

struct KeyboardRow {
    let keys: [String]
    let spacing: CGFloat
    let leftPadding: CGFloat
}

struct KeyboardLayout {
    static let qwertyRow = KeyboardRow(
        keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        spacing: 8, leftPadding: 25
    )
    
    static let homeRow = KeyboardRow(
        keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"],
        spacing: 8, leftPadding: 38
    )
    
    static let bottomRow = KeyboardRow(
        keys: ["z", "x", "c", "v", "b", "n", "m"],
        spacing: 8, leftPadding: 65
    )
    
    static let arrowKeys = ["left", "down", "up", "right"]
}

// MARK: - Temporary Key States

enum TemporaryKeyState {
    case layerHeld
    case none
    
    var backgroundColor: (active: [Color], inactive: [Color]) {
        switch self {
        case .layerHeld:
            // Purple gradient for layer keys
            return (
                active: [Color(hex: "DDA0DD"), Color(hex: "9370DB")], // Plum to MediumPurple
                inactive: [Color(hex: "E6E6FA"), Color(hex: "DDA0DD")] // Lavender to Plum
            )
        case .none:
            // Default styling (will be ignored)
            return (active: [], inactive: [])
        }
    }
    
    var borderColor: (active: Color, inactive: Color) {
        switch self {
        case .layerHeld:
            return (active: Color(hex: "8A2BE2"), inactive: Color(hex: "DDA0DD")) // BlueViolet to Plum
        case .none:
            return (active: Color.clear, inactive: Color.clear)
        }
    }
} 