import SwiftUI

/// Original keyboard display - selective key display based on layer
struct KeyboardView: View {
    @State private var config = KanataConfig.defaultQWERTY
    @EnvironmentObject var animationController: AnimationController
    @EnvironmentObject var layerManager: LayerManager
    
    var body: some View {
        VStack(spacing: 20) {
            if animationController.currentLayer == "base" {
                // Base layer: show only modifier keys in a compact row (original behavior)
                modifierOnlyRow()
            } else {
                // Other layers: show only non-transparent keys (original behavior)
                nonTransparentKeysLayout()
            }
        }
        .frame(minHeight: 200)
    }
    
    // MARK: - Original Base Layer Display
    
    private func modifierOnlyRow() -> some View {
        HStack(spacing: 20) {
            // Left side modifiers
            HStack(spacing: 15) {
                OriginalKeyCap(label: "Shift", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("shift"))
                OriginalKeyCap(label: "Control", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("control"))
                OriginalKeyCap(label: "Option", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("option"))
                OriginalKeyCap(label: "F-Nav", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("f"))
                OriginalKeyCap(label: "Command", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("command"))
                }
            
            Spacer()
            
            // Right side modifiers
            HStack(spacing: 15) {
                OriginalKeyCap(label: "Command", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("command"))
                OriginalKeyCap(label: "Option", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("option"))
                OriginalKeyCap(label: "Control", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("control"))
                OriginalKeyCap(label: "Shift", symbol: nil as String?, isArrow: false, isActive: animationController.isModifierActive("shift"))
                }
        }
        .padding()
            }
            
    // MARK: - Original Non-Base Layer Display
    
    private func nonTransparentKeysLayout() -> some View {
        VStack(spacing: 15) {
            Text("Layer: \(animationController.currentLayer.uppercased())")
                .font(.headline)
                .foregroundColor(.blue)
            
            // Show navigation keys for f-nav layer
            if animationController.currentLayer == "f-nav" {
                HStack(spacing: 15) {
                    OriginalKeyCap(label: "←", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("h")?.isPressed ?? false, arrowDirection: "left")
                    OriginalKeyCap(label: "↓", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("j")?.isPressed ?? false, arrowDirection: "down")
                    OriginalKeyCap(label: "↑", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("k")?.isPressed ?? false, arrowDirection: "up")
                    OriginalKeyCap(label: "→", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("l")?.isPressed ?? false, arrowDirection: "right")
                }
            }
            
            // Show fast navigation for navfast layer
            if animationController.currentLayer == "navfast" {
                HStack(spacing: 15) {
                    OriginalKeyCap(label: "⇤", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("h")?.isPressed ?? false, arrowDirection: "left")
                    OriginalKeyCap(label: "⇟", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("j")?.isPressed ?? false, arrowDirection: "down")
                    OriginalKeyCap(label: "⇞", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("k")?.isPressed ?? false, arrowDirection: "up")
                    OriginalKeyCap(label: "⇥", symbol: nil as String?, isArrow: true, isActive: animationController.getKeyState("l")?.isPressed ?? false, arrowDirection: "right")
                }
            }
        }
    }
}

// MARK: - Animated Letter Row (Exact Original Implementation)

struct AnimatedLetterRow: View {
    @EnvironmentObject var animationController: AnimationController
    
    private let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
    private let slotWidth: CGFloat = 64
    private let slotSpacing: CGFloat = 64 * 1.2
    private let smallFontSize: CGFloat = 60
    private let largeFontSize: CGFloat = 120
    private let overlayScale: CGFloat = 1.25
    private let overlayFrameHeight: CGFloat = 80
    private let drawWidth: CGFloat = 160
    
    var body: some View {
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            // Base letter row (small letters, always visible when not active)
            letterRow
            
            // Overlay animated letters (large letters, only when active)
            overlayAnimatedLetters
        }
        .frame(width: totalWidth, height: overlayFrameHeight)
    }
    
    private var letterRow: some View {
        HStack(spacing: slotSpacing) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let physicalKey = homeRowPhysicalKey(for: index)
                let isActive = animationController.getKeyState(physicalKey)?.isPressed ?? false
                
                ZStack {
                    if !isActive {
                        Text(letter)
                            .font(.system(size: smallFontSize, weight: .light, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: slotWidth, height: overlayFrameHeight)
            }
        }
    }
    
    private var overlayAnimatedLetters: some View {
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let physicalKey = homeRowPhysicalKey(for: index)
                let isActive = animationController.getKeyState(physicalKey)?.isPressed ?? false
                
                if isActive {
                    Text(letter)
                        .font(.system(size: largeFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .scaleEffect(overlayScale)
                        .shadow(color: .white.opacity(0.5), radius: 4)
                        .frame(width: drawWidth, height: overlayFrameHeight)
                        .position(x: CGFloat(index) * (slotWidth + slotSpacing) + slotWidth/2, y: overlayFrameHeight/2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
                }
            }
        }
        .frame(width: totalWidth, height: overlayFrameHeight)
    }
    
    private func homeRowPhysicalKey(for index: Int) -> String {
        let homeRowKeys = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        return index < homeRowKeys.count ? homeRowKeys[index] : "a"
    }
}

// MARK: - Preview

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedLetterRow()
            KeyboardView()
        }
        .padding()
        .background(.black)
        .environmentObject(AnimationController())
        .environmentObject(LayerManager())
    }
} 