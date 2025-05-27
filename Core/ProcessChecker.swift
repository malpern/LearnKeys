import Foundation

enum ProcessCheckError: Error, LocalizedError {
    case processIsRunning(String)

    var errorDescription: String? {
        switch self {
        case .processIsRunning(let processName):
            return "❌ CRITICAL ERROR: Required process '\(processName)' is already running. Please quit it and try again."
        }
    }
}

class ProcessChecker {

    static func isProcessRunning(named processName: String) -> Bool {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", processName] // -x for exact match
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0 // pgrep exits with 0 if process is found
        } catch {
            print("⚠️ Error running pgrep for \(processName): \(error)")
            return false // Assume not running on error
        }
    }

    static func checkForConflictingProcesses() throws {
        let kanataProcessName = "kanata"
        let karabinerConsoleUserServer = "karabiner_console_user_server" // Main process for Karabiner-Elements

        if isProcessRunning(named: kanataProcessName) {
            LogManager.shared.log("WARNING: Another instance of 'kanata' is already running. This may cause conflicts, but the app will continue.")
            // Do not throw or exit
        }

        if isProcessRunning(named: karabinerConsoleUserServer) {
            LogManager.shared.logError("CRITICAL ERROR: '\(karabinerConsoleUserServer)' (Karabiner-Elements) is running. Please quit Karabiner-Elements and try again.")
            throw ProcessCheckError.processIsRunning(karabinerConsoleUserServer)
        }
        
        LogManager.shared.logInit("✅ No conflicting Kanata or Karabiner-Elements processes found.")
    }
} 