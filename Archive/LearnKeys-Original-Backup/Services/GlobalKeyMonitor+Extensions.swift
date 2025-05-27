import Foundation
import CoreGraphics

// MARK: - GlobalKeyMonitor Extensions

extension GlobalKeyMonitor {
    
    // MARK: - Modifier Handling
    
    func handleModifierChange(keyCode: CGKeyCode, flags: CGEventFlags, eventType: CGEventType) {
        print("DEBUG: handleModifierChange keyCode: \(keyCode), flags: \(flags), eventType: \(eventType)")
        
        // For flagsChanged events, check all known modifier mappings
        if eventType == .flagsChanged {
            handleFlagsChangedEvent(flags: flags)
            return
        }
        
        // For keyDown/keyUp events, handle specific modifier keys
        if eventType == .keyDown || eventType == .keyUp {
            handleModifierKeyEvent(keyCode: keyCode, eventType: eventType)
        }
    }
    
    private func handleFlagsChangedEvent(flags: CGEventFlags) {
        print("DEBUG: Processing flagsChanged event with flags: \(flags)")
        
        // Check each modifier mapping to see if its state changed
        for (physicalKey, modifierInfo) in modifierInfoMap {
            let isCurrentlyActive = flags.contains(modifierInfo.flag)
            let wasActive = activeModifiers.contains(modifierInfo.type)
            
            if isCurrentlyActive != wasActive {
                print("DEBUG: Modifier '\(modifierInfo.type)' state changed: \(wasActive) -> \(isCurrentlyActive)")
                
                DispatchQueue.main.async {
                    if isCurrentlyActive {
                        self.activeModifiers.insert(modifierInfo.type)
                        self.activeKeys.insert(physicalKey)
                        print("DEBUG: ✅ Activated modifier '\(modifierInfo.type)' and key '\(physicalKey)'")
                    } else {
                        self.activeModifiers.remove(modifierInfo.type)
                        self.activeKeys.remove(physicalKey)
                        print("DEBUG: ❌ Deactivated modifier '\(modifierInfo.type)' and key '\(physicalKey)'")
                    }
                }
            }
        }
    }
    
    private func handleModifierKeyEvent(keyCode: CGKeyCode, eventType: CGEventType) {
        // Check if this is a system modifier keycode we care about (using dynamic mapping)
        if let physicalKey = systemModifierMap[keyCode] {
            print("DEBUG: Found physical key '\(physicalKey)' for system keycode \(keyCode)")
            
            // Check if this physical key has a modifier hold action in the config
            if let modifierInfo = getModifierInfoForKey(physicalKey) {
                let isKeyDown = (eventType == .keyDown)
                print("DEBUG: Modifier key '\(modifierInfo.type)' for key '\(physicalKey)' is \(isKeyDown ? "pressed" : "released")")
                
                DispatchQueue.main.async {
                    if isKeyDown {
                        self.activeModifiers.insert(modifierInfo.type)
                        self.activeKeys.insert(physicalKey)
                        print("DEBUG: ✅ Activated modifier '\(modifierInfo.type)' and key '\(physicalKey)' via keyDown")
                    } else {
                        self.activeModifiers.remove(modifierInfo.type)
                        self.activeKeys.remove(physicalKey)
                        print("DEBUG: ❌ Deactivated modifier '\(modifierInfo.type)' and key '\(physicalKey)' via keyUp")
                    }
                }
            } else {
                print("DEBUG: ❌ No modifier info found for physical key '\(physicalKey)'")
            }
        } else {
            print("DEBUG: ❌ No physical key mapping found for system keycode \(keyCode)")
            print("DEBUG: Available system modifier mappings: \(systemModifierMap)")
        }
    }
    
    private func getModifierInfoForKey(_ physicalKey: String) -> (type: String, flag: CGEventFlags)? {
        return modifierInfoMap[physicalKey]
    }
    
    // MARK: - Chord Detection
    
    func handleChordDetection(_ keyString: String, isKeyDown: Bool) {
        if isKeyDown {
            chordKeys.insert(keyString)
            chordStartTime = Date()
            
            // Check for F+D chord
            if chordKeys.contains("f") && chordKeys.contains("d") {
                activateChord("f+d")
            }
        } else {
            chordKeys.remove(keyString)
            
            // If F+D chord was active and one key is released, deactivate
            if activeChords.contains("f+d") && (!chordKeys.contains("f") || !chordKeys.contains("d")) {
                deactivateChord("f+d")
            }
            
            // If no keys held, reset chord detection
            if chordKeys.isEmpty {
                resetChordDetection()
            }
        }
    }
    
    private func activateChord(_ chord: String) {
        if !activeChords.contains(chord) {
            activeChords.insert(chord)
            print("DEBUG: 🎹 Chord activated: \(chord)")
            
            // Notify about chord activation for layer switching
            if chord == "f+d" {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChordActivated"),
                    object: ["chord": chord, "layer": "navfast"]
                )
            }
        }
    }
    
    private func deactivateChord(_ chord: String) {
        if activeChords.contains(chord) {
            activeChords.remove(chord)
            print("DEBUG: 🎹 Chord deactivated: \(chord)")
            
            // Notify about chord deactivation
            NotificationCenter.default.post(
                name: NSNotification.Name("ChordDeactivated"),
                object: ["chord": chord]
            )
        }
    }
    
    private func resetChordDetection() {
        chordKeys.removeAll()
        chordStartTime = nil
        
        // Deactivate all active chords
        for chord in activeChords {
            deactivateChord(chord)
        }
    }
    
    // MARK: - Keycode Mapping
    
    func getSystemKeycode(for physicalKey: String) -> CGKeyCode? {
        // Map physical key names to system keycodes
        let keycodeMap: [String: CGKeyCode] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "g": 5, "h": 4, "j": 38, "k": 40, "l": 37, ";": 41,
            "q": 12, "w": 13, "e": 14, "r": 15, "t": 17, "y": 16, "u": 32, "i": 34, "o": 31, "p": 35,
            "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "n": 45, "m": 46,
            "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
            "spc": 49, "ret": 36, "esc": 53, "tab": 48, "bspc": 51,
            "left": 123, "right": 124, "down": 125, "up": 126
        ]
        
        return keycodeMap[physicalKey]
    }
} 