import AppKit

// MARK: - App Entry Point
 
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hide from Dock and Cmd+Tab
app.run() 