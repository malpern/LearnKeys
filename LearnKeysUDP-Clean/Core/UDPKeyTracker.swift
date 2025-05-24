import Foundation
import Network

/// Single source of truth - All key events come through UDP
class UDPKeyTracker: ObservableObject {
    @Published var activeKeys: Set<String> = []
    @Published var activeNavKeys: Set<String> = []
    @Published var activeModifiers: Set<String> = []
    @Published var currentLayer: String = "base"
    
    // Callbacks for the AnimationController
    var onKeyPress: ((String) -> Void)?
    var onModifierChange: ((String, Bool) -> Void)?
    var onLayerChange: ((String) -> Void)?
    var onNavigationKey: ((String) -> Void)?
    
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
    
    // MARK: - UDP Listener Setup
    
    private func setupUDPListener() {
        do {
            listener = try NWListener(using: .udp, on: port)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("🎯 UDP-First KeyTracker ready on port 6789")
                    print("🎯 Listening for: keypress:*, navkey:*, modifier:*, layer:*")
                case .failed(let error):
                    print("❌ UDP KeyTracker failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.start(queue: queue)
            
        } catch {
            print("❌ UDP KeyTracker setup failed: \(error)")
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
    
    // MARK: - Message Processing
    
    func processMessage(_ message: String) {
        print("🎯 UDP received: '\(message)'")
        
        let components = message.split(separator: ":")
        guard !components.isEmpty else {
            print("⚠️ Empty UDP message")
            return
        }
        
        let messageType = String(components[0])
        
        switch messageType {
        case "keypress":
            handleKeyPress(components)
        case "navkey":
            handleNavKey(components)
        case "modifier":
            handleModifier(components)
        case "layer":
            handleLayer(components)
        case "combo":
            handleCombo(components)
        default:
            print("❓ Unknown UDP message type: '\(messageType)'")
        }
    }
    
    private func handleKeyPress(_ components: [Substring]) {
        guard components.count >= 2 else { return }
        
        let key = String(components[1]).lowercased()
        print("⌨️ Key press: '\(key)'")
        
        activateKey(key)
        onKeyPress?(key)
    }
    
    private func handleNavKey(_ components: [Substring]) {
        guard components.count >= 2 else { return }
        
        let key = String(components[1]).lowercased()
        print("🧭 Navigation key: '\(key)'")
        
        activateNavKey(key)
        onNavigationKey?(key)
    }
    
    private func handleModifier(_ components: [Substring]) {
        guard components.count >= 3 else { return }
        
        let modifier = String(components[1]).lowercased()
        let state = String(components[2])
        let isActive = state == "down"
        
        print("🎛️ Modifier \(modifier): \(isActive ? "down" : "up")")
        
        if isActive {
            activateModifier(modifier)
        } else {
            deactivateModifier(modifier)
        }
        
        onModifierChange?(modifier, isActive)
    }
    
    private func handleLayer(_ components: [Substring]) {
        guard components.count >= 2 else { return }
        
        let layer = String(components[1])
        print("🗂️ Layer change: '\(layer)'")
        
        updateLayer(layer)
        onLayerChange?(layer)
    }
    
    private func handleCombo(_ components: [Substring]) {
        guard components.count >= 2 else { return }
        
        let keys = String(components[1]).split(separator: "+").map { String($0).lowercased() }
        print("🤝 Combo keys: \(keys)")
        
        // Activate all keys in the combo
        for key in keys {
            activateKey(key)
            onKeyPress?(key)
        }
    }
    
    // MARK: - Key State Management
    
    private func activateKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeKeys.insert(key)
            
            // Cancel existing timer
            self.keyTimers[key]?.invalidate()
            
            // Auto-deactivate after 300ms
            self.keyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                self.deactivateKey(key)
            }
        }
    }
    
    private func deactivateKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeKeys.remove(key)
            self.keyTimers[key]?.invalidate()
            self.keyTimers.removeValue(forKey: key)
        }
    }
    
    private func activateNavKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeNavKeys.insert(key)
            
            // Cancel existing timer
            self.navKeyTimers[key]?.invalidate()
            
            // Auto-deactivate after 200ms (faster for nav)
            self.navKeyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                self.deactivateNavKey(key)
            }
        }
    }
    
    private func deactivateNavKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeNavKeys.remove(key)
            self.navKeyTimers[key]?.invalidate()
            self.navKeyTimers.removeValue(forKey: key)
        }
    }
    
    private func activateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeModifiers.insert(modifier)
            
            // Cancel existing timer
            self.modifierTimers[modifier]?.invalidate()
            
            // Auto-deactivate after 2 seconds (modifiers can be held longer)
            self.modifierTimers[modifier] = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                self.deactivateModifier(modifier)
            }
        }
    }
    
    private func deactivateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activeModifiers.remove(modifier)
            self.modifierTimers[modifier]?.invalidate()
            self.modifierTimers.removeValue(forKey: modifier)
        }
    }
    
    private func updateLayer(_ layer: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
    
    func isKeyActive(_ key: String) -> Bool {
        return activeKeys.contains(key.lowercased())
    }
    
    func isNavKeyActive(_ key: String) -> Bool {
        return activeNavKeys.contains(key.lowercased())
    }
    
    func isModifierActive(_ modifier: String) -> Bool {
        return activeModifiers.contains(modifier.lowercased())
    }
} 