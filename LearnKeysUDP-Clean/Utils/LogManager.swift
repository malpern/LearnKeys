import Foundation
import os.log

/// Centralized logging system for LearnKeys UDP
/// Supports both console and file logging with configurable levels
class LogManager {
    static let shared = LogManager()
    
    private let logger = Logger(subsystem: "com.learnkeys.udp", category: "main")
    private let logQueue = DispatchQueue(label: "com.learnkeys.udp.logging", qos: .utility)
    private let logFileURL: URL
    
    // Configuration
    private let consoleLoggingEnabled: Bool
    private let fileLoggingEnabled: Bool
    
    private init() {
        // Configure logging based on environment variables
        self.consoleLoggingEnabled = ProcessInfo.processInfo.environment["LOG_CONSOLE"] != "false"
        self.fileLoggingEnabled = ProcessInfo.processInfo.environment["LOG_FILE"] != "false"
        
        // Setup log file path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = documentsPath.appendingPathComponent("LearnKeysUDP.log")
        
        // Create log file if it doesn't exist
        if fileLoggingEnabled && !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }
    
    /// Log a message with category and level
    func log(_ message: String, category: LogCategory = .general, level: LogLevel = .info) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(category.rawValue)] [\(level.rawValue)] \(message)"
        
        logQueue.async { [weak self] in
            // Console logging
            if self?.consoleLoggingEnabled == true {
                print(formattedMessage)
            }
            
            // File logging
            if self?.fileLoggingEnabled == true {
                self?.writeToFile(formattedMessage)
            }
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let data = (message + "\n").data(using: .utf8) else { return }
        
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    }
}

// MARK: - Log Categories
enum LogCategory: String, CaseIterable {
    case general = "GENERAL"
    case udp = "UDP"
    case key = "KEY"
    case nav = "NAV"
    case modifier = "MOD"
    case layer = "LAYER"
    case animation = "ANIM"
    case error = "ERROR"
    case initialization = "INIT"
}

// MARK: - Log Levels
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

// MARK: - Date Formatter Extension
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Convenience Methods
extension LogManager {
    func logUDP(_ message: String) {
        log(message, category: .udp)
    }
    
    func logKey(_ message: String) {
        log(message, category: .key)
    }
    
    func logNav(_ message: String) {
        log(message, category: .nav)
    }
    
    func logModifier(_ message: String) {
        log(message, category: .modifier)
    }
    
    func logLayer(_ message: String) {
        log(message, category: .layer)
    }
    
    func logAnimation(_ message: String) {
        log(message, category: .animation)
    }
    
    func logError(_ message: String) {
        log(message, category: .error, level: .error)
    }
    
    func logInit(_ message: String) {
        log(message, category: .initialization)
    }
}