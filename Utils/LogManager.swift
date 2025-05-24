import Foundation

/// Logging configuration and manager
class LogManager {
    static let shared = LogManager()
    
    private let fileLogger: FileHandle?
    private let logQueue = DispatchQueue(label: "LogManager", qos: .background)
    private let enableConsole: Bool
    private let enableFile: Bool
    
    init() {
        // Check for environment variables or default settings
        self.enableConsole = ProcessInfo.processInfo.environment["LOG_CONSOLE"] != "false"
        self.enableFile = ProcessInfo.processInfo.environment["LOG_FILE"] != "false"
        
        // Create log file in a more accessible location
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("LearnKeysUDP.log")
        
        if enableFile {
            // Create or append to log file
            if !FileManager.default.fileExists(atPath: logURL.path) {
                FileManager.default.createFile(atPath: logURL.path, contents: nil)
            }
            
            fileLogger = try? FileHandle(forWritingTo: logURL)
            fileLogger?.seekToEndOfFile()
            
            if fileLogger != nil {
                log("📝 Logging to: \(logURL.path)", category: "LOG")
            }
        } else {
            fileLogger = nil
        }
        
        // Log startup information
        log("🚀 LogManager initialized", category: "LOG")
        log("📊 Console logging: \(enableConsole ? "ON" : "OFF")", category: "LOG")
        log("📂 File logging: \(enableFile ? "ON" : "OFF")", category: "LOG")
    }
    
    func log(_ message: String, category: String = "UDP") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(category)] \(message)"
        
        logQueue.async {
            // Console logging
            if self.enableConsole {
                print(logEntry)
            }
            
            // File logging
            if let fileLogger = self.fileLogger {
                if let data = (logEntry + "\n").data(using: .utf8) {
                    fileLogger.write(data)
                }
            }
        }
    }
    
    // Get log file path for testing
    func getLogFilePath() -> String? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: documentsPath).appendingPathComponent("LearnKeysUDP.log").path
    }
    
    deinit {
        fileLogger?.closeFile()
    }
} 