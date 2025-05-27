#!/usr/bin/env swift

import Foundation
import Network

print("🧪 Simple 'a' Key Test Monitor (TCP)")
print("=====================================")
print("Watching for: KEY_A, SHIFT_DOWN, SHIFT_UP")
print("Test: Tap 'a' (should see KEY_A), Hold 'a' (should see SHIFT_DOWN then SHIFT_UP)")

// Message counters
var keyACount = 0
var shiftDownCount = 0
var shiftUpCount = 0
var shiftActive = false

// Create TCP listener
let listener = try! NWListener(using: .tcp, on: 6789)

print("✅ Listening on TCP port 6789")
print("Press Ctrl+C to stop and see results")

listener.newConnectionHandler = { connection in
    connection.start(queue: .main)
    
    func receiveMessage() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                let timestamp = DateFormatter().apply {
                    $0.dateFormat = "HH:mm:ss.SSS"
                }.string(from: Date())
                
                switch message {
                case "KEY_A":
                    keyACount += 1
                    let status = shiftActive ? "ACTIVE" : "inactive"
                    let balance = shiftDownCount - shiftUpCount
                    print("[\(timestamp)] ⌨️  KEY_A (tap) - Count: \(keyACount)")
                    print("    Status: Shift \(status), Balance: \(balance) (downs: \(shiftDownCount), ups: \(shiftUpCount))")
                    
                case "SHIFT_DOWN":
                    if shiftActive {
                        print("[\(timestamp)] 🚨 SHIFT_DOWN but shift already active!")
                    } else {
                        print("[\(timestamp)] 🔽 SHIFT_DOWN (hold start) - Count: \(shiftDownCount + 1)")
                        shiftActive = true
                    }
                    shiftDownCount += 1
                    let balance = shiftDownCount - shiftUpCount
                    print("    Status: Shift ACTIVE, Balance: \(balance) (downs: \(shiftDownCount), ups: \(shiftUpCount))")
                    
                case "SHIFT_UP":
                    shiftUpCount += 1
                    shiftActive = false
                    let balance = shiftDownCount - shiftUpCount
                    print("[\(timestamp)] 🔼 SHIFT_UP (hold end) - Count: \(shiftUpCount)")
                    print("    Status: Shift inactive, Balance: \(balance) (downs: \(shiftDownCount), ups: \(shiftUpCount))")
                    
                default:
                    let status = shiftActive ? "ACTIVE" : "inactive"
                    let balance = shiftDownCount - shiftUpCount
                    print("[\(timestamp)] ❓ Unknown: \(message)")
                    print("    Status: Shift \(status), Balance: \(balance) (downs: \(shiftDownCount), ups: \(shiftUpCount))")
                }
            }
            
            if !isComplete {
                receiveMessage()
            }
        }
    }
    
    receiveMessage()
}

listener.start(queue: .main)

// Handle Ctrl+C gracefully
signal(SIGINT) { _ in
    print("\n\n📊 FINAL TEST RESULTS:")
    print("======================")
    print("KEY_A messages: \(keyACount)")
    print("SHIFT_DOWN messages: \(shiftDownCount)")
    print("SHIFT_UP messages: \(shiftUpCount)")
    print("Final balance: \(shiftDownCount - shiftUpCount) (downs: \(shiftDownCount), ups: \(shiftUpCount))")
    
    if shiftUpCount == 0 && shiftDownCount > 0 {
        print("❌ FAILED: No SHIFT_UP messages received!")
        print("🔍 This confirms the fork release action is not working.")
    } else if shiftDownCount == shiftUpCount {
        print("✅ PASSED: Balanced modifier state!")
    } else {
        print("⚠️  PARTIAL: Unbalanced modifier state")
    }
    
    exit(0)
}

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

RunLoop.main.run() 