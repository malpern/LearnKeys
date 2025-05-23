import SwiftUI
import Foundation

// MARK: - Main Dashboard View

struct LearnKeysView: View {
    @StateObject private var configParser = KanataConfigParser()
    @StateObject internal var tcpClient = KanataTCPClient()
    @StateObject internal var keyMonitor = GlobalKeyMonitor()
    
    @State internal var config = KanataConfig()
    
    private let configPath: String
    
    init(configPath: String) {
        self.configPath = configPath
    }
    
    var currentLayerKeys: [String] {
        config.layers[tcpClient.currentLayer] ?? []
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Header
            headerView
            
            // Animated letter row (always shown)
            animatedLetterRow
            
            // Key Layout
            if !config.defsrc.isEmpty {
                keyboardLayout
            } else {
                emptyStateView
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
            tcpClient.connect()
            loadConfigFromPath()
            setupLayerChangeListener()
        }
        .onDisappear {
            tcpClient.disconnect()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LearnKeys")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(URL(fileURLWithPath: configPath).lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Layer: \(tcpClient.currentLayer)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Circle()
                    .fill(tcpClient.isConnected ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text(tcpClient.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private var animatedLetterRow: some View {
        let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let smallFontSize: CGFloat = 60
        let largeFontSize: CGFloat = 120
        let overlayScale: CGFloat = 1.25
        let overlayFrameHeight: CGFloat = 80
        let drawWidth: CGFloat = 160
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            // Base letter row (small letters, always visible when not active)
            letterRow(letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing, 
                     smallFontSize: smallFontSize, overlayFrameHeight: overlayFrameHeight)
            
            // Overlay animated letters (large letters, only when active)
            overlayAnimatedLetters(letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing,
                                 largeFontSize: largeFontSize, overlayScale: overlayScale, 
                                 overlayFrameHeight: overlayFrameHeight, drawWidth: drawWidth)
        }
        .frame(width: totalWidth, height: overlayFrameHeight)
    }
    
    private var keyboardLayout: some View {
        VStack(spacing: 20) {
            if tcpClient.currentLayer == "base" {
                // Base layer: show only modifier keys in a compact row
                modifierOnlyRow()
            } else {
                // Other layers: show only non-transparent keys
                nonTransparentKeysLayout()
            }
        }
        .frame(minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("No Config Loaded")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Load a kanata config file to see your key mappings")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadConfigFromPath() {
        let url = URL(fileURLWithPath: configPath)
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            config = configParser.parseConfig(from: content)
            print("Loaded config '\(configPath)' with \(config.layers.count) layers")
            
            // Build dynamic modifier map from config
            updateModifierMapping()
        } catch {
            print("Error loading config '\(configPath)': \(error)")
            NSApp.terminate(nil)
        }
    }
    
    private func setupLayerChangeListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LayerChanged"),
            object: nil,
            queue: .main
        ) { notification in
            guard let newLayer = notification.object as? String else { return }
            
            // Find which physical key triggered this layer change
            let layerTriggerKey = findLayerTriggerKey(for: newLayer)
            
            if let triggerKey = layerTriggerKey {
                // Animate the layer trigger key for a short duration
                keyMonitor.updateLayerKeyState(physicalKey: triggerKey, isActive: true, layerType: "layer")
                
                // Auto-release the animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    keyMonitor.updateLayerKeyState(physicalKey: triggerKey, isActive: false, layerType: "layer")
                }
            }
        }
        
        // Listen for chord activation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChordActivated"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.object as? [String: String],
                  let chord = userInfo["chord"],
                  let layer = userInfo["layer"] else { return }
            
            print("DEBUG: 🎹 Chord UI notification: \(chord) -> \(layer)")
            
            // Simulate layer change for chord-activated layer
            if chord == "f+d" && layer == "navfast" {
                tcpClient.currentLayer = "navfast"
            }
        }
        
        // Listen for chord deactivation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChordDeactivated"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.object as? [String: String],
                  let chord = userInfo["chord"] else { return }
            
            print("DEBUG: 🎹 Chord UI deactivation: \(chord)")
            
            // Return to base layer when chord is released
            if chord == "f+d" {
                tcpClient.currentLayer = "base"
            }
        }
    }
    
    private func findLayerTriggerKey(for layerName: String) -> String? {
        // Find which key in the base layer has a layer action that leads to this layer
        guard let baseLayer = config.layers["base"] else { return nil }
        
        for (index, physicalKey) in config.defsrc.enumerated() {
            if index < baseLayer.count {
                let layerKey = baseLayer[index]
                
                if layerKey.hasPrefix("@") {
                    let aliasName = String(layerKey.dropFirst())
                    if let alias = config.aliases[aliasName] {
                        if let holdAction = alias.holdAction,
                           holdAction.contains("layer") && 
                           (holdAction.contains(layerName) || layerName != "base") {
                            return physicalKey
                        }
                    }
                }
            }
        }
        
        // Fallback: F key is commonly used for navigation layer
        if layerName.contains("nav") {
            return "f"
        }
        
        return nil
    }
} 