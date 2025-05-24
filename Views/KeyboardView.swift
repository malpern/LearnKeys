import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var animationController: AnimationController
    
    // Simple QWERTY layout for testing
    private let topRow = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let homeRow = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
    private let bottomRow = ["z", "x", "c", "v", "b", "n", "m"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            headerView
            
            // Keyboard layout
            VStack(spacing: 4) {
                // Top row
                HStack(spacing: 4) {
                    ForEach(topRow, id: \.self) { key in
                        KeyView(physicalKey: key)
                    }
                }
                
                // Home row (with modifiers)
                HStack(spacing: 4) {
                    ForEach(homeRow, id: \.self) { key in
                        KeyView(physicalKey: key)
                    }
                }
                
                // Bottom row
                HStack(spacing: 4) {
                    ForEach(bottomRow, id: \.self) { key in
                        KeyView(physicalKey: key)
                    }
                }
                
                // Spacebar
                KeyView(physicalKey: "spc")
                    .frame(width: 200)
            }
            
            // Status
            statusView
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var headerView: some View {
        VStack {
            Text("LearnKeys UDP")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Layer: \(animationController.currentLayer)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Keys: \(animationController.getActiveKeys().joined(separator: ", "))")
                .font(.caption)
            
            Text("Active Modifiers: \(animationController.getActiveModifiers().joined(separator: ", "))")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
} 