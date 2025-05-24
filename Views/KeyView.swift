import SwiftUI

struct KeyView: View {
    let physicalKey: String
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
        Button(action: {
            // For testing - simulate UDP message
            simulateKeyPress()
        }) {
            VStack(spacing: 2) {
                // Key label
                Text(displayKey)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                
                // Modifier indicator
                if isModifierKey {
                    Text(modifierLabel)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: keyWidth, height: 40)
            .background(keyBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var keyState: KeyState {
        return animationController.keyStates[physicalKey] ?? .inactive
    }
    
    private var isPressed: Bool {
        return keyState.isPressed
    }
    
    private var isModifierActive: Bool {
        // Check if this key has an active modifier
        let modifiers = ["shift", "control", "option", "command", "rshift", "rcontrol", "roption", "rcommand"]
        return modifiers.contains { animationController.isModifierActive($0) }
    }
    
    private var keyWidth: CGFloat {
        switch physicalKey {
        case "spc": return 120
        default: return 40
        }
    }
    
    private var displayKey: String {
        switch physicalKey {
        case "spc": return "⎵"
        case ";": return ";"
        default: return physicalKey.uppercased()
        }
    }
    
    private var isModifierKey: Bool {
        return ["a", "s", "d", "f", "g", "j", "k", "l", ";"].contains(physicalKey)
    }
    
    private var modifierLabel: String {
        switch physicalKey {
        case "a": return "⇧"     // shift
        case "s": return "⌃"     // control  
        case "d": return "⌥"     // option
        case "f": return "nav"   // layer
        case "g": return "⌘"     // command
        case "j": return "⌘"     // rcommand
        case "k": return "⌥"     // roption
        case "l": return "⌃"     // rcontrol
        case ";": return "⇧"     // rshift
        default: return ""
        }
    }
    
    private var keyBackground: Color {
        if isPressed {
            return .accentColor.opacity(0.8)
        } else if isModifierActive && isModifierKey {
            return .orange.opacity(0.3)
        } else if isModifierKey {
            return .blue.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var textColor: Color {
        if isPressed {
            return .white
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isPressed {
            return .accentColor
        } else if isModifierActive && isModifierKey {
            return .orange
        } else {
            return Color(.systemGray4)
        }
    }
    
    // MARK: - Testing Helper
    
    private func simulateKeyPress() {
        // For testing - simulate sending UDP message
        print("🧪 Simulating keypress:\(physicalKey)")
        
        // In real app, this would come from Kanata via UDP
        animationController.keyStates[physicalKey] = KeyState(
            key: physicalKey, 
            isPressed: true, 
            keyType: isModifierKey ? .modifier : .regular
        )
        
        // Auto-deactivate after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationController.keyStates[physicalKey]?.isPressed = false
        }
    }
} 