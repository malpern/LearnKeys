import SwiftUI
import AppKit

// MARK: - Window Class with Command+Q Support

class QuitOnCommandWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Command+Q or Command+W to quit
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "q" || event.charactersIgnoringModifiers == "w" {
                print("DEBUG: 🚪 Command+\(event.charactersIgnoringModifiers?.uppercased() ?? "") detected - quitting app")
                NSApp.terminate(nil)
                return
            }
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        performDrag(with: event)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up menu bar for Command+Q to work
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(withTitle: "Close Window", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "w")
        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
        
        // Check for command line arguments
        let arguments = CommandLine.arguments
        guard arguments.count > 1 else {
            print("Error: No config file provided")
            print("Usage: swift learnkeys.swift <config-file.kbd>")
            NSApp.terminate(nil)
            return
        }
        
        let configPath = arguments[1]
        guard FileManager.default.fileExists(atPath: configPath) else {
            print("Error: Config file '\(configPath)' not found")
            NSApp.terminate(nil)
            return
        }
        
        // Position on second monitor like chromeless.swift
        let screens = NSScreen.screens
        let targetScreen = screens.count > 1 ? screens[1] : screens[0] // Use secondary if available, else main
        let contentRect = targetScreen.frame
        
        let contentView = LearnKeysView(configPath: configPath)
        
        window = QuitOnCommandWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window)
    }
} 