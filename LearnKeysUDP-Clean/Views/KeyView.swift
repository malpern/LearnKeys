import SwiftUI

// MARK: - Original KeyCap Component (Pixel-Perfect Replica)

struct OriginalKeyCap: View {
    let label: String
    let symbol: String?
    let isArrow: Bool
    let isActive: Bool
    let arrowDirection: String? // "left", "right", "up", "down" for arrow keys
    let temporaryState: TemporaryKeyState? // For special temporary states

    init(label: String, symbol: String? = nil, isArrow: Bool, isActive: Bool, arrowDirection: String? = nil, temporaryState: TemporaryKeyState? = nil) {
        self.label = label
        self.symbol = symbol
        self.isArrow = isArrow
        self.isActive = isActive
        self.arrowDirection = arrowDirection
        self.temporaryState = temporaryState
    }

    private var keyCapWidth: CGFloat {
        if isArrow {
            return 54
        } else {
            return 120 // User set width
        }
    }

    // Centralized styling properties (exact original)
    private var modifierLabelFont: Font {
        .system(size: 18, design: .default)
    }

    private var modifierLabelColor: Color {
        isActive ? (Color(hex: "232323") ?? .black) : (Color(hex: "F7F7F7") ?? .white)
    }

    private var modifierSymbolFont: Font {
        .system(size: 32, weight: .light, design: .default)
    }

    private var modifierSymbolColor: Color {
        isActive ? (Color(hex: "232323") ?? .black) : (Color(hex: "F7F7F7") ?? .white)
    }

    private var modifierLabelPadding: CGFloat { 12 }
    private var modifierSymbolPadding: CGFloat { 12 }
    private var arrowLabelFont: Font {
        .system(size: 28, weight: .bold, design: .default)
    }

    private var arrowLabelColor: Color { .black }
    private var arrowLabelShadow: Color { .white.opacity(0.7) }
    private var arrowSymbolFont: Font {
        .system(size: 20, weight: .bold, design: .default)
    }

    private var arrowSymbolColor: Color {
        isActive ? .black.opacity(0.8) : .white.opacity(0.8)
    }

    private var modifierLabelOpacity: Double { 0.4 }
    
    var body: some View {
        VStack(alignment: .center, spacing: isArrow ? 0 : 2.2) {
            // Render symbol (if present) above the label
            if let symbol = symbol {
                if isArrow {
                    Text(symbol)
                        .font(arrowSymbolFont)
                        .foregroundColor(isActive ? .white : arrowSymbolColor)
                } else {
                    Text(symbol)
                        .font(modifierSymbolFont)
                        .foregroundColor(modifierSymbolColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.leading, modifierSymbolPadding)
                        .padding(.trailing, modifierSymbolPadding)
    }
            }
            // Render label (main key name)
            if isArrow {
                Text(label)
                    .font(arrowLabelFont)
                    .foregroundColor(isActive ? .white : arrowLabelColor)
                    .shadow(color: arrowLabelShadow, radius: 0.2, x: 0, y: 0.2)
            } else {
                Text(label)
                    .font(modifierLabelFont)
                    .foregroundColor(modifierLabelColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, modifierLabelPadding)
                    .padding(.trailing, modifierLabelPadding)
                    .opacity(modifierLabelOpacity)
    }
        }
        .frame(width: keyCapWidth, height: isArrow ? 54 : 72)
        // Key background: gradient and pressed state
        .background(keyBackground)
        // Key border: gradient or solid depending on type and state
        .overlay(keyBorder)
        .cornerRadius(10)
        // Modifier key tilt and blur animation
        .modifier(ModifierKeyTiltBlur(isActive: isActive, isArrow: isArrow))
        // Arrow key tilt and invert effect
        .modifier(ArrowKeyTiltInvert(isActive: isActive, isArrow: isArrow, arrowDirection: arrowDirection))
    }
    
    @ViewBuilder
    private var keyBackground: some View {
        if let tempState = temporaryState, tempState != .none {
            // Use temporary state styling
            let colors = tempState.backgroundColor
            LinearGradient(
                gradient: Gradient(colors: isActive ? colors.active : colors.inactive),
                startPoint: .top, endPoint: .bottom
            )
        } else if isArrow {
            if isActive {
                LinearGradient(
                    gradient: Gradient(colors: [Color(white: 0.22), Color(white: 0.13)]),
                    startPoint: .top, endPoint: .bottom
                )
                .opacity(0.7)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "F9F8F8") ?? .white, Color(hex: "D0CFCF") ?? .gray]),
                    startPoint: .top, endPoint: .bottom
                )
                .opacity(0.3)
            }
        } else {
            if isActive {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "F7F7F7") ?? .white, Color(hex: "E0E0E0") ?? .gray]),
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "656565") ?? .gray, Color(hex: "4D4D4E") ?? .gray]),
                    startPoint: .top, endPoint: .bottom
                )
        }
    }
    }
    
    @ViewBuilder
    private var keyBorder: some View {
        if let tempState = temporaryState, tempState != .none {
            // Use temporary state border colors
            let borderColors = tempState.borderColor
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? borderColors.active : borderColors.inactive, lineWidth: 3)
        } else if isArrow {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.white.opacity(0.7) : Color.black.opacity(0.4), lineWidth: 1)
        } else {
            if isActive {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "B0B0B0") ?? .gray, Color(hex: "D0D0D0") ?? .gray]),
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "777778") ?? .gray, Color(hex: "5B5B5B") ?? .gray]),
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
            }
        }
    }
}

// MARK: - View Modifiers (Exact Original)

// Custom view modifier for modifier key tilt and blur
struct ModifierKeyTiltBlur: ViewModifier {
    let isActive: Bool
    let isArrow: Bool
    
    func body(content: Content) -> some View {
        if isArrow {
            content
        } else {
            content
                .rotation3DEffect(
                    .degrees(isActive ? 30 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center
                )
                .blur(radius: isActive ? 2.4 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
    }
}

// Custom view modifier for arrow key tilt and color invert
struct ArrowKeyTiltInvert: ViewModifier {
    let isActive: Bool
    let isArrow: Bool
    let arrowDirection: String?
    
    func body(content: Content) -> some View {
        if isArrow {
            content
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
        } else {
            content
        }
    }
}

// MARK: - Supporting Types

enum TemporaryKeyState {
    case none
    case layer
    case chord
    case error
    
    var backgroundColor: (active: [Color], inactive: [Color]) {
        switch self {
        case .none:
            return (active: [.clear], inactive: [.clear])
        case .layer:
            return (
                active: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                inactive: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)]
            )
        case .chord:
            return (
                active: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)],
                inactive: [Color.purple.opacity(0.4), Color.purple.opacity(0.2)]
            )
        case .error:
            return (
                active: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                inactive: [Color.red.opacity(0.4), Color.red.opacity(0.2)]
            )
        }
    }
    
    var borderColor: (active: Color, inactive: Color) {
        switch self {
        case .none:
            return (active: .clear, inactive: .clear)
        case .layer:
            return (active: .blue, inactive: .blue.opacity(0.5))
        case .chord:
            return (active: .purple, inactive: .purple.opacity(0.5))
        case .error:
            return (active: .red, inactive: .red.opacity(0.5))
    }
    }
}

// MARK: - Color Extension (for hex colors)

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue:  Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

// MARK: - Preview

struct OriginalKeyCap_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Original KeyCap Design - Pixel Perfect")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                // Modifier key (inactive)
                OriginalKeyCap(label: "Shift", symbol: nil as String?, isArrow: false, isActive: false)
                
                // Modifier key (active)
                OriginalKeyCap(label: "Control", symbol: nil as String?, isArrow: false, isActive: true)
                
                // Arrow key (inactive)
                OriginalKeyCap(label: "←", symbol: nil as String?, isArrow: true, isActive: false, arrowDirection: "left")
                
                // Arrow key (active)
                OriginalKeyCap(label: "→", symbol: nil as String?, isArrow: true, isActive: true, arrowDirection: "right")
            }
            
            Text("Exact replica of original LearnKeys styling")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.black)
    }
} 