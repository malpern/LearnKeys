import SwiftUI

/// Main keyboard display using only UDP state
struct KeyboardView: View {
    @State private var config = KanataConfig.defaultQWERTY
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row
            HStack(spacing: 4) {
                ForEach(topRowKeys, id: \.self) { key in
                    KeyView(physicalKey: key, config: config)
                }
            }
            
            // Middle row (home row)
            HStack(spacing: 4) {
                ForEach(middleRowKeys, id: \.self) { key in
                    KeyView(physicalKey: key, config: config)
                }
            }
            
            // Bottom row
            HStack(spacing: 4) {
                ForEach(bottomRowKeys, id: \.self) { key in
                    KeyView(physicalKey: key, config: config)
                }
            }
            
            // Space bar row
            HStack {
                KeyView(physicalKey: "spc", config: config)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.systemGray))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Key Layout
    
    private var topRowKeys: [String] {
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    }
    
    private var middleRowKeys: [String] {
        ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
    }
    
    private var bottomRowKeys: [String] {
        ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
    }
}

// MARK: - Preview

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LayerIndicator()
            KeyboardView()
        }
        .padding()
        .environmentObject(AnimationController())
        .environmentObject(LayerManager())
    }
} 