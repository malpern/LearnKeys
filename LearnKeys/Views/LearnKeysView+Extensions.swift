import SwiftUI

extension LearnKeysView {
    
    func letterRow(letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat, 
                  smallFontSize: CGFloat, overlayFrameHeight: CGFloat) -> some View {
        let drawWidth: CGFloat = 160
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return HStack(spacing: slotSpacing) {
            ForEach(letters, id: \.self) { letter in
                ZStack {
                    GeometryReader { geo in
                        if !keyMonitor.activeKeys.contains(letter.lowercased()) {
                            Text(letter)
                                .font(.system(size: smallFontSize, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: slotWidth, height: overlayFrameHeight)
                                .position(x: drawWidth / 2, y: overlayFrameHeight / 2)
                                .transition(.scale)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: keyMonitor.activeKeys)
                        }
                    }
                    .frame(width: drawWidth, height: overlayFrameHeight)
                }
                .frame(width: slotWidth, height: overlayFrameHeight)
            }
        }
        .frame(width: totalWidth, height: overlayFrameHeight, alignment: .center)
    }
    
    func overlayAnimatedLetters(letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat,
                               largeFontSize: CGFloat, overlayScale: CGFloat, 
                               overlayFrameHeight: CGFloat, drawWidth: CGFloat) -> some View {
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let letter = pair.element
                let isActive = keyMonitor.activeKeys.contains(letter.lowercased())
                
                if isActive {
                    Text(letter)
                        .font(.system(size: largeFontSize, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(overlayScale)
                        .frame(width: drawWidth, height: overlayFrameHeight)
                        .position(x: CGFloat(index) * (slotWidth + slotSpacing) + slotWidth / 2,
                                  y: overlayFrameHeight / 2)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
                        .zIndex(2)
                }
            }
        }
        .frame(width: totalWidth, height: overlayFrameHeight)
    }
    
    func modifierOnlyRow() -> some View {
        VStack(spacing: 20) {
            alignedModifierRow()
            
            let additionalKeys = getNonHomeRowKeys().filter { key in
                !isKeyAlreadyShownInModifierRow(key.physicalKey)
            }
            
            if !additionalKeys.isEmpty {
                additionalKeysRow()
            } else {
                EmptyView()
                    .frame(height: 72)
            }
        }
    }
    
    func alignedModifierRow() -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        let modifierMappings: [String: String] = [
            "a": "shift", "s": "control", "d": "option", "f": "layer", "g": "command",
            "j": "rcommand", "k": "roption", "l": "rcontrol", ";": "rshift"
        ]
        
        return ZStack {
            // Background for modifier groups
            modifierBackground(letters: letters, modifierMappings: modifierMappings, 
                             slotWidth: slotWidth, slotSpacing: slotSpacing)
            
            // Position each modifier under its corresponding letter
            ForEach(letters, id: \.self) { letter in
                if let action = modifierMappings[letter.lowercased()],
                   let letterIndex = letters.firstIndex(of: letter.lowercased()) {
                    modifierKeyForAction(action, physicalKey: letter)
                        .position(
                            x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                            y: 50 // MOVED LOWER to match navigation layer visual height
                        )
                }
            }
        }
        .frame(width: totalWidth, height: 72)
    }
    
    func additionalKeysRow() -> some View {
        EmptyView()
            .frame(height: 72)
    }
    
    func nonTransparentKeysLayout() -> some View {
        let nonTransparentKeys = getNonTransparentKeys()
        
        if nonTransparentKeys.isEmpty {
            return AnyView(
                VStack(spacing: 20) {
                    EmptyView().frame(height: 72)
                    EmptyView().frame(height: 72)
                }
            )
        }
        
        return AnyView(
            VStack(spacing: 20) {
                let navigationKeys = nonTransparentKeys.filter { !isArrowKey($0.physicalKey) }
                if !navigationKeys.isEmpty {
                    navigationKeysSection(navigationKeys)
                } else {
                    EmptyView().frame(height: 72)
                }
                
                let arrowKeys = nonTransparentKeys.filter { isArrowKey($0.physicalKey) }
                if !arrowKeys.isEmpty {
                    arrowKeysSection(arrowKeys)
                } else {
                    EmptyView().frame(height: 72)
                }
            }
        )
    }
    
    func modifierBackground(letters: [String], modifierMappings: [String: String], 
                           slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        let modifierPositions = letters.enumerated().compactMap { index, letter -> Int? in
            modifierMappings[letter.lowercased()] != nil ? index : nil
        }
        
        let groups = groupConsecutivePositionsByHand(modifierPositions, letters: letters)
        let horizontalPadding: CGFloat = 45
        let backgroundHeight: CGFloat = 104
        
        return ZStack {
            ForEach(groups, id: \.self) { group in
                if !group.isEmpty {
                    let startPos = group.first!
                    let endPos = group.last!
                    
                    let startX = CGFloat(startPos) * (slotWidth + slotSpacing)
                    let endX = CGFloat(endPos) * (slotWidth + slotSpacing) + slotWidth
                    let minGroupWidth = slotWidth + 2 * horizontalPadding
                    let calculatedWidth = endX - startX + 2 * horizontalPadding
                    let groupWidth = max(minGroupWidth, calculatedWidth)
                    let centerX = (startX + endX) / 2
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1C1C1C"), Color(hex: "181818")]),
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "323232"), lineWidth: 1)
                        )
                        .frame(width: groupWidth, height: backgroundHeight)
                        .position(x: centerX, y: 50) // Match button positioning
                }
            }
        }
    }
    
    func modifierKeyForAction(_ action: String, physicalKey: String) -> some View {
        let isActive = keyMonitor.activeModifiers.contains(action.lowercased()) || 
                      keyMonitor.activeKeys.contains(physicalKey.lowercased())
        
        let (displayText, symbol): (String, String)
        switch action.lowercased() {
        case "shift", "rshift": (displayText, symbol) = ("shift", "⇧")
        case "control", "rcontrol": (displayText, symbol) = ("control", "⌃")
        case "option", "roption": (displayText, symbol) = ("option", "⌥")
        case "command", "rcommand": (displayText, symbol) = ("command", "⌘")
        case "layer": (displayText, symbol) = ("layer", "☰")
        default: (displayText, symbol) = (action.lowercased(), "◊")
        }
        
        return KeyCap(
            label: displayText,
            symbol: symbol,
            isArrow: false,
            isActive: isActive,
            arrowDirection: nil,
            temporaryState: nil
        )
    }
    
    func backgroundForActiveKeys(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)], 
                                letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        // Find positions of keys that actually have mappings, including keys not in home row
        let keyPositions = keys.compactMap { key -> Int? in
            if let homeRowIndex = letters.firstIndex(of: key.physicalKey.lowercased()) {
                return homeRowIndex
            } else {
                // For keys not in home row, find their closest position
                let closestPosition = findClosestHomeRowPosition(for: key.physicalKey)
                return letters.firstIndex(of: closestPosition)
            }
        }.sorted()
        
        // Group consecutive positions, separated by hand (based on actual key positions)
        let groups = groupConsecutivePositionsByHand(keyPositions, letters: letters)
        let horizontalPadding: CGFloat = 45 // Half of chromeless.swift's 90px total padding
        let keyHeight: CGFloat = 72
        let backgroundHeight: CGFloat = keyHeight + 32 // Match chromeless.swift padding
        
        return ZStack {
            ForEach(groups, id: \.self) { group in
                if !group.isEmpty { // Show background for any group (even single keys in nav layers)
                    let startPos = group.first!
                    let endPos = group.last!
                    
                    // Calculate actual positions with proper width for single keys
                    let startX = CGFloat(startPos) * (slotWidth + slotSpacing)
                    let endX = CGFloat(endPos) * (slotWidth + slotSpacing) + slotWidth
                    let minGroupWidth = slotWidth + 2 * horizontalPadding // Minimum width for single key
                    let calculatedWidth = endX - startX + 2 * horizontalPadding
                    let groupWidth = max(minGroupWidth, calculatedWidth)
                    let centerX = (startX + endX) / 2
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1C1C1C"), Color(hex: "181818")]),
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "323232"), lineWidth: 1)
                        )
                        .frame(width: groupWidth, height: backgroundHeight)
                        .position(x: centerX, y: 36) // Center on the key position
                }
            }
        }
    }
    
    func modifierStyleNavigationKey(physicalKey: String, layerKey: String, alias: KanataAlias?) -> some View {
        let isActive = keyMonitor.activeKeys.contains(physicalKey.lowercased())
        let resolvedAction = resolveKeyAction(layerKey: layerKey, alias: alias)
        
        // Extract alias name if this is an alias reference
        let aliasName: String? = layerKey.hasPrefix("@") ? String(layerKey.dropFirst()) : nil
        
        let (displayText, symbol) = getDisplayTextAndSymbol(for: resolvedAction, aliasName: aliasName)
        
        // Validate display text to prevent broken UI
        let (safeDisplayText, safeSymbol) = validateDisplayText(
            displayText: displayText, 
            symbol: symbol,
            physicalKey: physicalKey, 
            layerKey: layerKey, 
            alias: alias
        )
        
        return KeyCap(
            label: safeDisplayText,
            symbol: safeSymbol,
            isArrow: false,
            isActive: isActive,
            arrowDirection: nil,
            temporaryState: nil
        )
    }
    
    func groupConsecutivePositionsByHand(_ positions: [Int], letters: [String]) -> [[Int]] {
        guard !positions.isEmpty else { return [] }
        
        var groups: [[Int]] = []
        var currentGroup: [Int] = []
        var previousHand: String? = nil
        
        for position in positions {
            let currentHand = getHandForPosition(position, letters: letters)
            
            // Start new group if hand changes or position is not consecutive
            if let prevHand = previousHand, prevHand != currentHand {
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                    currentGroup = []
                }
            } else if let lastPos = currentGroup.last, position > lastPos + 1 {
                // Non-consecutive position, start new group
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                    currentGroup = []
                }
            }
            
            currentGroup.append(position)
            previousHand = currentHand
        }
        
        // Add the final group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    func getHandForPosition(_ position: Int, letters: [String]) -> String {
        // Split based on standard QWERTY hand positioning
        // Left hand: a(0), s(1), d(2), f(3), g(4)
        // Right hand: h(5), j(6), k(7), l(8), ;(9)
        return position < 5 ? "left" : "right"
    }
} 