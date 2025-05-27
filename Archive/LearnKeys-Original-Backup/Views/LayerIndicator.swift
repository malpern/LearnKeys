import SwiftUI

/// Simple layer status display - exact original replica
struct LayerIndicator: View {
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
            HStack {
            Text("Layer: \(animationController.currentLayer)")
                    .font(.headline)
                .foregroundColor(.blue)
            
            Spacer()
            
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
            
            Text("Connected")
                        .font(.caption)
                .foregroundColor(.gray)
    }
        .padding()
    }
}

// MARK: - Preview

struct LayerIndicator_Previews: PreviewProvider {
    static var previews: some View {
            LayerIndicator()
        .padding()
            .background(.black)
        .environmentObject(AnimationController())
    }
} 