import Foundation
import SwiftUI
import CoreGraphics
import Cocoa

// MARK: - Global Key Monitor Service

class GlobalKeyMonitor: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published var activeKeys: Set<String> = []
    @Published var activeModifiers: Set<String> = []
    @Published var activeLayerKeys: Set<String> = []
    @Published var activeChords: Set<String> = []  // Track active chords like "f+d"
    
    // Internal state for key monitoring
    internal var systemModifierMap: [CGKeyCode: String] = [:]  // Maps system keycodes to physical keys
    internal var modifierInfoMap: [String: (type: String, flag: CGEventFlags)] = [:]  // Maps physical keys to modifier info
    
    // Chord detection
    internal var chordKeys: Set<String> = []
    internal var chordStartTime: Date?
    
    // Track unhandled keycodes for analysis
    internal var unhandledKeycodes: [Int: Int] = [:]  // keycode -> count
    internal var lastLogTime: Date = Date()
    
    // Dynamic mappings set from main view
    internal var modifierKeyMap: [String: (type: String, flag: CGEventFlags)] = [:]
    
    init() {
        setupEventTap()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Interface
    
    func updateModifierMap(_ modifierMap: [String: (type: String, flag: CGEventFlags)]) {
        modifierInfoMap = modifierMap
        systemModifierMap.removeAll()
        
        // Build reverse mapping from system keycodes to physical keys
        for (physicalKey, modifierInfo) in modifierMap {
            if let systemKeycode = getSystemKeycode(for: physicalKey) {
                systemModifierMap[systemKeycode] = physicalKey
                print("DEBUG: Mapped system keycode \(systemKeycode) to physical key '\(physicalKey)' (modifier: \(modifierInfo.type))")
            }
        }
        
        print("DEBUG: Updated modifier map with \(modifierMap.count) modifiers")
    }
    
    func updateSystemModifierMap(_ systemMap: [CGKeyCode: String]) {
        systemModifierMap = systemMap
        print("DEBUG: Updated system modifier map with \(systemMap.count) mappings")
    }
    
    func updateLayerKeyState(physicalKey: String, isActive: Bool, layerType: String) {
        DispatchQueue.main.async {
            if isActive {
                self.activeLayerKeys.insert(layerType)
                self.activeKeys.insert(physicalKey)
            } else {
                self.activeLayerKeys.remove(layerType)
                self.activeKeys.remove(physicalKey)
            }
        }
    }
    
    func forceLogSummary() {
        print("\n🔍 MANUAL KEYCODE SUMMARY REQUEST:")
        print("Summary logging functionality removed")
    }
    
    // MARK: - Private Implementation
    
    func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<GlobalKeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                let _ = monitor.handleEvent(type: type, event: event)
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("❌ Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("✅ Global key monitor started")
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        print("🛑 Global key monitor stopped")
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Handle special test commands
        if type == .keyDown {
            // Command+Q for quit
            if keyCode == 12 && flags.contains(.maskCommand) { // Q key
                print("🚪 Command+Q detected - quitting application")
                NSApplication.shared.terminate(nil)
                return Unmanaged.passUnretained(event)
            }
            
            // Command+W for quit (alternative)
            if keyCode == 13 && flags.contains(.maskCommand) { // W key
                print("🚪 Command+W detected - quitting application")
                NSApplication.shared.terminate(nil)
                return Unmanaged.passUnretained(event)
            }
        }
        
        // Special debug for ESC key
        if keyCode == 53 {
            print("🚨 ESC KEY DETECTED: keycode 53, type: \(type), flags: \(flags)")
            if let keyString = KeyCodeMapper.keyStringFromCode(CGKeyCode(keyCode)) {
                print("🚨 ESC KEY MAPPED TO: '\(keyString)'")
            } else {
                print("🚨 ESC KEY MAPPING FAILED!")
            }
        }
        
        // Handle modifier changes
        handleModifierChange(keyCode: CGKeyCode(keyCode), flags: flags)
        
        // Handle regular key events
        if let keyString = KeyCodeMapper.keyStringFromCode(CGKeyCode(keyCode)) {
            if type == .keyDown {
                print("DEBUG: Key down detected: '\(keyString)' (keycode: \(keyCode))")
                self.activeKeys.insert(keyString)
                self.handleChordDetection(keyString, isKeyDown: true)
            } else if type == .keyUp {
                print("DEBUG: Key up detected: '\(keyString)' (keycode: \(keyCode))")
                self.activeKeys.remove(keyString)
                self.handleChordDetection(keyString, isKeyDown: false)
            }
        } else {
            print("DEBUG: Unhandled keycode: \(keyCode)")
        }
        
        return Unmanaged.passUnretained(event)
    }
}
 