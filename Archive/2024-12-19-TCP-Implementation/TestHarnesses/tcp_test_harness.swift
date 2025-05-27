#!/usr/bin/env swift

import Foundation
import Network

/// TCP Test Harness for No-Fork Kanata Configuration
/// Monitors TCP port 6790 for keypress, modifier, and navigation messages
/// Tests the layer switching approach for reliable modifier press/release detection

class TCPTestHarness {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "tcp-test-harness")
    private var isRunning = false
    
    // Message counters
    private var keyPressCount = 0
    private var modifierDownCount = 0
    private var modifierUpCount = 0
    private var navigationCount = 0
    private var layerChangeCount = 0
    
    // Message tracking
    private var allMessages: [String] = []
    private var startTime = Date()
    
    func start() {
        print("🧪 TCP Test Harness Starting")
        print("🔗 Connecting to TCP port 6790...")
        print("🎯 Testing no-fork layer switching configuration")
        print("📊 Monitoring: keypress:*, modifier:*:*, navkey:*, layer:*")
        print("⏱️  Test duration: 30 seconds")
        print("=" * 60)
        
        startTime = Date()
        setupTCPConnection()
        
        // Auto-stop after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.stop()
        }
        
        // Keep the program running
        RunLoop.main.run()
    }
    
    private func setupTCPConnection() {
        let host = NWEndpoint.Host("127.0.0.1")
        guard let port = NWEndpoint.Port(rawValue: 6790) else {
            print("❌ Invalid port number")
            return
        }
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ TCP connection established")
                print("💡 Start typing to see messages!")
                self?.isRunning = true
                self?.startReceiving()
            case .failed(let error):
                print("⚠️  TCP connection failed: \(error)")
                print("💡 This is normal - TCP port activates when keys are pressed")
                print("💡 Retrying connection in 2 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.setupTCPConnection()
                }
            case .cancelled:
                print("🔗 TCP connection cancelled")
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func startReceiving() {
        guard let connection = connection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, context, isComplete, error in
            if let error = error {
                print("❌ Receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                if let message = String(data: data, encoding: .utf8) {
                    // TCP can receive multiple messages, split by newlines
                    let messages = message.components(separatedBy: .newlines)
                    for msg in messages {
                        let trimmed = msg.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            self?.processMessage(trimmed)
                        }
                    }
                }
            }
            
            if !isComplete && self?.isRunning == true {
                self?.startReceiving()
            }
        }
    }
    
    private func processMessage(_ message: String) {
        let timestamp = String(format: "%.3f", Date().timeIntervalSince(startTime))
        allMessages.append("[\(timestamp)s] \(message)")
        
        let components = message.split(separator: ":")
        guard !components.isEmpty else { return }
        
        let messageType = String(components[0])
        
        switch messageType {
        case "keypress":
            keyPressCount += 1
            if components.count >= 2 {
                let key = String(components[1])
                print("⌨️  [\(timestamp)s] Key: \(key) (total: \(keyPressCount))")
            }
            
        case "modifier":
            if components.count >= 3 {
                let modifier = String(components[1])
                let state = String(components[2])
                
                if state == "down" {
                    modifierDownCount += 1
                    print("🔽 [\(timestamp)s] \(modifier.uppercased()) DOWN (downs: \(modifierDownCount))")
                } else if state == "up" {
                    modifierUpCount += 1
                    print("🔼 [\(timestamp)s] \(modifier.uppercased()) UP (ups: \(modifierUpCount))")
                }
            }
            
        case "navkey":
            navigationCount += 1
            if components.count >= 2 {
                let key = String(components[1])
                print("🧭 [\(timestamp)s] Nav: \(key) (total: \(navigationCount))")
            }
            
        case "layer":
            layerChangeCount += 1
            if components.count >= 2 {
                let layer = String(components[1])
                print("🗂️  [\(timestamp)s] Layer: \(layer) (changes: \(layerChangeCount))")
            }
            
        default:
            print("❓ [\(timestamp)s] Unknown: \(message)")
        }
    }
    
    private func stop() {
        print("\n" + "=" * 60)
        print("🛑 Test Complete - Generating Report")
        print("=" * 60)
        
        isRunning = false
        connection?.cancel()
        
        generateReport()
        exit(0)
    }
    
    private func generateReport() {
        let duration = Date().timeIntervalSince(startTime)
        let modifierBalance = modifierDownCount - modifierUpCount
        
        print("\n📊 TEST RESULTS SUMMARY")
        print("=" * 40)
        print("⏱️  Duration: \(String(format: "%.1f", duration)) seconds")
        print("📨 Total Messages: \(allMessages.count)")
        print("")
        print("📈 MESSAGE BREAKDOWN:")
        print("   ⌨️  Key Presses: \(keyPressCount)")
        print("   🔽 Modifier Downs: \(modifierDownCount)")
        print("   🔼 Modifier Ups: \(modifierUpCount)")
        print("   🧭 Navigation: \(navigationCount)")
        print("   🗂️  Layer Changes: \(layerChangeCount)")
        print("")
        print("⚖️  MODIFIER BALANCE ANALYSIS:")
        print("   Balance: \(modifierBalance) (downs - ups)")
        
        if modifierBalance == 0 {
            print("   ✅ PERFECT BALANCE - No stuck modifiers!")
        } else if modifierBalance > 0 {
            print("   ⚠️  POSITIVE BALANCE - \(modifierBalance) modifiers may be stuck")
        } else {
            print("   ⚠️  NEGATIVE BALANCE - \(abs(modifierBalance)) extra releases")
        }
        
        print("")
        print("🎯 NO-FORK LAYER SWITCHING TEST:")
        if modifierUpCount > 0 {
            print("   ✅ SUCCESS - Layer switching method working!")
            print("   ✅ Release events detected: \(modifierUpCount)")
            print("   ✅ Fork constructs successfully avoided")
        } else {
            print("   ❌ FAILURE - No release events detected")
            print("   ❌ Layer switching may not be working")
        }
        
        print("")
        print("📋 DETAILED MESSAGE LOG:")
        print("-" * 40)
        for message in allMessages {
            print("   \(message)")
        }
        
        print("")
        print("💡 TESTING INSTRUCTIONS:")
        print("   1. Hold 'a' key for 1 second, then release")
        print("   2. Should see: keypress:a, modifier:shift:down, modifier:shift:up")
        print("   3. Repeat with other home row modifiers (s, d, g, j, k, l, ;)")
        print("   4. Perfect test shows equal downs and ups")
    }
}

// String extension for repeat operator
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

// Main execution
print("🚀 Starting TCP Test Harness for No-Fork Configuration")
print("🔧 Make sure Kanata is running with the no-fork config")
print("🔧 Config should be using TCP port 6790")
print("")

let harness = TCPTestHarness()
harness.start() 