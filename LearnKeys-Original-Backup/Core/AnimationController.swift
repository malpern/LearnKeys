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
        udpTracker.startListening()
    }
    
    private func setupUDPHandlers() {
        // Key press animations
        udpTracker.onKeyPress = { [weak self] key in
            self?.animateKeyPress(key)
        }
        
        // Modifier state changes
        udpTracker.onModifierChange = { [weak self] modifier, isActive in
            self?.updateModifierState(modifier, isActive)
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
            print("🎯 Animating key press: \(key)")
            
            let keyType = self.determineKeyType(key)
            self.keyStates[key] = KeyState(key: key, isPressed: true, keyType: keyType)
            
            // Auto-deactivate after animation duration
            let duration = keyType == .navigation ? 0.2 : 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.keyStates[key]?.isPressed = false
            }
        }
    }
    
    private func updateModifierState(_ modifier: String, _ isActive: Bool) {
        DispatchQueue.main.async {
            print("🎯 Modifier \(modifier): \(isActive ? "activated" : "deactivated")")
            self.modifierStates[modifier] = ModifierState(modifier: modifier, isActive: isActive)
        }
    }
    
    private func transitionToLayer(_ layer: String) {
        DispatchQueue.main.async {
            print("🎯 Layer transition to: \(layer)")
            self.currentLayer = layer
            self.layerTransitionStartTime = Date()
        }
    }
    
    private func animateNavigation(_ key: String) {
        DispatchQueue.main.async {
            print("🎯 Navigation animation: \(key)")
            self.keyStates[key] = KeyState(key: key, isPressed: true, keyType: .navigation)
            
            // Navigation keys have faster animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.keyStates[key]?.isPressed = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineKeyType(_ key: String) -> KeyState.KeyType {
        // Home row modifier keys
        if ["a", "s", "d", "f", "g", "j", "k", "l", ";", "semicolon"].contains(key) {
            return .modifier
        }
        
        // Layer keys
        if ["spc", "f"].contains(key) {
            return .layer
        }
        
        // Navigation keys
        if key.hasPrefix("fast_") || key.hasPrefix("fnav_") {
            return .navigation
        }
        
        return .regular
    }
    
    // MARK: - Public Query Methods
    
    func getKeyState(_ key: String) -> KeyState? {
        return keyStates[key]
    }
    
    func isKeyActive(_ key: String) -> Bool {
        return keyStates[key]?.isPressed ?? false
    }
    
    func isModifierActive(_ modifier: String) -> Bool {
        return modifierStates[modifier]?.isActive ?? false
    }
    
    func getActiveKeys() -> Set<String> {
        return Set(keyStates.compactMap { $0.value.isPressed ? $0.key : nil })
    }
    
    func getActiveModifiers() -> Set<String> {
        return Set(modifierStates.compactMap { $0.value.isActive ? $0.key : nil })
    }
} 