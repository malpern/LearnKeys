// Commented out all image loading and NSImageView code for pure SwiftUI rendering
// import Cocoa
import SwiftUI

class QuitOnCommandWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Command+W
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "w" {
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

// class NonInteractiveImageView: NSImageView {
//     override var acceptsFirstResponder: Bool { false }
// }

// --- SwiftUI Implementation ---

// KeyCap renders a single key (modifier or arrow) with custom styling and pressed state
struct KeyCap: View {
    let label: String
    let symbol: String?
    let isArrow: Bool
    let isActive: Bool
    
    private var keyCapWidth: CGFloat {
        if isArrow {
            return 54
        } else {
            return 120 // User set width
        }
    }
    // Centralized styling properties
    private var modifierLabelFont: Font {
        .system(size: 18, design: .default)
    }
    private var modifierLabelColor: Color {
        isActive ? Color(hex: "232323") : Color(hex: "F7F7F7")
    }
    private var modifierSymbolFont: Font {
        .system(size: 32, weight: .light, design: .default)
    }
    private var modifierSymbolColor: Color {
        isActive ? Color(hex: "232323") : Color(hex: "F7F7F7")
    }
    private var modifierLabelPadding: CGFloat { 12 }
    private var modifierSymbolPadding: CGFloat { 12 }
    private var arrowLabelFont: Font {
        .system(size: 28, weight: .bold, design: .default)
    }
    private var arrowLabelColor: Color { .black }
    private var arrowLabelShadow: Color { .white.opacity(0.7) }
    private var arrowSymbolFont: Font {
        .system(size: 20, weight: .bold, design: .default)
    }
    private var arrowSymbolColor: Color {
        isActive ? .black.opacity(0.8) : .white.opacity(0.8)
    }
    private var modifierLabelOpacity: Double { 0.4 }
    var body: some View {
        VStack(alignment: .center, spacing: isArrow ? 0 : 2.2) {
            // Render symbol (if present) above the label
            if let symbol = symbol {
                if isArrow {
                    Text(symbol)
                        .font(arrowSymbolFont)
                        .foregroundColor(arrowSymbolColor)
                } else {
                Text(symbol)
                        .font(modifierSymbolFont)
                        .foregroundColor(modifierSymbolColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.leading, modifierSymbolPadding)
                        .padding(.trailing, modifierSymbolPadding)
                }
            }
            // Render label (main key name)
            if isArrow {
                Text(label)
                    .font(arrowLabelFont)
                    .foregroundColor(arrowLabelColor)
                    .shadow(color: arrowLabelShadow, radius: 0.2, x: 0, y: 0.2)
            } else {
            Text(label)
                    .font(modifierLabelFont)
                    .foregroundColor(modifierLabelColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, modifierLabelPadding)
                    .padding(.trailing, modifierLabelPadding)
                    .opacity(modifierLabelOpacity)
            }
        }
        .frame(width: keyCapWidth, height: isArrow ? 54 : 72)
        // Key background: gradient and pressed state
        .background(
            Group {
                if isArrow {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "F9F8F8"), Color(hex: "D0CFCF")]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .opacity(0.7)
                } else {
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "F7F7F7"), Color(hex: "E0E0E0")]),
                            startPoint: .top, endPoint: .bottom
                        )
                    } else {
            LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "656565"), Color(hex: "4D4D4E")]),
                startPoint: .top, endPoint: .bottom
            )
                    }
                }
            }
        )
        // Key border: gradient or solid depending on type and state
        .overlay(
            Group {
                if isArrow {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.black.opacity(0.4) : Color(white: 0.7, opacity: 0.4), lineWidth: 1)
                } else {
                    if isActive {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "B0B0B0"), Color(hex: "D0D0D0")]),
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                    } else {
            RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "777778"), Color(hex: "5B5B5B")]),
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                    }
                }
            }
        )
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)
    }
}

struct ModifierRow: View {
    let keys: [(String, String?)]
    var body: some View {
        HStack(spacing: 16) {
            ForEach(keys.indices, id: \.self) { index in
                let key = keys[index]
                KeyCap(label: key.0, symbol: key.1, isArrow: false, isActive: false)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(white: 0.16), Color(white: 0.10)]),
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(white: 0.7, opacity: 0.25), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)
    }
}

struct ArrowRow: View {
    var body: some View {
        HStack(spacing: 24) {
            KeyCap(label: "←", symbol: nil, isArrow: true, isActive: false)
            KeyCap(label: "↓", symbol: nil, isArrow: true, isActive: true)
            KeyCap(label: "→", symbol: nil, isArrow: true, isActive: false)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(white: 0.16), Color(white: 0.10)]),
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(white: 0.7, opacity: 0.25), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)
    }
}

// Helper to monitor key events
import AppKit
struct KeyEventMonitor: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void
    var onKeyUp: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let options: NSEvent.EventTypeMask = [.keyDown, .keyUp]
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: options) { event in
            switch event.type {
            case .keyDown:
                onKeyDown(event)
            case .keyUp:
                onKeyUp(event)
            default:
                break
            }
            return event
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var monitor: Any?
    }
}

// GlobalKeyEventMonitor: listens for global key events using CGEventTap
class GlobalKeyEventMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
    private let handler: (CGEventType, CGKeyCode) -> Void

    init(handler: @escaping (CGEventType, CGKeyCode) -> Void) {
        self.handler = handler
        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalKeyEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                monitor.handler(type, CGKeyCode(keyCode))
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        self.eventTap = eventTap
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            DispatchQueue.global(qos: .userInteractive).async {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .commonModes)
                CGEvent.tapEnable(tap: eventTap, enable: true)
                CFRunLoopRun()
            }
        }
    }
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
}

// Main guide view for the chromeless keyboard layout
struct ChromelessGuideView: View {
    let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
    @State private var activeKeys: Set<String> = []
    @State private var globalMonitor: GlobalKeyEventMonitor? = nil
    @State private var overlayAnimating: [String: Bool] = [:]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 60) {
                ZStack {
                    letterRow
                    overlayAnimatedLetters
                }
                modifierRow
                arrowRowWithBackground
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.black.ignoresSafeArea())
        }
        .onAppear {
            globalMonitor = GlobalKeyEventMonitor { type, keyCode in
                guard let key = keyIdentifierFromKeyCode(keyCode) else { return }
                DispatchQueue.main.async {
                    if type == .keyDown {
                        activeKeys.insert(key)
                        overlayAnimating[key] = true
                    } else if type == .keyUp {
                        activeKeys.remove(key)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            overlayAnimating[key] = false
                        }
                    }
                }
            }
        }
        .onDisappear {
            globalMonitor = nil
        }
    }

    // Overlay animated letters
    var overlayAnimatedLetters: some View {
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let smallFontSize: CGFloat = 60
        let largeFontSize: CGFloat = 120
        let overlayScale: CGFloat = 1.25
        let overlayFrameHeight: CGFloat = 160
        let drawWidth: CGFloat = 160
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        return ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let letter = pair.element
                if overlayAnimating[letter.lowercased()] == true {
                    let isActive = activeKeys.contains(letter.lowercased())
                    Text(letter)
                        .font(.system(size: isActive ? largeFontSize : smallFontSize, weight: isActive ? .black : .light, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(isActive ? overlayScale : 1.0)
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

    // Letter row: 10 home row letters, equally spaced, with overlay for animated letters
    var letterRow: some View {
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let smallFontSize: CGFloat = 60
        let largeFontSize: CGFloat = 120
        let overlayScale: CGFloat = 1.25
        let overlayFrameHeight: CGFloat = 160
        let drawWidth: CGFloat = 160 // Large enough for the biggest letter
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        return HStack(spacing: slotSpacing) {
            ForEach(letters, id: \.self) { letter in
                ZStack {
                    GeometryReader { geo in
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        // Only show the small letter if not animating in overlay
                        if overlayAnimating[letter.lowercased()] != true {
                            Text(letter)
                                .font(.system(size: smallFontSize, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: slotWidth, height: overlayFrameHeight)
                                .position(x: drawWidth / 2, y: overlayFrameHeight / 2)
                                .transition(.scale)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: activeKeys)
                        }
                    }
                    .frame(width: drawWidth, height: overlayFrameHeight)
                }
                .frame(width: slotWidth, height: overlayFrameHeight)
            }
        }
        .frame(width: totalWidth, height: overlayFrameHeight, alignment: .center)
    }

    // Modifier row: 10 slots, with modifier keys under A, S, D, F, J, K, L, ; and empty slots under G and H for alignment
    var modifierRow: some View {
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let keyHeight: CGFloat = 72
        let backgroundWidth: CGFloat = (4 * slotWidth) + (3 * slotSpacing) + 90
        let backgroundHeight: CGFloat = keyHeight + 24 + 8
        let totalWidth = CGFloat(10) * slotWidth + CGFloat(9) * slotSpacing
        let leftGroupStart = slotWidth / 2
        let leftGroupEnd = 3 * (slotWidth + slotSpacing) + slotWidth / 2
        let leftGroupCenter = (leftGroupStart + leftGroupEnd) / 2
        let leftBackgroundOffset = leftGroupCenter - (backgroundWidth / 2)
        let rightGroupStart = 6 * (slotWidth + slotSpacing) + slotWidth / 2
        let rightGroupEnd = 9 * (slotWidth + slotSpacing) + slotWidth / 2
        let rightGroupCenter = (rightGroupStart + rightGroupEnd) / 2
        let rightBackgroundOffset = rightGroupCenter - (backgroundWidth / 2)
        return ZStack(alignment: .leading) {
            // Left group background (A, S, D, F)
            ZStack {
                let fill = RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "1C1C1C"), Color(hex: "181818")]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                let stroke = RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "323232"), lineWidth: 1)
                fill
                stroke
            }
            .frame(width: backgroundWidth, height: backgroundHeight)
            .offset(x: leftBackgroundOffset, y: 0)
            // Right group background (J, K, L, ;)
            ZStack {
                let fill = RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "1C1C1C"), Color(hex: "181818")]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                let stroke = RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "323232"), lineWidth: 1)
                fill
                stroke
            }
            .frame(width: backgroundWidth, height: backgroundHeight)
            .offset(x: rightBackgroundOffset, y: 0)
            // 10-slot grid of modifier keys (with empty slots under G and H)
            HStack(spacing: slotSpacing) {
                ZStack { KeyCap(label: "shift", symbol: "⇧", isArrow: false, isActive: activeKeys.contains("shift")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "control", symbol: "⌃", isArrow: false, isActive: activeKeys.contains("control")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "option", symbol: "⌥", isArrow: false, isActive: activeKeys.contains("option")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "command", symbol: "⌘", isArrow: false, isActive: activeKeys.contains("command")) }.frame(width: slotWidth)
                Spacer().frame(width: slotWidth)
                Spacer().frame(width: slotWidth)
                ZStack { KeyCap(label: "command", symbol: "⌘", isArrow: false, isActive: activeKeys.contains("command")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "option", symbol: "⌥", isArrow: false, isActive: activeKeys.contains("option")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "control", symbol: "⌃", isArrow: false, isActive: activeKeys.contains("control")) }.frame(width: slotWidth)
                ZStack { KeyCap(label: "shift", symbol: "⇧", isArrow: false, isActive: activeKeys.contains("shift")) }.frame(width: slotWidth)
            }
            .frame(width: totalWidth)
        }
        .frame(width: totalWidth)
    }

    // Arrow row with background: background is anchored to left arrow and extends with equal padding
    var arrowRowWithBackground: some View {
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalLetterRowWidth = CGFloat(10) * slotWidth + CGFloat(9) * slotSpacing
        let arrowBlockVisualWidth = CGFloat(4) * slotWidth + CGFloat(3) * slotSpacing
        let backgroundHorizontalPadding: CGFloat = 32
        let arrowBackgroundWidth = arrowBlockVisualWidth + 2 * backgroundHorizontalPadding
        let arrowBackgroundHeight = CGFloat(54 + 24)
        let leftArrowX = CGFloat(5) * slotWidth + CGFloat(5) * slotSpacing
        let backgroundOffset = leftArrowX - backgroundHorizontalPadding - (totalLetterRowWidth / 2) + (arrowBackgroundWidth / 2)
        return ZStack(alignment: .center) {
            arrowBackgroundShape
                .frame(width: arrowBackgroundWidth, height: arrowBackgroundHeight)
                .offset(x: backgroundOffset, y: 0)
            arrowKeysRow
        }
        .frame(width: totalLetterRowWidth, height: arrowBackgroundHeight)
    }

    // Arrow key background shape: dark gradient fill and solid border
    var arrowBackgroundShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "1C1C1C"), Color(hex: "181818")]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "323232"), lineWidth: 1)
        }
    }

    // Arrow keys row: left arrow is centered under H (slot 5)
    var arrowKeysRow: some View {
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        return HStack(spacing: slotSpacing) {
            ForEach(0..<5) { _ in Spacer().frame(width: slotWidth) }
            KeyCap(label: "←", symbol: nil, isArrow: true, isActive: activeKeys.contains("left")).frame(width: slotWidth, height: 54)
            KeyCap(label: "↓", symbol: nil, isArrow: true, isActive: activeKeys.contains("down")).frame(width: slotWidth, height: 54)
            KeyCap(label: "→", symbol: nil, isArrow: true, isActive: activeKeys.contains("right")).frame(width: slotWidth, height: 54)
            KeyCap(label: "↑", symbol: nil, isArrow: true, isActive: activeKeys.contains("up")).frame(width: slotWidth, height: 54)
            Spacer().frame(width: slotWidth)
        }
    }
}

// AnimatedLetter: animates size and weight when active
struct AnimatedLetter: View {
    let letter: String
    let isActive: Bool
    var body: some View {
        Text(letter)
            .font(.system(size: isActive ? 120 : 60, weight: isActive ? .black : .light, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .frame(width: 64)
            .fixedSize()
            .zIndex(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1.25 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }
}

// Helper to map CGKeyCode to key string (for global event tap)
func keyIdentifierFromKeyCode(_ keyCode: CGKeyCode) -> String? {
    switch keyCode {
    case 123: return "left"
    case 124: return "right"
    case 125: return "down"
    case 126: return "up"
    case 56, 60: return "shift"
    case 59, 62: return "control"
    case 58, 61: return "option"
    case 55, 54: return "command"
    case 0: return "a"
    case 1: return "s"
    case 2: return "d"
    case 3: return "f"
    case 5: return "g"
    case 4: return "h"
    case 38: return "j"
    case 40: return "k"
    case 37: return "l"
    case 41: return ";"
    default: return nil
    }
}

// --- End SwiftUI Implementation ---

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let quitTitle = "Quit " + (Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App")
        appMenu.addItem(
            withTitle: quitTitle,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        NSApp.mainMenu = mainMenu
    }

    func applicationDidFinishLaunching(_: Notification) {
        setupMenu()
        // --- Commented out image loading ---
        // let path = ("~/Downloads/homerow-guide.png" as NSString).expandingTildeInPath
        // if let image = NSImage(contentsOfFile: path) {
        //     ... (old image code) ...
        // }
        let screens = NSScreen.screens
        let targetScreen = screens.count > 1 ? screens[1] : screens[0] // Use secondary if available, else main
        let contentRect = targetScreen.frame
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

        // SwiftUI hosting
        let swiftUIView = ChromelessGuideView()
        let hosting = NSHostingView(rootView: swiftUIView)
        hosting.frame = window.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hide from Dock and Cmd+Tab
app.run()

// Add this Color extension for hex support:
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alphaValue, redValue, greenValue, blueValue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alphaValue, redValue, greenValue, blueValue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alphaValue, redValue, greenValue, blueValue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alphaValue, redValue, greenValue, blueValue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alphaValue, redValue, greenValue, blueValue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(redValue) / 255,
            green: Double(greenValue) / 255,
            blue: Double(blueValue) / 255,
            opacity: Double(alphaValue) / 255
        )
    }
}

// NOTE: For global key listening, your app must be granted Accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility.

