import SwiftUI

/// Individual key view with UDP-driven animations
struct KeyView: View {
    let physicalKey: String
    let config: KanataConfig
    
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
        ZStack {
            // Key background
            RoundedRectangle(cornerRadius: 8)
                .fill(keyBackgroundColor)
                .stroke(keyBorderColor, lineWidth: keyBorderWidth)
                .shadow(color: keyShadowColor, radius: keyShadowRadius, x: 0, y: keyShadowOffset)
            
            // Key content
            VStack(spacing: 2) {
                // Main symbol
                Text(displaySymbol)
                    .font(keyFont)
                    .fontWeight(keyFontWeight)
                    .foregroundColor(keyTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                // Description (for modifier keys)
                if let description = keyDescription, showDescription {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(4)
        }
        .frame(width: keyWidth, height: keyHeight)
        .scaleEffect(keyScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyScale)
        .animation(.easeInOut(duration: 0.2), value: keyBackgroundColor)
    }
    
    // MARK: - Computed Properties
    
    private var keyState: KeyState? {
        animationController.getKeyState(physicalKey)
    }
    
    private var isPressed: Bool {
        keyState?.isPressed ?? false
    }
    
    private var keyType: KeyState.KeyType {
        keyState?.keyType ?? .regular
    }
    
    private var displaySymbol: String {
        config.getDisplaySymbol(for: physicalKey, in: animationController.currentLayer)
    }
    
    private var keyDescription: String? {
        config.getKeyDescription(for: physicalKey)
    }
    
    private var showDescription: Bool {
        keyType == .modifier || (keyDescription?.contains("/") == true)
    }
    
    // MARK: - Visual Properties
    
    private var keyWidth: CGFloat {
        switch physicalKey {
        case "spc":
            return 200 // Space bar is wider
        default:
            return 40
        }
    }
    
    private var keyHeight: CGFloat {
        switch physicalKey {
        case "spc":
            return 35
        default:
            return 40
        }
    }
    
    private var keyScale: CGFloat {
        isPressed ? 1.1 : 1.0
    }
    
    private var keyBackgroundColor: Color {
        if isPressed {
            switch keyType {
            case .navigation:
                return Color.blue.opacity(0.7)
            case .modifier:
                return Color.orange.opacity(0.7)
            case .layer:
                return Color.purple.opacity(0.7)
            case .regular:
                return Color.green.opacity(0.6)
            }
        } else if animationController.isModifierActive(physicalKey) {
            return Color.orange.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var keyBorderColor: Color {
        if isPressed {
            switch keyType {
            case .navigation:
                return Color.blue
            case .modifier:
                return Color.orange
            case .layer:
                return Color.purple
            case .regular:
                return Color.green
            }
        } else if animationController.isModifierActive(physicalKey) {
            return Color.orange
        } else {
            return Color(NSColor.systemGray)
        }
    }
    
    private var keyBorderWidth: CGFloat {
        isPressed ? 2.0 : 1.0
    }
    
    private var keyTextColor: Color {
        if isPressed {
            return .white
        } else if animationController.isModifierActive(physicalKey) {
            return Color.orange
        } else {
            return .primary
        }
    }
    
    private var keyFont: Font {
        switch physicalKey {
        case "spc":
            return .caption
        default:
            return .system(size: 14, weight: .medium, design: .monospaced)
        }
    }
    
    private var keyFontWeight: Font.Weight {
        isPressed ? .bold : .medium
    }
    
    private var keyShadowColor: Color {
        isPressed ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    private var keyShadowRadius: CGFloat {
        isPressed ? 4 : 2
    }
    
    private var keyShadowOffset: CGFloat {
        isPressed ? 2 : 1
    }
}

// MARK: - Preview

struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                // Regular key
                KeyView(physicalKey: "a", config: .defaultQWERTY)
                
                // Navigation key
                KeyView(physicalKey: "h", config: .defaultQWERTY)
                
                // Space bar
                KeyView(physicalKey: "spc", config: .defaultQWERTY)
            }
            
            Text("Key views with different states")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .environmentObject(AnimationController())
    }
} 