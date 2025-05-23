import Foundation
import Network

class UDPKeyTracker: ObservableObject {
    @Published var activeNavKeys: Set<String> = []
    @Published var activeKeys: Set<String> = []  // Track all key presses
    @Published var activeModifiers: Set<String> = []  // Track modifiers
    @Published var currentLayer: String = "base"  // Track layer changes via UDP
    
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 6789
    private let queue = DispatchQueue(label: "udp-key-tracker")
    private var keyTimers: [String: Timer] = [:]
    private var navKeyTimers: [String: Timer] = [:]
    private var modifierTimers: [String: Timer] = [:]
    
    init() {
        setupUDPListener()
    }
    
    deinit {
        stopListening()
    }
    
    private func setupUDPListener() {
        do {
            listener = try NWListener(using: .udp, on: port)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("🔊 UDP KeyTracker ready on port 6789")
                    print("🔊 Listening for: navkey:*, keypress:*, modifier:*, layer:*")
                case .failed(let error):
                    print("🔊 UDP KeyTracker failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.start(queue: queue)
            
        } catch {
            print("🔊 UDP KeyTracker setup failed: \(error)")
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        func receiveMessage() {
            connection.receiveMessage { [weak self] (data, context, isComplete, error) in
                if let data = data, !data.isEmpty {
                    if let message = String(data: data, encoding: .utf8) {
                        self?.processMessage(message.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                
                if !isComplete {
                    receiveMessage()
                }
            }
        }
        
        receiveMessage()
    }
    
    private func processMessage(_ message: String) {
        print("🔊 UDP received: '\(message)'")
        
        // Parse different message types
        if message.hasPrefix("navkey:") {
            let key = String(message.dropFirst(7)) // Remove "navkey:" prefix
            print("🔊 📡 Parsed as navigation key: '\(key)'")
            activateNavKey(key)
        } else if message.hasPrefix("keypress:") {
            let key = String(message.dropFirst(9)) // Remove "keypress:" prefix
            print("🔊 ⌨️  Parsed as basic keypress: '\(key)'")
            activateKey(key)
        } else if message.hasPrefix("modifier:") {
            print("🔊 🎛️  Parsed as modifier message")
            parseModifierMessage(message)
        } else if message.hasPrefix("layer:") {
            let layer = String(message.dropFirst(6)) // Remove "layer:" prefix
            print("🔊 🗂️  Parsed as layer change: '\(layer)'")
            updateLayer(layer)
        } else if !message.isEmpty {
            print("🔊 ❓ UDP unknown message format: '\(message)'")
        } else {
            print("🔊 ⚠️  Received empty UDP message")
        }
    }
    
    private func parseModifierMessage(_ message: String) {
        let components = message.components(separatedBy: ":")
        guard components.count >= 3 else {
            print("🔊 UDP invalid modifier message: '\(message)'")
            return
        }
        
        let modifier = components[1]
        let action = components[2]
        
        if action == "down" {
            activateModifier(modifier)
        } else if action == "up" {
            deactivateModifier(modifier)
        }
    }
    
    private func activateNavKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔊 Activating nav key: \(key)")
            self.activeNavKeys.insert(key)
            
            // Cancel any existing timer for this key
            self.navKeyTimers[key]?.invalidate()
            
            // Set a timer to deactivate the key after a short duration
            self.navKeyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                print("🔊 Deactivating nav key: \(key)")
                self.activeNavKeys.remove(key)
                self.navKeyTimers.removeValue(forKey: key)
            }
        }
    }
    
    private func activateKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔊 ⌨️  Activating key: '\(key)' (active keys before: \(self.activeKeys.count))")
            self.activeKeys.insert(key)
            print("🔊 ✅ Key '\(key)' activated (active keys now: \(self.activeKeys.count))")
            print("🔊 📊 Current active keys: \(Array(self.activeKeys).sorted())")
            
            // Cancel any existing timer for this key
            self.keyTimers[key]?.invalidate()
            
            // Set a timer to deactivate the key after a short duration
            self.keyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                print("🔊 ⏰ Timer expired for key: '\(key)'")
                print("🔊 ⌨️  Deactivating key: '\(key)'")
                self.activeKeys.remove(key)
                self.keyTimers.removeValue(forKey: key)
                print("🔊 ❌ Key '\(key)' deactivated (active keys now: \(self.activeKeys.count))")
            }
        }
    }
    
    private func activateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔊 Activating modifier: \(modifier)")
            self.activeModifiers.insert(modifier)
            
            // Cancel any existing timer for this modifier
            self.modifierTimers[modifier]?.invalidate()
            
            // Set a longer timer for modifiers (they can be held longer)
            self.modifierTimers[modifier] = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                print("🔊 Auto-deactivating modifier: \(modifier)")
                self.activeModifiers.remove(modifier)
                self.modifierTimers.removeValue(forKey: modifier)
            }
        }
    }
    
    private func deactivateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔊 Deactivating modifier: \(modifier)")
            self.activeModifiers.remove(modifier)
            self.modifierTimers[modifier]?.invalidate()
            self.modifierTimers.removeValue(forKey: modifier)
        }
    }
    
    private func updateLayer(_ layer: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔊 UDP layer change: \(layer)")
            self.currentLayer = layer
        }
    }
    
    private func stopListening() {
        listener?.cancel()
        listener = nil
        
        // Cancel all timers
        keyTimers.values.forEach { $0.invalidate() }
        keyTimers.removeAll()
        
        navKeyTimers.values.forEach { $0.invalidate() }
        navKeyTimers.removeAll()
        
        modifierTimers.values.forEach { $0.invalidate() }
        modifierTimers.removeAll()
    }
    
    // MARK: - Public Interface
    
    func isNavKeyActive(_ physicalKey: String) -> Bool {
        return activeNavKeys.contains(physicalKey.lowercased())
    }
    
    func isKeyActive(_ physicalKey: String) -> Bool {
        let isActive = activeKeys.contains(physicalKey.lowercased())
        if isActive {
            print("🔊 🔍 UI Query: Key '\(physicalKey)' is ACTIVE via UDP")
        }
        return isActive
    }
    
    func isModifierActive(_ modifier: String) -> Bool {
        let isActive = activeModifiers.contains(modifier.lowercased())
        if isActive {
            print("🔊 🔍 UI Query: Modifier '\(modifier)' is ACTIVE via UDP")
        }
        return isActive
    }
    
    func getActiveNavKeys() -> Set<String> {
        return activeNavKeys
    }
    
    func getActiveKeys() -> Set<String> {
        return activeKeys
    }
    
    func getActiveModifiers() -> Set<String> {
        return activeModifiers
    }
} 