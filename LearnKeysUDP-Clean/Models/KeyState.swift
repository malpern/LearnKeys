import Foundation

/// Simple key state model for UDP-driven animations
struct KeyState {
    let key: String
    var isPressed: Bool = false
    var keyType: KeyType = .regular
    var activationTime: Date = Date()
    
    enum KeyType {
        case regular
        case navigation
        case modifier
    }
}

/// Modifier state tracking
struct ModifierState {
    let modifier: String
    var isActive: Bool = false
    var activationTime: Date = Date()
} 