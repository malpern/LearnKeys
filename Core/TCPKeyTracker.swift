import Foundation
import Network

class TCPKeyTracker: ObservableObject {
    @Published var activeNavKeys: Set<String> = []
    @Published var activeKeys: Set<String> = []  // Track all key presses
    @Published var activeModifiers: Set<String> = []  // Track modifiers
    @Published var currentLayer: String = "base"  // Track layer changes via TCP
    @Published var isKanataActive: Bool = false // Tracks if Kanata has sent a message recently
    @Published var didFailToStartListening: Bool = false // Tracks if the TCP listener failed to start
    
    // Callbacks for the AnimationController
    var onKeyPress: ((String) -> Void)?
    var onModifierChange: ((String, Bool) -> Void)?
    var onLayerChange: ((String) -> Void)?
    var onNavigationKey: ((String) -> Void)?
    
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 6790  // TCP port 6790 to match Kanata config
    private let queue = DispatchQueue(label: "tcp-key-tracker")
    private var keyTimers: [String: Timer] = [:]
    private var navKeyTimers: [String: Timer] = [:]
    private var modifierTimers: [String: Timer] = [:]
    private var activeConnections: [NWConnection] = []
    
    // Heartbeat system to detect stuck modifiers
    private var modifierHeartbeats: [String: Date] = [:]
    private var heartbeatTimer: Timer?
    private var kanataActivityTimer: Timer?
    
    init() {
        setupTCPListener()
        startHeartbeatMonitoring()
    }
    
    deinit {
        stopListening()
        heartbeatTimer?.invalidate()
        kanataActivityTimer?.invalidate()
    }
    
    private func setupTCPListener() {
        do {
            listener = try NWListener(using: .tcp, on: port)  // TCP instead of UDP
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("🔗 TCP KeyTracker ready on port 6790")
                    print("🔗 Listening for: navkey:*, keypress:*, modifier:*, layer:*")
                case .failed(let error):
                    print("🔗 TCP KeyTracker failed: \(error)")
                    // Signal that the listener failed to start
                    DispatchQueue.main.async {
                        self?.didFailToStartListening = true
                    }
                default:
                    break
                }
            }
            
            listener?.start(queue: queue)
            
        } catch {
            print("🔗 TCP KeyTracker setup failed: \(error)")
            // Signal that the listener failed to start due to an exception
            DispatchQueue.main.async {
                self.didFailToStartListening = true
            }
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        print("🔗 New TCP connection established")
        
        // Add to active connections
        activeConnections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("🔗 TCP connection ready")
            case .cancelled, .failed:
                print("🔗 TCP connection closed")
                self?.activeConnections.removeAll { $0 === connection }
            default:
                break
            }
        }
        
        connection.start(queue: queue)
        
        func receiveMessage() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] (data, context, isComplete, error) in
                if let error = error {
                    print("🔗 TCP receive error: \(error)")
                    return
                }
                
                if let data = data, !data.isEmpty {
                    if let message = String(data: data, encoding: .utf8) {
                        // TCP can receive multiple messages in one packet, split by newlines
                        let messages = message.components(separatedBy: .newlines)
                        for msg in messages {
                            let trimmed = msg.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                self?.processMessage(trimmed)
                            }
                        }
                    }
                }
                
                if !isComplete {
                    receiveMessage()
                } else {
                    self?.activeConnections.removeAll { $0 === connection }
                }
            }
        }
        
        receiveMessage()
    }
    
    func processMessage(_ message: String) {
        print("🔗 TCP received: '\(message)'")
        updateKanataActivity() // Mark Kanata as active and reset timeout
        
        // Parse different message types
        if message.hasPrefix("navkey:") {
            print("🔗 📡 Parsed as navigation key message")
            parseNavKeyMessage(message)
        } else if message.hasPrefix("keypress:") {
            var key = String(message.dropFirst(9)) // Remove "keypress:" prefix
            print("🔗 ⌨️  Parsed as basic keypress: '\(key)'")

            // Normalize the key: if it ends with ":tap", remove that suffix
            // so that "a:tap" becomes "a" for animation and state tracking.
            if key.hasSuffix(":tap") {
                key = String(key.dropLast(":tap".count))
                print("🔗 ⌨️  Normalized key to: '\(key)' for animation")
            }

            activateKey(key)
            onKeyPress?(key)
        } else if message.hasPrefix("modifier:") {
            print("🔗 🎛️  Parsed as modifier message")
            parseModifierMessage(message)
        } else if message.hasPrefix("layer:") {
            print("🔗 🗂️  Parsed as layer message")
            parseLayerMessage(message)
        } else if message.hasPrefix("debug:") {
            print("🔗 🐛 Parsed as debug message")
            parseDebugMessage(message)
        } else if !message.isEmpty {
            print("🔗 ❓ TCP unknown message format: '\(message)'")
        } else {
            print("🔗 ⚠️  Received empty TCP message")
        }
    }
    
    private func parseModifierMessage(_ message: String) {
        let components = message.components(separatedBy: ":")
        guard components.count >= 3 else {
            print("🔗 ❌ TCP invalid modifier message format: '\(message)'")
            return
        }
        
        let modifier = components[1].lowercased()
        let action = components[2].lowercased()
        
        print("🔗 🎛️  Processing modifier: '\(modifier)' action: '\(action)'")
        
        if action == "down" {
            activateModifier(modifier)
            onModifierChange?(modifier, true)
        } else if action == "up" {
            deactivateModifier(modifier)
            onModifierChange?(modifier, false)
        } else {
            print("🔗 ❌ Unknown modifier action: '\(action)' for modifier: '\(modifier)'")
        }
    }
    
    private func parseNavKeyMessage(_ message: String) {
        let components = message.components(separatedBy: ":")
        
        if components.count == 2 {
            // Old format: navkey:h (just activate the key)
            let key = components[1].lowercased()
            print("🔗 📡 Processing navkey (old format): '\(key)'")
            activateNavKey(key)
            onNavigationKey?(key)
        } else if components.count >= 3 {
            // New format: navkey:h:down or navkey:h:up
            let key = components[1].lowercased()
            let action = components[2].lowercased()
            
            print("🔗 📡 Processing navkey: '\(key)' action: '\(action)'")
            
            if action == "down" {
                activateNavKey(key)
                onNavigationKey?(key)
            } else if action == "up" {
                deactivateNavKey(key)
            } else {
                print("🔗 ❌ Unknown navkey action: '\(action)' for key: '\(key)'")
            }
        } else {
            print("🔗 ❌ TCP INVALID navkey message format: '\(message)' - use 'navkey:key' or 'navkey:key:down/up'")
        }
    }
    
    private func parseLayerMessage(_ message: String) {
        let components = message.components(separatedBy: ":")
        
        if components.count == 2 {
            // Old format: layer:f-nav (just change layer)
            let layer = components[1]
            print("🔗 🗂️  Processing layer (old format): '\(layer)'")
            updateLayer(layer)
            onLayerChange?(layer)
        } else if components.count >= 3 {
            // New format: layer:f-nav:down or layer:f-nav:up
            let layer = components[1]
            let action = components[2].lowercased()
            
            print("🔗 🗂️  Processing layer: '\(layer)' action: '\(action)'")
            
            if action == "down" {
                updateLayer(layer)
                onLayerChange?(layer)
            } else if action == "up" {
                // For layer up, we might want to return to base layer
                updateLayer("base")
                onLayerChange?("base")
            } else {
                print("🔗 ❌ Unknown layer action: '\(action)' for layer: '\(layer)'")
            }
        } else {
            print("🔗 ❌ TCP INVALID layer message format: '\(message)' - use 'layer:name' or 'layer:name:down/up'")
        }
    }
    
    private func parseDebugMessage(_ message: String) {
        let components = message.components(separatedBy: ":")
        guard components.count >= 3 else {
            print("🔗 ❌ TCP invalid debug message format: '\(message)' - expected 'debug:key:action'")
            return
        }
        
        let key = components[1].lowercased()
        let action = components[2].lowercased()
        
        print("🔗 🐛 Processing debug: '\(key)' action: '\(action)'")
        
        if action == "down" {
            print("🔗 🐛 ✅ DEBUG KEY PRESS: '\(key)'")
            activateKey("debug-\(key)")
        } else if action == "up" {
            print("🔗 🐛 ❌ DEBUG KEY RELEASE: '\(key)'")
            // Debug releases are handled by timer, but we can log them
        } else {
            print("🔗 ❌ Unknown debug action: '\(action)' for key: '\(key)'")
        }
    }
    
    private func activateNavKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 📡 Activating nav key: \(key)")
            self.activeNavKeys.insert(key)
            
            // Cancel any existing timer for this key
            self.navKeyTimers[key]?.invalidate()
            
            // Set a timer to deactivate the key after a short duration (fallback)
            self.navKeyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                print("🔗 ⏰ Timer fallback: Deactivating nav key: \(key)")
                self.activeNavKeys.remove(key)
                self.navKeyTimers.removeValue(forKey: key)
            }
        }
    }
    
    private func deactivateNavKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 📡 Deactivating nav key: \(key)")
            self.activeNavKeys.remove(key)
            self.navKeyTimers[key]?.invalidate()
            self.navKeyTimers.removeValue(forKey: key)
        }
    }
    
    private func activateKey(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 ⌨️  Activating key: '\(key)' (active keys before: \(self.activeKeys.count))")
            self.activeKeys.insert(key)
            print("🔗 ✅ Key '\(key)' activated (active keys now: \(self.activeKeys.count))")
            print("🔗 📊 Current active keys: \(Array(self.activeKeys).sorted())")
            
            // Cancel any existing timer for this key
            self.keyTimers[key]?.invalidate()
            
            // Set a timer to deactivate the key after a short duration
            self.keyTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                print("🔗 ⏰ Timer expired for key: '\(key)'")
                print("🔗 ⌨️  Deactivating key: '\(key)'")
                self.activeKeys.remove(key)
                self.keyTimers.removeValue(forKey: key)
                print("🔗 ❌ Key '\(key)' deactivated (active keys now: \(self.activeKeys.count))")
            }
        }
    }
    
    private func activateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 🎛️  Activating modifier: \(modifier)")
            self.activeModifiers.insert(modifier)
            
            // Update heartbeat for this modifier
            self.modifierHeartbeats[modifier] = Date()
            
            // Cancel any existing timer for this modifier
            self.modifierTimers[modifier]?.invalidate()
            
            // Set a shorter safety timeout since Kanata fork bugs can cause missed releases
            // This is more aggressive to prevent stuck modifiers
            self.modifierTimers[modifier] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                print("🔗 ⚠️  Safety timeout: Auto-deactivating modifier '\(modifier)' after 3 seconds (likely missed release)")
                self.activeModifiers.remove(modifier)
                self.modifierTimers.removeValue(forKey: modifier)
                self.modifierHeartbeats.removeValue(forKey: modifier)
                
                // Notify the animation controller of the forced deactivation
                self.onModifierChange?(modifier, false)
            }
            
            print("🔗 ✅ Modifier '\(modifier)' activated (active modifiers: \(Array(self.activeModifiers).sorted()))")
        }
    }
    
    private func deactivateModifier(_ modifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 🎛️  Deactivating modifier: \(modifier)")
            self.activeModifiers.remove(modifier)
            self.modifierTimers[modifier]?.invalidate()
            self.modifierTimers.removeValue(forKey: modifier)
            self.modifierHeartbeats.removeValue(forKey: modifier)
            
            print("🔗 ❌ Modifier '\(modifier)' deactivated (active modifiers: \(Array(self.activeModifiers).sorted()))")
        }
    }
    
    private func updateLayer(_ layer: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🔗 TCP layer change: \(layer)")
            self.currentLayer = layer
        }
    }
    
    private func startHeartbeatMonitoring() {
        // Check for stuck modifiers every 500ms
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForStuckModifiers()
        }
    }
    
    private func checkForStuckModifiers() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            let stuckThreshold: TimeInterval = 2.0 // Consider stuck after 2 seconds without heartbeat
            
            for (modifier, lastHeartbeat) in self.modifierHeartbeats {
                if now.timeIntervalSince(lastHeartbeat) > stuckThreshold {
                    print("🔗 💔 Heartbeat timeout: Force-releasing stuck modifier '\(modifier)'")
                    self.deactivateModifier(modifier)
                    self.onModifierChange?(modifier, false)
                }
            }
        }
    }
    
    private func stopListening() {
        listener?.cancel()
        listener = nil
        
        // Stop heartbeat monitoring
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        // Close all active connections
        for connection in activeConnections {
            connection.cancel()
        }
        activeConnections.removeAll()
        
        // Cancel all timers
        keyTimers.values.forEach { $0.invalidate() }
        keyTimers.removeAll()
        
        navKeyTimers.values.forEach { $0.invalidate() }
        navKeyTimers.removeAll()
        
        modifierTimers.values.forEach { $0.invalidate() }
        modifierTimers.removeAll()
        
        // Clear heartbeat tracking
        modifierHeartbeats.removeAll()
    }
    
    private func updateKanataActivity() {
        DispatchQueue.main.async {
            if !self.isKanataActive {
                print("🔗 Kanata became active.")
            }
            self.isKanataActive = true
            self.kanataActivityTimer?.invalidate()
            self.kanataActivityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    if self?.isKanataActive == true { // Check if it was true before setting to false
                        print("🔗 Kanata activity timeout. Marking as inactive.")
                    }
                    self?.isKanataActive = false
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func debugModifierDown(_ modifier: String) {
        print("🔗 🐛 DEBUG: Manually triggering modifier down: \(modifier)")
        processMessage("modifier:\(modifier):down")
    }
    
    func debugModifierUp(_ modifier: String) {
        print("🔗 🐛 DEBUG: Manually triggering modifier up: \(modifier)")
        processMessage("modifier:\(modifier):up")
    }
    
    func debugClearAllModifiers() {
        print("🔗 🐛 DEBUG: Clearing all active modifiers")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for modifier in self.activeModifiers {
                print("🔗 🐛 DEBUG: Force clearing modifier: \(modifier)")
            }
            
            self.activeModifiers.removeAll()
            self.modifierTimers.values.forEach { $0.invalidate() }
            self.modifierTimers.removeAll()
            
            print("🔗 🐛 DEBUG: All modifiers cleared")
        }
    }
    
    // MARK: - Public Interface
    
    func isNavKeyActive(_ physicalKey: String) -> Bool {
        return activeNavKeys.contains(physicalKey.lowercased())
    }
    
    func isKeyActive(_ physicalKey: String) -> Bool {
        let isActive = activeKeys.contains(physicalKey.lowercased())
        if isActive {
            print("🔗 🔍 UI Query: Key '\(physicalKey)' is ACTIVE via TCP")
        }
        return isActive
    }
    
    func isModifierActive(_ modifier: String) -> Bool {
        let isActive = activeModifiers.contains(modifier.lowercased())
        if isActive {
            print("🔗 🔍 UI Query: Modifier '\(modifier)' is ACTIVE via TCP")
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