import SwiftUI
import CoreGraphics

// MARK: - LearnKeysView Helper Methods

extension LearnKeysView {
    
    // MARK: - Key State Checking
    
    func isLetterActive(letter: String) -> Bool {
        // Find the corresponding physical key and layer key for this letter position
        guard let position = config.defsrc.firstIndex(of: letter) else { return false }
        guard position < currentLayerKeys.count else { return false }
        
        let layerKey = currentLayerKeys[position]
        let alias: KanataAlias? = layerKey.hasPrefix("@") ? 
            config.aliases[String(layerKey.dropFirst())] : nil
            
        return isKeyActive(physicalKey: letter, layerKey: layerKey, alias: alias)
    }
    
    func isKeyActive(physicalKey: String, layerKey: String, alias: KanataAlias?) -> Bool {
        // Check UDP tracker for any type of key activity first (most reliable for configured keys)
        if udpTracker.isKeyActive(physicalKey) {
            return true
        }
        
        // For navigation layers, check UDP nav key tracker (existing functionality)
        if tcpClient.currentLayer == "nomods" || tcpClient.currentLayer == "navfast" {
            if udpTracker.isNavKeyActive(physicalKey) {
                return true
            }
        }
        
        // Check UDP modifier tracking
        if udpTracker.isModifierActive(physicalKey) {
            return true
        }
        
        // For all layers, check for direct physical key press (fallback)
        if keyMonitor.activeKeys.contains(physicalKey.lowercased()) {
            return true
        }
        
        // For F-nav layer, check for simple arrow key outputs (J/K work fine)
        if tcpClient.currentLayer == "f-nav" {
            let resolvedAction = resolveKeyActionForDisplay(layerKey: layerKey, alias: alias)
            
            // Check for simple navigation actions that map directly
            switch resolvedAction.lowercased() {
            case "down", "pgdn":
                return keyMonitor.activeKeys.contains("pgdn")
            case "up", "pgup":
                return keyMonitor.activeKeys.contains("pgup")
            case "left":
                return keyMonitor.activeKeys.contains("left")
            case "right":
                return keyMonitor.activeKeys.contains("right")
            default:
                break
            }
        }
        
        return false
    }
    
    // MARK: - Key Data Retrieval
    
    func getNonTransparentKeys() -> [(physicalKey: String, layerKey: String, alias: KanataAlias?)] {
        var nonTransparentKeys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)] = []
        
        for (index, physicalKey) in config.defsrc.enumerated() {
            if index < currentLayerKeys.count {
                let layerKey = currentLayerKeys[index]
                
                // Skip transparent keys
                if isTransparentKey(layerKey: layerKey, physicalKey: physicalKey) {
                    continue
                }
                
                let alias: KanataAlias? = layerKey.hasPrefix("@") ? 
                    config.aliases[String(layerKey.dropFirst())] : nil
                    
                nonTransparentKeys.append((physicalKey: physicalKey, layerKey: layerKey, alias: alias))
            }
        }
        
        return nonTransparentKeys
    }
    
    func getNonHomeRowKeys() -> [(physicalKey: String, layerKey: String, alias: KanataAlias?)] {
        let homeRowKeys = Set(["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"])
        return getNonTransparentKeys().filter { !homeRowKeys.contains($0.physicalKey.lowercased()) }
    }
    
    func isTransparentKey(layerKey: String, physicalKey: String) -> Bool {
        return layerKey == "_" || 
               layerKey.isEmpty || 
               layerKey == physicalKey
    }
    
    func isArrowKey(_ key: String) -> Bool {
        return ["left", "right", "up", "down"].contains(key.lowercased())
    }
    
    func isKeyAlreadyShownInModifierRow(_ physicalKey: String) -> Bool {
        // Check if this key is already shown in alignedModifierRow
        let homeRowKeys = Set(["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"])
        
        // Home row keys with modifiers
        if homeRowKeys.contains(physicalKey.lowercased()) {
            return true
        }
        
        // Space key is now handled in the second row (additionalKeysRow), not in alignedModifierRow
        // So we return false to allow it to be shown in the second row
        if physicalKey.lowercased() == "spc" {
            return false
        }
        
        return false
    }
    
    // MARK: - Layout Helper Methods
    
    func navigationKeysSection(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
        // Position buttons directly under corresponding letters
        alignedNavigationButtons(keys)
    }
    
    func arrowKeysSection(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
        // Position arrow keys directly under corresponding letters
        alignedNavigationButtons(keys)
    }
    
    func alignedNavigationButtons(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            // Background for active keys only
            backgroundForActiveKeys(keys, letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing)
            
            // Position each navigation key under its corresponding letter or closest position
            ForEach(keys, id: \.physicalKey) { key in
                let closestPosition = findClosestHomeRowPosition(for: key.physicalKey)
                if let letterIndex = letters.firstIndex(of: closestPosition) {
                    modifierStyleNavigationKey(physicalKey: key.physicalKey, layerKey: key.layerKey, alias: key.alias)
                        .position(
                            x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                            y: 36 // Half height of the key - same as base layer modifiers
                        )
                }
            }
        }
        .frame(width: totalWidth, height: {
            // Use the same dynamic height calculation as base layer modifiers
            let height: CGFloat = 72 // Base height
            // Check if any keys would be positioned outside the base height
            // This matches the logic from alignedModifierRow
            return height
        }())
    }
    
    // MARK: - Display Text Processing
    
    func resolveKeyActionForDisplay(layerKey: String, alias: KanataAlias?) -> String {
        if layerKey.hasPrefix("@") {
            let aliasName = String(layerKey.dropFirst())
            if let alias = alias {
                // For tap-hold keys, prefer the tap action for display
                if alias.definition.contains("tap-hold") {
                    return alias.tapAction ?? alias.definition
                } else {
                    return alias.definition
                }
            } else {
                // Fallback patterns for missing aliases
                switch aliasName {
                // Basic f-nav layer
                case "fnav_h": return "left"
                case "fnav_j": return "down"
                case "fnav_k": return "up"
                case "fnav_l": return "right"
                case "fnav_b": return "a-left"
                case "fnav_w": return "a-right"
                case "fnav_u": return "homerow"
                
                // Fast navigation layer (navfast - F+D chord)
                case "fast_h": return "m-left"
                case "fast_j": return "pgdn"
                case "fast_k": return "pgup"
                case "fast_l": return "m-right"
                case "fast_w": return "a-right"
                case "fast_b": return "a-left"
                case "fast_u": return "homerow"
                
                default: return layerKey
                }
            }
        } else {
            return layerKey
        }
    }
    
    func getDisplayTextAndSymbol(for action: String, aliasName: String? = nil) -> (String, String) {
        // First check if we have a display mapping for the alias name (if provided)
        if let aliasName = aliasName,
           let displayMapping = config.displayMappings[aliasName.lowercased()] {
            return (displayMapping.displayText, displayMapping.symbol)
        }
        
        // Then check if we have a dynamic display mapping from the config for the action
        if let displayMapping = config.displayMappings[action.lowercased()] {
            return (displayMapping.displayText, displayMapping.symbol)
        }
        
        // Enhanced handling for specific alias patterns in F and D&F layers
        if let aliasName = aliasName {
            switch aliasName.lowercased() {
            // F layer (fnav) aliases
            case "fnav_h": return ("left", "←")
            case "fnav_j": return ("down", "↓")
            case "fnav_k": return ("up", "↑")
            case "fnav_l": return ("right", "→")
            case "fnav_b": return ("word left", "⇠")
            case "fnav_w": return ("word right", "⇢")
            case "fnav_u": return ("home row", "⌂")
            
            // D&F layer (fast/navfast) aliases - fixed H and L
            case "fast_h": return ("line start", "⇤")  // Fixed: should be line start, not just "H"
            case "fast_j": return ("page down", "⇟")
            case "fast_k": return ("page up", "⇞")
            case "fast_l": return ("line end", "⇥")    // Fixed: should be line end, not just "L"
            case "fast_w": return ("word right", "⇢")
            case "fast_b": return ("word left", "⇠")
            case "fast_u": return ("home row", "⌂")
            
            default:
                break // Continue to general mapping
            }
        }
        
        // Enhanced mapping for navigation keys
        switch action.lowercased() {
        // Navigation keys
        case "left": return ("left", "←")
        case "right": return ("right", "→")
        case "up": return ("up", "↑")
        case "down": return ("down", "↓")
        case "pgup": return ("page up", "⇞")
        case "pgdn": return ("page down", "⇟")
        case "esc", "escape": return ("escape", "⎋")
        case "spc": return ("space", "⎵")
        
        // Word/line navigation - fixed for H and L keys in D&F layer
        case "a-left": return ("word left", "⇠")
        case "a-right": return ("word right", "⇢")
        case "m-left": return ("line start", "⇤")
        case "m-right": return ("line end", "⇥")
        
        // Letters (tap actions from home row)
        case "a": return ("A", "🅰")
        case "s": return ("S", "🅂")
        case "d": return ("D", "🄳")
        case "f": return ("F", "🄵")
        case "g": return ("G", "🄶")
        case "h": return ("H", "🄷")
        case "j": return ("J", "🄹")
        case "k": return ("K", "🄺")
        case "l": return ("L", "🄻")
        case ";": return (";", "⁏")
        
        // Numbers
        case "1": return ("1", "①")
        case "2": return ("2", "②")
        case "3": return ("3", "③")
        case "4": return ("4", "④")
        case "5": return ("5", "⑤")
        case "6": return ("6", "⑥")
        case "7": return ("7", "⑦")
        case "8": return ("8", "⑧")
        case "9": return ("9", "⑨")
        case "0": return ("0", "⓪")
        
        // Other common keys
        case "z": return ("Z", "🅉")
        case "x": return ("X", "🅇")
        case "c": return ("C", "🄲")
        case "v": return ("V", "🅅")
        case "b": return ("B", "🄱")
        case "n": return ("N", "🄽")
        case "m": return ("M", "🄼")
        case "q": return ("Q", "🅀")
        case "w": return ("W", "🅆")
        case "e": return ("E", "🄴")
        case "r": return ("R", "🅁")
        case "t": return ("T", "🅃")
        case "y": return ("Y", "🅈")
        case "u": return ("U", "🅄")
        case "i": return ("I", "🄸")
        case "o": return ("O", "🄾")
        case "p": return ("P", "🄿")
        
        // Punctuation
        case ",": return (",", "‚")
        case ".": return (".", "․")
        case "/": return ("/", "⁄")
        case "'": return ("'", "′")
        case "\"": return ("\"", "″")
        case "-": return ("-", "−")
        case "=": return ("=", "＝")
        case "[": return ("[", "⁅")
        case "]": return ("]", "⁆")
        case "\\": return ("\\", "⧵")
        case "`": return ("`", "‵")
        
        default: return (action.uppercased(), "◉")
        }
    }
    
    func validateDisplayText(displayText: String, symbol: String, physicalKey: String, layerKey: String, alias: KanataAlias?) -> (String, String) {
        // Check for problematic display text that indicates parsing failure
        if displayText.contains("(") || displayText.contains("tap-hold") || displayText.contains("multi") {
            print("⚠️  Display validation failed for key '\(physicalKey)': showing raw definition '\(displayText)'")
            
            // Try to extract a sensible fallback
            if let alias = alias, let tapAction = alias.tapAction {
                print("✅ Using tap action '\(tapAction)' as fallback")
                return (tapAction.uppercased(), "⚠️")
            } else {
                print("❌ No fallback available, using physical key with error symbol")
                return (physicalKey.uppercased(), "❌")
            }
        }
        
        // Check for empty or nil display text
        if displayText.isEmpty || displayText == "nil" {
            print("⚠️  Empty display text for key '\(physicalKey)', using physical key")
            return (physicalKey.uppercased(), "❓")
        }
        
        // Check for overly long display text (likely unparsed definition)
        if displayText.count > 15 {
            print("⚠️  Display text too long for key '\(physicalKey)': '\(displayText)'")
            if let alias = alias, let tapAction = alias.tapAction, tapAction.count <= 15 {
                return (tapAction.uppercased(), "⚠️")
            } else {
                return (physicalKey.uppercased(), "❌")
            }
        }
        
        return (displayText, symbol)
    }
    
    // MARK: - Position Finding
    
    func findClosestHomeRowPosition(for key: String) -> String {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        
        // Comprehensive mapping of all keyboard keys to closest home row key
        // Based on standard QWERTY layout physical proximity
        let keyMapping: [String: String] = [
            // Home row (direct mapping)
            "a": "a", "s": "s", "d": "d", "f": "f", "g": "g",
            "h": "h", "j": "j", "k": "k", "l": "l", ";": ";",
            
            // Number row (map to home row based on column alignment)
            "`": "a", "1": "a", "2": "s", "3": "d", "4": "f", "5": "g",
            "6": "h", "7": "j", "8": "k", "9": "l", "0": ";", "-": ";", "=": ";",
            
            // QWERTY row (map to home row based on column alignment)
            "q": "a", "w": "s", "e": "d", "r": "f", "t": "g",
            "y": "h", "u": "j", "i": "k", "o": "l", "p": ";", "[": ";", "]": ";", "\\": ";",
            
            // ZXCV row (map to home row based on column alignment)
            "z": "a", "x": "s", "c": "d", "v": "f", "b": "g",
            "n": "h", "m": "j", ",": "k", ".": "l", "/": ";",
            
            // Navigation keys (clustered on right side)
            "left": "j", "right": "l", "up": "k", "down": "k",
            "home": "j", "end": "l", "pgup": "k", "pgdn": "k",
            
            // Special keys
            "spc": "g", "space": "g",
            "enter": "l", "return": "l", "ret": "l",
            "tab": "a", "caps": "a", "capslock": "a",
            "esc": "a", "escape": "a",
            "backspace": ";", "bspc": ";"
        ]
        
        // First try direct mapping
        if let mapped = keyMapping[key.lowercased()] {
            return mapped
        }
        
        // Fallback: try to find the key in defsrc and map to closest home row position
        guard let keyIndex = config.defsrc.firstIndex(of: key.lowercased()) else {
            // Final fallback: return middle position
            return letters[letters.count / 2]
        }
        
        // Find the closest home row position based on defsrc index
        var closestIndex = 0
        var minDistance = abs(keyIndex - 0)
        
        for (index, homeRowKey) in letters.enumerated() {
            if let homeRowSrcIndex = config.defsrc.firstIndex(of: homeRowKey) {
                let distance = abs(keyIndex - homeRowSrcIndex)
                if distance < minDistance {
                    minDistance = distance
                    closestIndex = index
                }
            }
        }
        
        return letters[closestIndex]
    }
    
    // MARK: - Modifier Mapping
    
    func updateModifierMapping() {
        var modifierMap: [String: (type: String, flag: CGEventFlags)] = [:]
        var systemModifierMap: [CGKeyCode: String] = [:]
        
        // Get base layer mappings
        guard let baseLayer = config.layers["base"] else { return }
        
        for (index, physicalKey) in config.defsrc.enumerated() {
            if index < baseLayer.count {
                let layerKey = baseLayer[index]
                
                // Check if this is an alias with modifier hold behavior
                if layerKey.hasPrefix("@") {
                    let aliasName = String(layerKey.dropFirst())
                    if let alias = config.aliases[aliasName] {
                        if let holdAction = alias.holdAction {
                            print("DEBUG: Processing alias '\(aliasName)' for key '\(physicalKey)' with holdAction: '\(holdAction)'")
                            let modifierInfo = getModifierTypeAndFlag(for: holdAction, config: config)
                            if let info = modifierInfo {
                                modifierMap[physicalKey] = info
                                
                                // Build reverse mapping: system keycode -> physical key
                                if let systemKeyCode = getSystemKeyCodeForModifier(info.type, physicalKey: physicalKey) {
                                    systemModifierMap[systemKeyCode] = physicalKey
                                    print("DEBUG: ✅ System keycode mapping - keycode \(systemKeyCode) -> physical key '\(physicalKey)' for modifier '\(info.type)'")
                                } else {
                                    print("DEBUG: ❌ Failed to get system keycode for modifier '\(info.type)' and physical key '\(physicalKey)'")
                                }
                                
                                print("DEBUG: ✅ Modifier mapping - \(physicalKey) -> \(info.type)")
                            } else {
                            print("❌ Failed to get modifier info for holdAction: '\(holdAction)' in alias '\(aliasName)'")
                            print("   This hold action is not supported for UI display")
                            }
                        }
                    }
                }
            }
        }
        
        // Update the key monitor with both mappings
        keyMonitor.updateModifierMap(modifierMap)
        keyMonitor.updateSystemModifierMap(systemModifierMap)
    }
    
    func getSystemKeyCodeForModifier(_ modifierType: String, physicalKey: String) -> CGKeyCode? {
        // Map modifier types to their system keycodes, considering left/right variants
        switch modifierType.lowercased() {
        case "shift":
            // Determine if this should be left or right shift based on physical key position
            return isLeftHandKey(physicalKey) ? 56 : 60  // 56=left shift, 60=right shift
        case "control":
            return isLeftHandKey(physicalKey) ? 59 : 62  // 59=left control, 62=right control
        case "option":
            return isLeftHandKey(physicalKey) ? 58 : 61  // 58=left option, 61=right option
        case "command":
            return isLeftHandKey(physicalKey) ? 55 : 54  // 55=left command, 54=right command
        case "rshift":
            return 60  // right shift
        case "rcontrol":
            return 62  // right control
        case "roption":
            return 61  // right option
        case "rcommand":
            return 54  // right command
        default:
            return nil
        }
    }
    
    func isLeftHandKey(_ key: String) -> Bool {
        // Home row keys: left hand is a,s,d,f,g and right hand is h,j,k,l,;
        let leftHandKeys = Set(["a", "s", "d", "f", "g", "q", "w", "e", "r", "t", "z", "x", "c", "v", "b"])
        return leftHandKeys.contains(key.lowercased())
    }
    
    func getModifierTypeAndFlag(for holdAction: String, config: KanataConfig) -> (type: String, flag: CGEventFlags)? {
        print("DEBUG: getModifierTypeAndFlag called with holdAction: '\(holdAction)'")
        
        // Check if this is a built-in kanata modifier first (before trying alias resolution)
        let cleanAction = holdAction.hasPrefix("@") ? String(holdAction.dropFirst()) : holdAction
        print("DEBUG: Clean action after removing '@': '\(cleanAction)'")
        
        switch cleanAction.lowercased() {
        case "shift", "lsft":
            return ("shift", .maskShift)
        case "control", "lctl":
            return ("control", .maskControl)
        case "option", "lalt":
            return ("option", .maskAlternate)
        case "command", "lmet":
            return ("command", .maskCommand)
        case "rshift", "rsft":
            print("DEBUG: ✅ Detected right shift modifier")
            return ("rshift", .maskShift)
        case "rcontrol", "rctl":
            print("DEBUG: ✅ Detected right control modifier")
            return ("rcontrol", .maskControl)
        case "roption", "ralt":
            print("DEBUG: ✅ Detected right option modifier")
            return ("roption", .maskAlternate)
        case "rcommand", "rmet":
            print("DEBUG: ✅ Detected right command modifier")
            return ("rcommand", .maskCommand)
        default:
            break // Continue to alias resolution
        }
        
        // Check if this is a layer action
        if holdAction.contains("layer") {
            return ("layer", CGEventFlags(rawValue: 0)) // Special flag for layer keys
        }
        
        return nil
    }
} 