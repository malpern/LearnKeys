#!/usr/bin/env swift

import Foundation

print("🧪 Simple 'a' Key Test Monitor (File-based)")
print("==========================================")
print("Watching for: KEY_A, SHIFT_DOWN, SHIFT_UP")
print("Test: Tap 'a' (should see KEY_A), Hold 'a' (should see SHIFT_DOWN then SHIFT_UP)")

// Message counters
var keyACount = 0
var shiftDownCount = 0
var shiftUpCount = 0
var shiftActive = false

let logFile = "/tmp/kanata_test.log"

// Clear the log file at start
try? FileManager.default.removeItem(atPath: logFile)

print("✅ Monitoring file: \(logFile)")
print("Press Ctrl+C to stop and see results")

// Track file position to only read new content
var lastFileSize: UInt64 = 0

func readNewLogEntries() {
    guard FileManager.default.fileExists(atPath: logFile) else { return }
    
    do {
        let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: logFile))
        defer { fileHandle.closeFile() }
        
        // Get current file size
        let currentSize = fileHandle.seekToEndOfFile()
        
        // If file grew, read new content
        if currentSize > lastFileSize {
            fileHandle.seek(toFileOffset: lastFileSize)
            let newData = fileHandle.readDataToEndOfFile()
            lastFileSize = currentSize
            
            if let newContent = String(data: newData, encoding: .utf8) {
                let lines = newContent.components(separatedBy: .newlines)
                for line in lines {
                    let message = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !message.isEmpty {
                        processMessage(message)
                    }
                }
            }
        }
    } catch {
        // File might not exist yet or be locked
    }
}

func processMessage(_ message: String) {
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
    
    // Show final log file content
    if FileManager.default.fileExists(atPath: logFile) {
        print("\n📄 Final log file content:")
        if let content = try? String(contentsOfFile: logFile) {
            print(content)
        }
    }
    
    exit(0)
}

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

// Monitor file changes every 100ms
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    readNewLogEntries()
}

RunLoop.main.run() 