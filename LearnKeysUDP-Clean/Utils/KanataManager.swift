import Foundation
import AppKit
import Darwin

/// Monitors external Kanata process status (Kanata runs independently)
class KanataManager: ObservableObject {
    static let shared = KanataManager()
    
    @Published var isKanataRunning = false
    @Published var kanataStatus = "Not started"
    
    private var kanataProcess: Process?
    private var configPath: String?
    
    private init() {
        setupSignalHandling()
    }
    
    /// Start Kanata with the config.kbd file
    func startKanata() {
        guard !isKanataRunning else {
            LogManager.shared.log("⚠️ Kanata is already running")
            return
        }
        
        // Find config.kbd file
        guard let configPath = findConfigFile() else {
            LogManager.shared.log("❌ Could not find config.kbd file")
            kanataStatus = "Config file not found"
            return
        }
        
        self.configPath = configPath
        
        // Check if kanata binary exists
        guard FileManager.default.fileExists(atPath: "/usr/local/bin/kanata") else {
            LogManager.shared.log("❌ Kanata not found at /usr/local/bin/kanata")
            kanataStatus = "Kanata not installed"
            return
        }
        
        LogManager.shared.log("🚀 Starting Kanata with config: \(configPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/kanata")
        process.arguments = ["--cfg", configPath]
        
        // Set up output handling
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Monitor output for debugging
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                LogManager.shared.log("📟 Kanata: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                LogManager.shared.log("⚠️ Kanata error: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        // Set up termination handler
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.isKanataRunning = false
                self?.kanataStatus = "Stopped (exit code: \(process.terminationStatus))"
                LogManager.shared.log("🛑 Kanata process terminated with exit code: \(process.terminationStatus)")
            }
        }
        
        do {
            try process.run()
            kanataProcess = process
            
            DispatchQueue.main.async {
                self.isKanataRunning = true
                self.kanataStatus = "Running"
            }
            
            LogManager.shared.log("✅ Kanata started successfully (PID: \(process.processIdentifier))")
            
            // Give Kanata a moment to start up
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if process.isRunning {
                    LogManager.shared.log("🎯 Kanata is active and processing key events")
                    self.kanataStatus = "Active"
                }
            }
            
        } catch {
            LogManager.shared.log("❌ Failed to start Kanata: \(error.localizedDescription)")
            kanataStatus = "Failed to start: \(error.localizedDescription)"
        }
    }
    
    /// Stop the Kanata process
    func stopKanata() {
        guard let process = kanataProcess, process.isRunning else {
            LogManager.shared.log("⚠️ No Kanata process to stop")
            return
        }
        
        LogManager.shared.log("🛑 Stopping Kanata process...")
        
        // Try graceful termination first
        process.terminate()
        
        // Give it time to terminate gracefully
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if process.isRunning {
                LogManager.shared.log("⚠️ Kanata didn't terminate gracefully, force killing...")
                // Force kill using SIGKILL
                kill(process.processIdentifier, SIGKILL)
            }
        }
        
        kanataProcess = nil
        isKanataRunning = false
        kanataStatus = "Stopped"
    }
    
    /// Check if Kanata is currently running (any instance)
    func checkKanataStatus() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "kanata"]
        
        do {
            try task.run()
            task.waitUntilExit()
            let isRunning = task.terminationStatus == 0
            
            DispatchQueue.main.async {
                self.isKanataRunning = isRunning
                self.kanataStatus = isRunning ? "Running (external)" : "Not running"
            }
            
            return isRunning
        } catch {
            return false
        }
    }
    
    /// Find the config.kbd file
    private func findConfigFile() -> String? {
        let bundlePath = Bundle.main.bundlePath
        let bundleDir = URL(fileURLWithPath: bundlePath).deletingLastPathComponent()
        
        // Look for config.kbd in several locations
        let searchPaths = [
            // Test the simple config first
            FileManager.default.currentDirectoryPath + "/config-simple.kbd",
            FileManager.default.currentDirectoryPath + "/LearnKeysUDP-Clean/config-simple.kbd",
            // Current working directory first (most common during development)
            FileManager.default.currentDirectoryPath + "/config.kbd",
            // LearnKeysUDP-Clean directory relative to current working directory
            FileManager.default.currentDirectoryPath + "/LearnKeysUDP-Clean/config.kbd",
            // Same directory as the executable
            bundleDir.appendingPathComponent("config.kbd").path,
            // LearnKeysUDP-Clean directory relative to bundle
            bundleDir.appendingPathComponent("LearnKeysUDP-Clean/config.kbd").path,
            // Parent directory
            bundleDir.appendingPathComponent("../config.kbd").path,
            // Absolute path to the known location
            "/Users/malpern/Library/CloudStorage/Dropbox/code/LearnKeys/LearnKeysUDP-Clean/config.kbd",
        ]
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                LogManager.shared.log("📁 Found config.kbd at: \(path)")
                return path
            }
        }
        
        // Also check relative to the app bundle
        if let configPath = Bundle.main.path(forResource: "config", ofType: "kbd") {
            LogManager.shared.log("📁 Found config.kbd in app bundle: \(configPath)")
            return configPath
        }
        
        LogManager.shared.log("❌ config.kbd not found in any of these locations:")
        for path in searchPaths {
            LogManager.shared.log("   - \(path)")
        }
        
        return nil
    }
    
    /// Set up signal handling for clean app shutdown
    private func setupSignalHandling() {
        // Handle app termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            LogManager.shared.log("🚪 App terminating - Kanata runs independently")
        }
        
        // Handle signals for clean shutdown
        signal(SIGINT) { _ in
            LogManager.shared.log("🛑 Received SIGINT - shutting down LearnKeys")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            LogManager.shared.log("🛑 Received SIGTERM - shutting down LearnKeys")
            exit(0)
        }
    }
    
    deinit {
        // Kanata runs independently - no cleanup needed
    }
} 