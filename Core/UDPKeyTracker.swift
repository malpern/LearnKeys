import Foundation
import Network

/// UDP-First Key Tracker - Primary input source
class UDPKeyTracker: ObservableObject {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "UDPKeyTracker", qos: .userInitiated)
    
    // Callbacks for different message types
    var onKeyPress: ((String) -> Void)?
    var onModifierChange: ((String, Bool) -> Void)?
    var onLayerChange: ((String) -> Void)?
    var onNavigationKey: ((String) -> Void)?
    
    public func startListening(port: UInt16 = 6789) {
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
            
            DispatchQueue.main.async {
                LogManager.shared.log("🎯 UDP-First KeyTracker ready on port \(port)", category: "INIT")
                LogManager.shared.log("🎯 Listening for: keypress:*, navkey:*, modifier:*, layer:*", category: "INIT")
            }
            
        } catch {
            LogManager.shared.log("❌ Failed to start UDP listener: \(error)", category: "ERROR")
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        func receive() {
            connection.receiveMessage { [weak self] data, _, isComplete, error in
                if let data = data, !data.isEmpty {
                    if let message = String(data: data, encoding: .utf8) {
                        self?.processMessage(message.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                
                if let error = error {
                    LogManager.shared.log("⚠️ Connection error: \(error)", category: "NET")
                }
                
                if !isComplete {
                    receive()
                }
            }
        }
        
        receive()
    }
    
    public func processMessage(_ message: String) {
        DispatchQueue.main.async {
            LogManager.shared.log("📨 Received: \(message)", category: "UDP")
            
            let components = message.split(separator: ":")
            guard !components.isEmpty else { 
                LogManager.shared.log("❌ Empty message received", category: "ERROR")
                return 
            }
            
            let command = String(components[0])
            
            switch command {
            case "keypress":
                if components.count >= 2 {
                    let key = String(components[1])
                    LogManager.shared.log("⌨️  Key press: \(key)", category: "KEY")
                    self.onKeyPress?(key)
                } else {
                    LogManager.shared.log("❌ Invalid keypress format: \(message)", category: "ERROR")
                }
                
            case "navkey":
                if components.count >= 2 {
                    let key = String(components[1])
                    LogManager.shared.log("🧭 Navigation key: \(key)", category: "NAV")
                    self.onNavigationKey?(key)
                } else {
                    LogManager.shared.log("❌ Invalid navkey format: \(message)", category: "ERROR")
                }
                
            case "modifier":
                if components.count >= 3 {
                    let modifier = String(components[1])
                    let state = String(components[2])
                    let isActive = (state == "down" || state == "on")
                    LogManager.shared.log("🔧 Modifier \(modifier): \(isActive ? "ON" : "OFF")", category: "MOD")
                    self.onModifierChange?(modifier, isActive)
                } else {
                    LogManager.shared.log("❌ Invalid modifier format: \(message)", category: "ERROR")
                }
                
            case "layer":
                if components.count >= 2 {
                    let layer = String(components[1])
                    LogManager.shared.log("🎚️  Layer change: \(layer)", category: "LAYER")
                    self.onLayerChange?(layer)
                } else {
                    LogManager.shared.log("❌ Invalid layer format: \(message)", category: "ERROR")
                }
                
            case "combo":
                // Handle key combinations
                if components.count >= 2 {
                    let combo = String(components[1])
                    LogManager.shared.log("🔗 Combo keys: \(combo)", category: "COMBO")
                    // Process each key in the combo
                    let keys = combo.split(separator: "+")
                    for key in keys {
                        self.onKeyPress?(String(key))
                    }
                } else {
                    LogManager.shared.log("❌ Invalid combo format: \(message)", category: "ERROR")
                }
                
            default:
                LogManager.shared.log("⚠️  Unknown command: \(command) in message: \(message)", category: "WARN")
            }
        }
    }
    
    deinit {
        listener?.cancel()
    }
} 