import Foundation

/// Simple key state model for UDP-driven animations
struct KeyState {
    let key: String
    var isPressed: Bool = false
    var pressedAt: Date?
    var keyType: KeyType = .regular
    var animationDuration: Double = 0.3
    
    enum KeyType {
        case regular        // Normal keys (q, w, e, etc.)
        case modifier       // Home row mods (a, s, d, f, g, j, k, l, ;)
        case navigation     // Navigation keys (hjkl in nav layer)
        case layer          // Layer keys (f, spc)
    }
    
    static let inactive = KeyState(key: "", isPressed: false)
    
    init(key: String, isPressed: Bool = false, keyType: KeyType = .regular) {
        self.key = key
        self.isPressed = isPressed
        self.keyType = keyType
        self.pressedAt = isPressed ? Date() : nil
    }
}

/// Simple modifier state for UDP tracking
struct ModifierState {
    let modifier: String
    var isActive: Bool = false
    var activatedAt: Date?
    
    init(modifier: String, isActive: Bool = false) {
        self.modifier = modifier
        self.isActive = isActive
        self.activatedAt = isActive ? Date() : nil
    }
} 