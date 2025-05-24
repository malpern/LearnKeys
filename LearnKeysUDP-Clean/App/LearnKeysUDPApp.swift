import Foundation
import SwiftUI
import AppKit

// MARK: - Headless UDP Server for CI Testing

class HeadlessUDPServer {
    static let shared = HeadlessUDPServer()
    private var udpTracker: UDPKeyTracker?
    
    private init() {}
    
    func start() {
        LogManager.shared.logInit("🎯 LearnKeys UDP starting in HEADLESS mode for CI/testing")
        LogManager.shared.logInit("🎯 No GUI will be created - UDP server only")
        LogManager.shared.logInit("🎯 Starting headless UDP server...")
        LogManager.shared.logInit("🎯 UDP Port: 6789")
        LogManager.shared.logInit("🎯 Supported messages: keypress:*, navkey:*, modifier:*:*, layer:*")
        
        // Create headless UDP tracker
        udpTracker = UDPKeyTracker()
        
        // Set up logging callbacks for verification
        udpTracker?.onKeyPress = { key in
            LogManager.shared.log("✅ HEADLESS: Key press processed - \(key)")
        }
        
        udpTracker?.onNavigationKey = { key in
            LogManager.shared.log("✅ HEADLESS: Navigation key processed - \(key)")
        }
        
        udpTracker?.onModifierChange = { modifier, isActive in
            LogManager.shared.log("✅ HEADLESS: Modifier \(modifier) - \(isActive ? "activated" : "deactivated")")
        }
        
        udpTracker?.onLayerChange = { layer in
            LogManager.shared.log("✅ HEADLESS: Layer changed to - \(layer)")
        }
        
        LogManager.shared.logInit("✅ Headless UDP server ready - waiting for messages...")
        LogManager.shared.logInit("💡 Test with: echo 'keypress:a' | nc -u 127.0.0.1 6789")
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            LogManager.shared.log("🛑 HEADLESS: Received SIGINT - shutting down gracefully")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            LogManager.shared.log("🛑 HEADLESS: Received SIGTERM - shutting down gracefully")
            exit(0)
        }
        
        LogManager.shared.logInit("🔄 Headless mode active - app will run without windows")
        LogManager.shared.logInit("💡 Kanata runs separately - start it independently")
    }
}

// MARK: - Custom Window Class with Drag Support

class DraggableWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Command+Q or Command+W to quit
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "q" || event.charactersIgnoringModifiers == "w" {
                LogManager.shared.log("🚪 Command+\(event.charactersIgnoringModifiers?.uppercased() ?? "") detected - quitting app")
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

@main
struct LearnKeysUDPApp: App {
    @StateObject private var animationController = AnimationController()
    @StateObject private var layerManager = LayerManager()
    @StateObject private var kanataManager = KanataManager.shared
    
    // Static property to track headless mode
    private static let isHeadless = CommandLine.arguments.contains("--headless")
    
    init() {
        // Start headless mode if requested
        if Self.isHeadless {
            HeadlessUDPServer.shared.start()
        } else {
            // GUI mode - Kanata runs independently
            LogManager.shared.logInit("🚀 Starting GUI mode - Kanata should be launched separately")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // In headless mode, create a minimal hidden view
            if Self.isHeadless {
                Text("Headless Mode")
                    .frame(width: 1, height: 1)
                    .opacity(0)
                    .onAppear {
                        // Hide the window immediately in headless mode
                        DispatchQueue.main.async {
                            NSApp.windows.first?.orderOut(nil)
                            NSApp.setActivationPolicy(.prohibited)
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(animationController)
                    .environmentObject(layerManager)
                    .environmentObject(kanataManager)
                    .onAppear {
                        LogManager.shared.logInit("🎯 LearnKeys UDP-First started!")
                        LogManager.shared.logInit("🎯 Architecture: Clean UDP-driven design")
                        LogManager.shared.logInit("🎯 No accessibility permissions needed")
                        configureWindow()
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unifiedCompact)
    }
    
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit LearnKeys", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(withTitle: "Close Window", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "w")
        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
    
    private func configureWindow() {
        DispatchQueue.main.async {
            // Set up menu bar for Command+Q to work
            self.setupMenuBar()
            
            // Configure window properties to match original but with better UX
            if let window = NSApp.windows.first {
                // Replace the standard window with our draggable window
                let currentContentView = window.contentView
                let currentFrame = window.frame
                
                let newWindow = DraggableWindow(
                    contentRect: currentFrame,
                    styleMask: [.borderless, .resizable],
                    backing: .buffered,
                    defer: false
                )
                
                // Set window properties
                newWindow.level = .normal  // Changed from .floating to be less intrusive
                newWindow.isOpaque = true
                newWindow.backgroundColor = .black
                newWindow.hasShadow = true  // Changed from false to provide visual feedback
                newWindow.contentView = currentContentView
                
                // Position on secondary monitor (desktop 2) like original
                let screens = NSScreen.screens
                let targetScreen = screens.count > 1 ? screens[1] : screens[0] // Use secondary if available, else main
                let contentRect = targetScreen.frame // Use full screen like original
                
                newWindow.setFrame(contentRect, display: true)
                
                // Close the old window and show the new one
                window.close()
                newWindow.makeKeyAndOrderFront(nil)
                newWindow.makeFirstResponder(newWindow)
                
                LogManager.shared.logInit("🎯 Window configured: draggable, resizable, with shadow")
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var animationController: AnimationController
    @EnvironmentObject var layerManager: LayerManager
    @EnvironmentObject var kanataManager: KanataManager
    @State private var config = KanataConfig.defaultQWERTY
    
    var body: some View {
        VStack(spacing: 4) {
            // Header (exact replica of original)
            headerView
            
            // Animated letter row (always shown - signature feature)
            animatedLetterRow
            
            // Key Layout (selective display like original)
            if !config.physicalKeys.isEmpty {
                keyboardLayout
            } else {
                emptyStateView
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    // MARK: - Header (with drag area)
    
    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LearnKeys")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("config.kbd")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Layer: \(animationController.currentLayer)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                HStack(spacing: 12) {
                    // UDP Connection Status
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    
                    Text("UDP Connected")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Separator
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    // Kanata Status
                    Circle()
                        .fill(kanataManager.isKanataRunning ? .green : .red)
                        .frame(width: 12, height: 12)
                    
                    Text("Kanata: \(kanataManager.kanataStatus)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Animated Letter Row (exact original)
    
    private var animatedLetterRow: some View {
        let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let smallFontSize: CGFloat = 60
        let largeFontSize: CGFloat = 120
        let overlayScale: CGFloat = 1.25
        let overlayFrameHeight: CGFloat = 80
        let drawWidth: CGFloat = 160
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            // Base letter row (small letters, always visible when not active)
            letterRow(letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing, 
                     smallFontSize: smallFontSize, overlayFrameHeight: overlayFrameHeight)
            
            // Overlay animated letters (large letters, only when active)
            overlayAnimatedLetters(letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing,
                                 largeFontSize: largeFontSize, overlayScale: overlayScale, 
                                 overlayFrameHeight: overlayFrameHeight, drawWidth: drawWidth)
        }
        .frame(width: totalWidth, height: overlayFrameHeight)
    }
    
    private func letterRow(letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat, 
                          smallFontSize: CGFloat, overlayFrameHeight: CGFloat) -> some View {
        let drawWidth: CGFloat = 160
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return HStack(spacing: slotSpacing) {
            ForEach(letters, id: \.self) { letter in
                let physicalKey = letter.lowercased()
                let isActive = animationController.getKeyState(physicalKey)?.isPressed ?? false
                
                ZStack {
                    GeometryReader { geo in
                        if !isActive {
                            Text(letter)
                                .font(.system(size: smallFontSize, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: slotWidth, height: overlayFrameHeight)
                                .position(x: drawWidth / 2, y: overlayFrameHeight / 2)
                                .transition(.scale)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
                        }
                    }
                    .frame(width: drawWidth, height: overlayFrameHeight)
                }
                .frame(width: slotWidth, height: overlayFrameHeight)
            }
        }
        .frame(width: totalWidth, height: overlayFrameHeight, alignment: .center)
    }
    
    private func overlayAnimatedLetters(letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat,
                                       largeFontSize: CGFloat, overlayScale: CGFloat, 
                                       overlayFrameHeight: CGFloat, drawWidth: CGFloat) -> some View {
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let letter = pair.element
                let physicalKey = letter.lowercased()
                let isActive = animationController.getKeyState(physicalKey)?.isPressed ?? false
                
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
    
    private func homeRowPhysicalKey(for index: Int) -> String {
        let homeRowKeys = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        return index < homeRowKeys.count ? homeRowKeys[index] : "a"
    }
    
    // MARK: - Keyboard Layout (exact original alignment)
    
    private var keyboardLayout: some View {
        VStack(spacing: 20) {
            if animationController.currentLayer == "base" {
                // Base layer: aligned modifier row with background panels
                alignedModifierRow()
            } else {
                // Other layers: aligned navigation keys with background panels
                alignedNavigationKeys()
            }
        }
        .frame(minHeight: 200)
    }
    
    // MARK: - Aligned Modifier Row (exact original positioning)
    
    private func alignedModifierRow() -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        let modifierMappings: [String: String] = [
            "a": "shift", "s": "control", "d": "option", "f": "layer", "g": "command",
            "j": "rcommand", "k": "roption", "l": "rcontrol", ";": "rshift"
        ]
        
        return ZStack {
            // Background panels grouped by hand
            modifierBackground(letters: letters, modifierMappings: modifierMappings, 
                             slotWidth: slotWidth, slotSpacing: slotSpacing)
            
            // Position each modifier under its corresponding letter
            ForEach(letters, id: \.self) { letter in
                if let action = modifierMappings[letter.lowercased()],
                   let letterIndex = letters.firstIndex(of: letter.lowercased()) {
                    modifierKeyForAction(action, physicalKey: letter)
                        .position(
                            x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                            y: 50 // Match original positioning
                        )
                }
            }
        }
        .frame(width: totalWidth, height: 72)
    }
    
    // MARK: - Navigation Key Data Structure
    
    private struct NavigationKey {
        let key: String
        let label: String
        let symbol: String?
        let arrow: Bool
        let direction: String?
    }
    
    // MARK: - Aligned Navigation Keys (exact original positioning)
    
    private func alignedNavigationKeys() -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        // Define navigation keys based on layer
        let navigationKeys: [NavigationKey]
        
        if animationController.currentLayer == "f-nav" {
            navigationKeys = [
                NavigationKey(key: "h", label: "←", symbol: nil, arrow: true, direction: "left"),
                NavigationKey(key: "j", label: "↓", symbol: nil, arrow: true, direction: "down"),
                NavigationKey(key: "k", label: "↑", symbol: nil, arrow: true, direction: "up"),
                NavigationKey(key: "l", label: "→", symbol: nil, arrow: true, direction: "right")
            ]
        } else if animationController.currentLayer == "navfast" {
            navigationKeys = [
                NavigationKey(key: "h", label: "⇤", symbol: nil, arrow: true, direction: "left"),
                NavigationKey(key: "j", label: "⇟", symbol: nil, arrow: true, direction: "down"),
                NavigationKey(key: "k", label: "⇞", symbol: nil, arrow: true, direction: "up"),
                NavigationKey(key: "l", label: "⇥", symbol: nil, arrow: true, direction: "right")
            ]
        } else {
            navigationKeys = []
        }
        
        return ZStack {
            // Background panel for active navigation keys
            if !navigationKeys.isEmpty {
                navigationBackground(keys: navigationKeys, letters: letters, 
                                   slotWidth: slotWidth, slotSpacing: slotSpacing)
            }
            
            // Position each navigation key under its corresponding letter
            ForEach(navigationKeys, id: \.key) { navKey in
                if let letterIndex = letters.firstIndex(of: navKey.key.lowercased()) {
                    OriginalKeyCap(
                        label: navKey.label,
                        symbol: navKey.symbol,
                        isArrow: navKey.arrow,
                        isActive: animationController.getKeyState(navKey.key)?.isPressed ?? false,
                        arrowDirection: navKey.direction
                    )
                    .position(
                        x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                        y: 36 // Match original positioning
                    )
                }
            }
        }
        .frame(width: totalWidth, height: 72)
    }
    
    // MARK: - Background Panels (exact original styling)
    
    private func modifierBackground(letters: [String], modifierMappings: [String: String], 
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
                                gradient: Gradient(colors: [Color(hex: "1C1C1C") ?? .gray, Color(hex: "181818") ?? .gray]),
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "323232") ?? .gray, lineWidth: 1)
                        )
                        .frame(width: groupWidth, height: backgroundHeight)
                        .position(x: centerX, y: 50) // Match button positioning
                }
            }
        }
    }
    
    private func navigationBackground(keys: [NavigationKey], 
                                    letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        let keyPositions = keys.compactMap { key -> Int? in
            letters.firstIndex(of: key.key.lowercased())
        }.sorted()
        
        let groups = groupConsecutivePositionsByHand(keyPositions, letters: letters)
        let horizontalPadding: CGFloat = 45
        let backgroundHeight: CGFloat = 72 + 32
        
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
                                gradient: Gradient(colors: [Color(hex: "1C1C1C") ?? .gray, Color(hex: "181818") ?? .gray]),
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "323232") ?? .gray, lineWidth: 1)
                        )
                        .frame(width: groupWidth, height: backgroundHeight)
                        .position(x: centerX, y: 36) // Center on key position
                }
            }
        }
    }
    
    // MARK: - Helper Functions (exact original)
    
    private func modifierKeyForAction(_ action: String, physicalKey: String) -> some View {
        let isActive = animationController.isModifierActive(physicalKey)
        
        let (displayText, symbol): (String, String)
        switch action.lowercased() {
        case "shift", "rshift": (displayText, symbol) = ("shift", "⇧")
        case "control", "rcontrol": (displayText, symbol) = ("control", "⌃")
        case "option", "roption": (displayText, symbol) = ("option", "⌥")
        case "command", "rcommand": (displayText, symbol) = ("command", "⌘")
        case "layer": (displayText, symbol) = ("layer", "☰")
        default: (displayText, symbol) = (action.lowercased(), "◊")
        }
        
        return OriginalKeyCap(
            label: displayText,
            symbol: symbol,
            isArrow: false,
            isActive: isActive,
            arrowDirection: nil,
            temporaryState: nil
        )
    }
    
    private func groupConsecutivePositionsByHand(_ positions: [Int], letters: [String]) -> [[Int]] {
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
    
    private func getHandForPosition(_ position: Int, letters: [String]) -> String {
        // Split based on standard QWERTY hand positioning
        // Left hand: a(0), s(1), d(2), f(3), g(4)
        // Right hand: h(5), j(6), k(7), l(8), ;(9)
        return position < 5 ? "left" : "right"
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("No Config Loaded")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Load a kanata config file to see your key mappings")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
} 