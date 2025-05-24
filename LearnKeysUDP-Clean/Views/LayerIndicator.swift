import SwiftUI

/// Layer status display driven by UDP layer changes
struct LayerIndicator: View {
    @EnvironmentObject var animationController: AnimationController
    @EnvironmentObject var layerManager: LayerManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Layer indicator
            HStack {
                Image(systemName: layerIcon)
                    .foregroundColor(layerColor)
                
                Text(layerDisplayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(layerColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(layerColor.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            // Active indicators
            if animationController.getActiveKeyCount() > 0 {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.green)
                    Text("\(animationController.getActiveKeyCount())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            if animationController.getActiveModifierCount() > 0 {
                HStack {
                    Image(systemName: "command")
                        .foregroundColor(.orange)
                    Text("\(animationController.getActiveModifierCount())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: animationController.currentLayer)
    }
    
    private var layerDisplayName: String {
        layerManager.getLayerDisplayName(animationController.currentLayer)
    }
    
    private var layerIcon: String {
        switch animationController.currentLayer.lowercased() {
        case "base":
            return "keyboard"
        case "f-nav", "fnav":
            return "arrow.up.arrow.down.arrow.left.arrow.right"
        case "navfast":
            return "bolt"
        case "nomods":
            return "keyboard.badge.ellipsis"
        default:
            return "square.stack.3d.up"
        }
    }
    
    private var layerColor: Color {
        switch animationController.currentLayer.lowercased() {
        case "base":
            return .primary
        case "f-nav", "fnav":
            return .blue
        case "navfast":
            return .purple
        case "nomods":
            return .gray
        default:
            return .secondary
        }
    }
}

// MARK: - Preview

struct LayerIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            LayerIndicator()
            
            Text("Layer indicator shows current state")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .environmentObject(AnimationController())
        .environmentObject(LayerManager())
    }
} 