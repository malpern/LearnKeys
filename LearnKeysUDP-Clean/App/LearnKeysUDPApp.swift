import Foundation
import SwiftUI

@main
struct LearnKeysUDPApp: App {
    @StateObject private var animationController = AnimationController()
    @StateObject private var layerManager = LayerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(animationController)
                .environmentObject(layerManager)
                .onAppear {
                    print("🎯 LearnKeys UDP-First started!")
                    print("🎯 Architecture: Clean UDP-driven design")
                    print("🎯 No accessibility permissions needed")
                }
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @EnvironmentObject var animationController: AnimationController
    @EnvironmentObject var layerManager: LayerManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Main keyboard view
            KeyboardView()
                .frame(maxWidth: 600)
            
            // Status and controls
            statusView
            
            // UDP test controls
            testControlsView
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("LearnKeys UDP-First")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Clean UDP-driven architecture - No accessibility permissions needed!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Single source of truth: UDP messages from Kanata")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusView: some View {
        HStack(spacing: 30) {
            // Current layer
            VStack {
                Text("Current Layer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(layerManager.getLayerDisplayName(animationController.currentLayer))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Active keys count
            VStack {
                Text("Active Keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(animationController.getActiveKeyCount())")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Active modifiers count
            VStack {
                Text("Modifiers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(animationController.getActiveModifierCount())")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // UDP status
            VStack {
                Text("UDP Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Listening")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var testControlsView: some View {
        VStack(spacing: 12) {
            Text("UDP Test Controls")
                .font(.headline)
            
            Text("Test the UDP-driven animations without Kanata")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Test 'A' Key") {
                    testUDPMessage("keypress:a")
                }
                
                Button("Test 'S' Key") {
                    testUDPMessage("keypress:s")
                }
                
                Button("Test Space") {
                    testUDPMessage("keypress:spc")
                }
                
                Button("Test Navigation") {
                    testUDPMessage("navkey:h")
                }
            }
            .buttonStyle(.bordered)
            
            HStack(spacing: 12) {
                Button("Shift Down") {
                    testUDPMessage("modifier:shift:down")
                }
                
                Button("Shift Up") {
                    testUDPMessage("modifier:shift:up")
                }
                
                Button("Nav Layer") {
                    testUDPMessage("layer:f-nav")
                }
                
                Button("Base Layer") {
                    testUDPMessage("layer:base")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func testUDPMessage(_ message: String) {
        print("🧪 Testing UDP message: \(message)")
        animationController.processTestMessage(message)
    }
} 