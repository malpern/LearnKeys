import Foundation
import Network

// MARK: - TCP Client for Kanata

class KanataTCPClient: ObservableObject {
    @Published var currentLayer: String = "base"
    @Published var isConnected: Bool = false
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "kanata-tcp")
    
    func connect() {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(integerLiteral: 5829)
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    print("[TCP] Connected to kanata")
                case .failed(let error):
                    self?.isConnected = false
                    print("[TCP] Connection failed: \(error)")
                case .cancelled:
                    self?.isConnected = false
                    print("[TCP] Connection cancelled")
                default:
                    break
                }
            }
        }
        
        startReceiving()
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? ""
                self?.parseMessage(message)
            }
            
            if isComplete {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            } else if error == nil {
                self?.startReceiving()
            }
        }
    }
    
    private func parseMessage(_ message: String) {
        let lines = message.components(separatedBy: .newlines)
        for line in lines {
            if line.isEmpty { continue }
            
            print("[TCP] Raw message: \(line)")
            
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Parse layer change messages
                if let layerChange = json["LayerChange"] as? [String: Any],
                   let newLayer = layerChange["new"] as? String {
                    DispatchQueue.main.async {
                        self.currentLayer = newLayer
                        print("[TCP] Layer changed to: \(newLayer)")
                    }
                    return
                }
                
                // Handle other message types as needed
                print("[TCP] Unhandled message type: \(json)")
            } else {
                print("[TCP] 🔍 Non-JSON message: \(line)")
            }
        }
    }
} 