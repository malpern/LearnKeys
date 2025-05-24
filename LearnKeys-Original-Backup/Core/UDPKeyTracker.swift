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
                print("🎯 UDP-First KeyTracker ready on port \(port)")
                print("🎯 Listening for: keypress:*, navkey:*, modifier:*, layer:*")
            }
            
        } catch {
            print("❌ Failed to start UDP listener: \(error)")
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
                
                if !isComplete {
                    receive()
                }
            }
        }
        
        receive()
    }
    
    public func processMessage(_ message: String) {
        DispatchQueue.main.async {
            print("🎯 UDP: \(message)")
            
            let components = message.split(separator: ":")
            guard !components.isEmpty else { return }
            
            let command = String(components[0])
            
            switch command {
            case "keypress":
                if components.count >= 2 {
                    let key = String(components[1])
                    self.onKeyPress?(key)
                }
                
            case "navkey":
                if components.count >= 2 {
                    let key = String(components[1])
                    self.onNavigationKey?(key)
                }
                
            case "modifier":
                if components.count >= 3 {
                    let modifier = String(components[1])
                    let state = String(components[2])
                    let isActive = (state == "down" || state == "on")
                    self.onModifierChange?(modifier, isActive)
                }
                
            case "layer":
                if components.count >= 2 {
                    let layer = String(components[1])
                    self.onLayerChange?(layer)
                }
                
            case "combo":
                // Handle key combinations
                if components.count >= 2 {
                    let combo = String(components[1])
                    // Process each key in the combo
                    let keys = combo.split(separator: "+")
                    for key in keys {
                        self.onKeyPress?(String(key))
                    }
                }
                
            default:
                print("⚠️  Unknown UDP command: \(command)")
            }
        }
    }
    
    deinit {
        listener?.cancel()
    }
} 