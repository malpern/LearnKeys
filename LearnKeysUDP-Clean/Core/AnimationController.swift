import Foundation
import SwiftUI

/// Single source of truth - UDP events drive all animations
class AnimationController: ObservableObject {
    @Published var keyStates: [String: KeyState] = [:]
    @Published var modifierStates: [String: ModifierState] = [:]
    @Published var currentLayer: String = "base"
    @Published var layerTransitionStartTime: Date?
    
    private let udpTracker = UDPKeyTracker()
    
    init() {
        setupUDPHandlers()
    }
    
    private func setupUDPHandlers() {
        // Key press animations
        udpTracker.onKeyPress = { [weak self] key in
            self?.animateKeyPress(key)
        }
        
        // Modifier state changes
        udpTracker.onModifierChange = { [weak self] modifier, isActive in
            self?.updateModifierState(modifier, isActive: isActive)
        }
        
        // Layer transitions
        udpTracker.onLayerChange = { [weak self] layer in
            self?.transitionToLayer(layer)
        }
        
        // Navigation animations
        udpTracker.onNavigationKey = { [weak self] key in
            self?.animateNavigation(key)
        }
    }
    
    // MARK: - Animation Methods
    
    private func animateKeyPress(_ key: String) {
        DispatchQueue.main.async {
            LogManager.shared.log("🎯 Animating key press: \(key)")
            
            let keyType = self.determineKeyType(key)
            self.keyStates[key] = KeyState(key: key, isPressed: true, keyType: keyType)
            
            // Auto-deactivate after animation duration
            let duration = keyType == .navigation ? 0.2 : 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.keyStates[key]?.isPressed = false
            }
        }
    }
    
    private func animateNavigation(_ key: String) {
        DispatchQueue.main.async {
            LogManager.shared.log("🧭 Animating navigation: \(key)")
            
            self.keyStates[key] = KeyState(key: key, isPressed: true, keyType: .navigation)
            
            // Navigation animations are faster
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.keyStates[key]?.isPressed = false
            }
        }
    }
    
    private func updateModifierState(_ modifier: String, isActive: Bool) {
        DispatchQueue.main.async {
            LogManager.shared.log("🎛️ Updating modifier \(modifier): \(isActive ? "active" : "inactive")")
            
            if isActive {
                self.modifierStates[modifier] = ModifierState(modifier: modifier, isActive: true)
            } else {
                self.modifierStates[modifier]?.isActive = false
                
                // Remove inactive modifiers after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.modifierStates[modifier]?.isActive == false {
                        self.modifierStates.removeValue(forKey: modifier)
                    }
                }
            }
        }
    }
    
    private func transitionToLayer(_ layer: String) {
        DispatchQueue.main.async {
            LogManager.shared.log("🗂️ Transitioning to layer: \(layer)")
            
            self.currentLayer = layer
            self.layerTransitionStartTime = Date()
            
            // Clear any conflicting key states during layer transitions
            self.clearTransientStates()
        }
    }
    
    private func clearTransientStates() {
        // Clear key states that might conflict during layer changes
        keyStates = keyStates.compactMapValues { keyState in
            keyState.keyType == .modifier ? keyState : nil
        }
    }
    
    private func determineKeyType(_ key: String) -> KeyState.KeyType {
        // Determine key type based on key name
        switch key.lowercased() {
        case "h", "j", "k", "l", "w", "b", "e": // vim-like navigation
            return .navigation
        case "shift", "ctrl", "alt", "cmd", "control", "option", "command":
            return .modifier
        default:
            return .regular
        }
    }
    
    // MARK: - Public Interface for Views
    
    func isKeyPressed(_ key: String) -> Bool {
        return keyStates[key.lowercased()]?.isPressed ?? false
    }
    
    func isModifierActive(_ modifier: String) -> Bool {
        return modifierStates[modifier.lowercased()]?.isActive ?? false
    }
    
    func getKeyState(_ key: String) -> KeyState? {
        return keyStates[key.lowercased()]
    }
    
    func getModifierState(_ modifier: String) -> ModifierState? {
        return modifierStates[modifier.lowercased()]
    }
    
    // MARK: - Testing Support
    
    func simulateUDPMessage(_ message: String) {
        LogManager.shared.log("🧪 Simulating UDP message: \(message)")
        udpTracker.processMessage(message)
    }
    
    func getActiveKeyCount() -> Int {
        return keyStates.values.filter { $0.isPressed }.count
    }
    
    func getActiveModifierCount() -> Int {
        return modifierStates.values.filter { $0.isActive }.count
    }
}

// Extension to expose UDP message processing for testing
extension AnimationController {
    func processTestMessage(_ message: String) {
        let components = message.split(separator: ":")
        
        switch String(components[0]) {
        case "keypress":
            if components.count >= 2 {
                animateKeyPress(String(components[1]))
            }
        case "modifier":
            if components.count >= 3 {
                let modifier = String(components[1])
                let isActive = String(components[2]) == "down"
                updateModifierState(modifier, isActive: isActive)
            }
        case "navkey":
            if components.count >= 2 {
                animateNavigation(String(components[1]))
            }
        case "layer":
            if components.count >= 2 {
                transitionToLayer(String(components[1]))
            }
        default:
            LogManager.shared.log("❓ Unknown test message type")
        }
    }
} 