import SwiftUI

// MARK: - Key Visual Components

struct KeyCap: View {
    let label: String
    let symbol: String?
    let isArrow: Bool
    let isActive: Bool
    let arrowDirection: String? // "left", "right", "up", "down" for arrow keys
    let temporaryState: TemporaryKeyState? // For special temporary states

    private var keyCapWidth: CGFloat {
        if isArrow {
            return 54
        } else {
            return 120 // User set width
        }
    }

    // Centralized styling properties
    private var modifierLabelFont: Font {
        .system(size: 18, design: .default)
    }

    private var modifierLabelColor: Color {
        isActive ? Color(hex: "232323") : Color(hex: "F7F7F7")
    }

    private var modifierSymbolFont: Font {
        .system(size: 32, weight: .light, design: .default)
    }

    private var modifierSymbolColor: Color {
        isActive ? Color(hex: "232323") : Color(hex: "F7F7F7")
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
        .background(
            Group {
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
                            gradient: Gradient(colors: [Color(hex: "F9F8F8"), Color(hex: "D0CFCF")]),
                            startPoint: .top, endPoint: .bottom
                        )
                        .opacity(0.3)
                    }
                } else {
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "F7F7F7"), Color(hex: "E0E0E0")]),
                            startPoint: .top, endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "656565"), Color(hex: "4D4D4E")]),
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                }
            }
        )
        // Key border: gradient or solid depending on type and state
        .overlay(
            Group {
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
                                    gradient: Gradient(colors: [Color(hex: "B0B0B0"), Color(hex: "D0D0D0")]),
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "777778"), Color(hex: "5B5B5B")]),
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                    }
                }
            }
        )
        .cornerRadius(10)
        // Modifier key tilt and blur animation
        .modifier(ModifierKeyTiltBlur(isActive: isActive, isArrow: isArrow))
        // Arrow key tilt and invert effect
        .modifier(ArrowKeyTiltInvert(isActive: isActive, isArrow: isArrow, arrowDirection: arrowDirection))
    }
}

// MARK: - View Modifiers

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
            let tilt: Double = isActive ? 30 : 0
            let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
            switch arrowDirection {
            case "left":
                axis = (x: 0, y: -1, z: 0)
            case "right":
                axis = (x: 0, y: 1, z: 0)
            case "up":
                axis = (x: 1, y: 0, z: 0)
            case "down":
                axis = (x: -1, y: 0, z: 0)
            default:
                axis = (x: 1, y: 0, z: 0)
            }
            return AnyView(
                content
                    .rotation3DEffect(
                        .degrees(tilt),
                        axis: axis,
                        anchor: .center
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            )
        } else {
            return AnyView(content)
        }
    }
} 