import SwiftUI

@main
struct LearnKeysUDPApp: App {
    @StateObject private var animationController = AnimationController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(animationController)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
        VStack {
            // Header
            headerView
            
            // Main keyboard view
            KeyboardView()
            
            // UDP Test controls
            testControlsView
            
            Spacer()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("LearnKeys UDP-First")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Clean UDP-driven architecture - No accessibility permissions needed!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var testControlsView: some View {
        VStack(spacing: 12) {
            Text("UDP Test Controls")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button("Test Key 'A'") {
                    testUDPMessage("keypress:a")
                }
                
                Button("Test Modifier") {
                    testUDPMessage("modifier:shift:down")
                }
                
                Button("Test Navigation") {
                    testUDPMessage("navkey:h")
                }
                
                Button("Test Layer") {
                    testUDPMessage("layer:f-nav")
                }
            }
            .buttonStyle(.bordered)
            
            Text("Click keys above or use these test buttons to see UDP-driven animations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func testUDPMessage(_ message: String) {
        print("🧪 Testing UDP message: \(message)")
        
        // Simulate UDP message processing
        let components = message.split(separator: ":")
        
        switch String(components[0]) {
        case "keypress":
            let key = String(components[1])
            animationController.keyStates[key] = KeyState(key: key, isPressed: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animationController.keyStates[key]?.isPressed = false
            }
            
        case "modifier":
            let modifier = String(components[1])
            let isActive = components[2] == "down"
            animationController.modifierStates[modifier] = ModifierState(modifier: modifier, isActive: isActive)
            
        case "navkey":
            let key = String(components[1])
            animationController.keyStates[key] = KeyState(key: key, isPressed: true, keyType: .navigation)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animationController.keyStates[key]?.isPressed = false
            }
            
        case "layer":
            let layer = String(components[1])
            animationController.currentLayer = layer
            
        default:
            print("Unknown UDP message type")
        }
    }
} 