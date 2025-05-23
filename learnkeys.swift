import SwiftUI
import Foundation
import Network

// MARK: - Kanata Config Parser

struct KanataConfig {
    var defsrc: [String] = []
    var layers: [String: [String]] = [:]
    var aliases: [String: KanataAlias] = [:]
    var variables: [String: String] = [:]
    var capsWordConfig: CapsWordConfig? = nil  // Add caps-word timing config
}

struct CapsWordConfig {
    let tapTimeout: TimeInterval      // Time before tap becomes hold (150ms)
    let holdTimeout: TimeInterval     // Time before hold activates caps-word (200ms) 
    let duration: TimeInterval        // How long caps-word stays active (2000ms)
    let triggerKey: String           // Which key triggers it (esc)
    
    init(tapTimeout: TimeInterval, holdTimeout: TimeInterval, duration: TimeInterval, triggerKey: String) {
        self.tapTimeout = tapTimeout / 1000.0      // Convert ms to seconds
        self.holdTimeout = holdTimeout / 1000.0    // Convert ms to seconds
        self.duration = duration / 1000.0          // Convert ms to seconds
        self.triggerKey = triggerKey
    }
}

struct KanataAlias {
    let name: String
    let definition: String
    let tapAction: String?
    let holdAction: String?
    let isModifier: Bool
    let isLayer: Bool
    
    init(name: String, definition: String) {
        self.name = name
        self.definition = definition
        
        var tempTapAction: String? = nil
        var tempHoldAction: String? = nil
        var tempIsModifier = false
        var tempIsLayer = false
        
        // Parse tap-hold patterns
        if definition.contains("tap-hold") {
            // Parse tap-hold-release-keys format: tap-hold-release-keys time time (multi key @tap) holdAction keys
            if definition.contains("tap-hold-release-keys") {
                // Extract the tap action from (multi key @tap) pattern
                if let multiRange = definition.range(of: #"\(multi ([a-zA-Z0-9;]+) @tap\)"#, options: .regularExpression) {
                    let multiMatch = String(definition[multiRange])
                    // Extract just the key name from "(multi key @tap)"
                    let keyPattern = #"multi ([a-zA-Z0-9;]+) @tap"#
                    if let keyMatch = multiMatch.range(of: keyPattern, options: .regularExpression) {
                        let keyPart = String(multiMatch[keyMatch])
                        tempTapAction = keyPart.replacingOccurrences(of: "multi ", with: "").replacingOccurrences(of: " @tap", with: "")
                    }
                } else {
                    // Enhanced parsing for simple tap-hold-release-keys format
                    // Format: tap-hold-release-keys time time tapAction holdAction keys
                    let parts = definition.components(separatedBy: " ")
                    
                    // Find the tap action (usually after the timing values)
                    if parts.count >= 4 {
                        let tapActionCandidate = parts[3]
                        if !tapActionCandidate.contains("(") && !tapActionCandidate.isEmpty {
                            tempTapAction = tapActionCandidate
                        } else {
                            print("⚠️  Complex tap action detected for '\(name)': \(tapActionCandidate)")
                        }
                    } else {
                        print("❌ Insufficient parts in tap-hold definition for '\(name)': \(parts.count) parts")
                    }
                }
            } else {
                // Simple parsing for basic tap-hold format
                let parts = definition.components(separatedBy: " ")
                if parts.count >= 4 {
                    tempTapAction = parts[3]
                }
            }
            
            // Extract hold action from various patterns
            if definition.contains("@shift") || definition.contains("lsft") {
                tempHoldAction = "@shift"
                tempIsModifier = true
            } else if definition.contains("@control") || definition.contains("lctl") {
                tempHoldAction = "@control"
                tempIsModifier = true
            } else if definition.contains("@option") || definition.contains("lalt") {
                tempHoldAction = "@option"
                tempIsModifier = true
            } else if definition.contains("@command") || definition.contains("lmet") {
                tempHoldAction = "@command"
                tempIsModifier = true
            } else if definition.contains("@rshift") || definition.contains("rsft") {
                tempHoldAction = "@rshift"
                tempIsModifier = true
            } else if definition.contains("@rcontrol") || definition.contains("rctl") {
                tempHoldAction = "@rcontrol"
                tempIsModifier = true
            } else if definition.contains("@roption") || definition.contains("ralt") {
                tempHoldAction = "@roption"
                tempIsModifier = true
            } else if definition.contains("@rcommand") || definition.contains("rmet") {
                tempHoldAction = "@rcommand"
                tempIsModifier = true
            } else if definition.contains("layer-toggle") || definition.contains("layer-while-held") {
                tempIsModifier = false
                tempIsLayer = true
                tempHoldAction = "layer"
            } else if definition.contains("caps-word") {
                tempIsModifier = false
                tempIsLayer = false
                tempHoldAction = "caps-word"
            } else {
                // Log unrecognized hold actions in tap-hold expressions
                if definition.contains("tap-hold") {
                    print("⚠️  Unrecognized hold action in tap-hold definition for '\(name)': \(definition)")
                }
            }
            
            tempIsLayer = definition.contains("layer")
        } else {
            tempTapAction = definition
            tempIsLayer = definition.contains("layer")
        }
        
        self.tapAction = tempTapAction
        self.holdAction = tempHoldAction
        self.isModifier = tempIsModifier
        self.isLayer = tempIsLayer
    }
}

class KanataConfigParser: ObservableObject {
    private var parseErrors: [String] = []
    private var parseWarnings: [String] = []
    
    func parseConfig(from content: String) -> KanataConfig {
        parseErrors.removeAll()
        parseWarnings.removeAll()
        var config = KanataConfig()
        
        let lines = content.components(separatedBy: .newlines)
        var currentExpression = ""
        var inExpression = false
        var parenCount = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix(";;") { continue }
            
            for char in trimmed {
                if char == "(" {
                    if !inExpression {
                        inExpression = true
                        currentExpression = ""
                    }
                    parenCount += 1
                    currentExpression.append(char)
                } else if char == ")" {
                    parenCount -= 1
                    currentExpression.append(char)
                    if parenCount == 0 {
                        parseExpression(currentExpression, config: &config)
                        currentExpression = ""
                        inExpression = false
                    }
                } else if inExpression {
                    currentExpression.append(char)
                }
            }
            
            // Add space between lines when inside an expression
            if inExpression && !currentExpression.isEmpty && !currentExpression.hasSuffix(" ") {
                currentExpression.append(" ")
            }
        }
        
        // Report parsing summary
        reportParsingSummary(config: config)
        
        return config
    }
    
    private func reportParsingSummary(config: KanataConfig) {
        print("=== PARSING SUMMARY ===")
        print("✅ Parsed \(config.aliases.count) aliases, \(config.layers.count) layers")
        
        if !parseWarnings.isEmpty {
            print("⚠️  WARNINGS (\(parseWarnings.count)):")
            for warning in parseWarnings {
                print("   • \(warning)")
            }
        }
        
        if !parseErrors.isEmpty {
            print("❌ ERRORS (\(parseErrors.count)):")
            for error in parseErrors {
                print("   • \(error)")
            }
        }
        
        // Validate aliases for display issues
        validateAliasesForDisplay(config: config)
        
        if parseErrors.isEmpty && parseWarnings.isEmpty {
            print("✅ No parsing issues detected")
        }
        print("=======================")
    }
    
    private func validateAliasesForDisplay(config: KanataConfig) {
        print("🔍 Validating aliases for display compatibility...")
        
        for (name, alias) in config.aliases {
            var issues: [String] = []
            
            // Check if tap action is parseable
            if alias.definition.contains("tap-hold") && alias.tapAction == nil {
                issues.append("Missing tap action - will show raw definition")
            }
            
            // Check if hold action is supported for display
            if let holdAction = alias.holdAction {
                if !isSupportedHoldAction(holdAction) {
                    issues.append("Unsupported hold action '\(holdAction)' - may not display correctly")
                }
            }
            
            // Check for complex actions that aren't fully parsed
            if alias.definition.contains("(multi") && !alias.definition.contains("@tap") {
                issues.append("Complex multi-action not fully parsed")
            }
            
            // Check for potentially problematic display text
            if wouldShowTruncatedText(alias: alias) {
                issues.append("Definition too complex - would show truncated text like '(TAP-HO...'")
            }
            
            if !issues.isEmpty {
                parseWarnings.append("Alias '\(name)': \(issues.joined(separator: ", "))")
            }
        }
    }
    
    private func isSupportedHoldAction(_ action: String) -> Bool {
        let supportedActions = [
            "@shift", "@control", "@option", "@command",
            "@rshift", "@rcontrol", "@roption", "@rcommand",
            "lsft", "lctl", "lalt", "lmet",
            "rsft", "rctl", "ralt", "rmet",
            "layer", "caps-word"
        ]
        return supportedActions.contains(action) || action.contains("layer")
    }
    
    private func wouldShowTruncatedText(alias: KanataAlias) -> Bool {
        // Check if this alias would result in showing truncated definition text
        if alias.definition.contains("tap-hold") && alias.tapAction == nil && alias.holdAction == nil {
            return true
        }
        if alias.definition.count > 20 && alias.tapAction == nil {
            return true
        }
        return false
    }
    
    private func parseExpression(_ expr: String, config: inout KanataConfig) {
        let tokens = tokenize(expr)
        guard !tokens.isEmpty else { return }
        
        switch tokens[0] {
        case "defsrc":
            config.defsrc = Array(tokens[1...])
        case "deflayer":
            if tokens.count >= 2 {
                let layerName = tokens[1]
                config.layers[layerName] = Array(tokens[2...])
            }
        case "defalias":
            parseAliases(tokens, config: &config)
        case "defvar":
            parseVariables(tokens, config: &config)
        default:
            break
        }
    }
    
    private func parseAliases(_ tokens: [String], config: inout KanataConfig) {
        print("DEBUG: parseAliases called with \(tokens.count) tokens")
        var index = 1
        while index < tokens.count - 1 {
            let name = tokens[index]
            let definition = tokens[index + 1]
            
            // Skip if this alias name already exists (prevent duplicates)
            if config.aliases[name] != nil {
                parseWarnings.append("Duplicate alias definition for '\(name)' - keeping first occurrence")
                print("DEBUG: Skipping duplicate alias '\(name)'")
                index += 2
                continue
            }
            
            let alias = KanataAlias(name: name, definition: definition)
            
            // Check if this is a caps-word alias and extract timing config
            if alias.holdAction == "caps-word" && definition.contains("tap-hold-release-keys") {
                print("DEBUG: 🕒 Found caps-word alias '\(name)' with definition: '\(definition)'")
                let parts = definition.components(separatedBy: " ")
                print("DEBUG: 🕒 Split into \(parts.count) parts: \(parts)")
                
                if parts.count >= 5,
                   let tapTime = Double(parts[1]),
                   let holdTime = Double(parts[2]) {
                    
                    print("DEBUG: 🕒 Extracted timing: tap=\(tapTime)ms, hold=\(holdTime)ms")
                    
                    // Extract caps-word duration from (caps-word 2000) pattern
                    if let capsWordRange = definition.range(of: #"\(caps-word (\d+)\)"#, options: .regularExpression) {
                        let capsWordMatch = String(definition[capsWordRange])
                        print("DEBUG: 🕒 Found caps-word pattern: '\(capsWordMatch)'")
                        
                        if let durationMatch = capsWordMatch.range(of: #"\d+"#, options: .regularExpression) {
                            let durationStr = String(capsWordMatch[durationMatch])
                            print("DEBUG: 🕒 Extracted duration string: '\(durationStr)'")
                            
                            if let duration = Double(durationStr) {
                                config.capsWordConfig = CapsWordConfig(
                                    tapTimeout: tapTime,
                                    holdTimeout: holdTime, 
                                    duration: duration,
                                    triggerKey: name
                                )
                                print("DEBUG: 🕒 ✅ Created caps-word config: tap=\(tapTime)ms, hold=\(holdTime)ms, duration=\(duration)ms, key='\(name)'")
                            } else {
                                print("DEBUG: 🕒 ❌ Failed to parse duration as Double: '\(durationStr)'")
                            }
                        } else {
                            print("DEBUG: 🕒 ❌ Failed to find duration number in: '\(capsWordMatch)'")
                        }
                    } else {
                        print("DEBUG: 🕒 ❌ Failed to find caps-word pattern in: '\(definition)'")
                    }
                } else {
                    print("DEBUG: 🕒 ❌ Failed to extract timing - parts.count=\(parts.count), tapTime=\(parts.count > 1 ? parts[1] : "missing"), holdTime=\(parts.count > 2 ? parts[2] : "missing")")
                }
            }
            
            // Validate alias parsing
            if definition.contains("tap-hold") {
                if alias.tapAction == nil {
                    parseErrors.append("Failed to parse tap action for alias '\(name)' with definition: \(definition)")
                }
                if alias.holdAction == nil {
                    parseErrors.append("Failed to parse hold action for alias '\(name)' with definition: \(definition)")
                }
            }
            
            // Check for unsupported complex features
            if definition.contains("defchords") || definition.contains("defseq") {
                parseWarnings.append("Alias '\(name)' uses unsupported feature (chords/sequences) - display may be incomplete")
            }
            
            print("DEBUG: Adding alias '\(name)' -> '\(definition)'")
            print("DEBUG: Parsed tap action: '\(alias.tapAction ?? "nil")' hold action: '\(alias.holdAction ?? "nil")'")
            config.aliases[name] = alias
            index += 2
        }
        
        // Check for incomplete alias lists (comment truncation issue)
        if tokens.count < 10 && tokens.contains(where: { $0.contains("fnav") }) {
            parseWarnings.append("Suspiciously few aliases parsed - check for inline comment issues")
        }
        
        print("DEBUG: Total aliases loaded: \(config.aliases.count)")
        for (key, alias) in config.aliases {
            if key.hasPrefix("fnav") {
                print("DEBUG: FNAV alias '\(key)' -> '\(alias.definition)'")
            }
        }
    }
    
    private func parseVariables(_ tokens: [String], config: inout KanataConfig) {
        var index = 1
        while index < tokens.count - 1 {
            let name = tokens[index]
            let value = tokens[index + 1]
            config.variables[name] = value
            index += 2
        }
    }
    
    private func tokenize(_ expr: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inParens = 0
        var inString = false
        
        // Check if this line contains a comment and truncate if needed
        // Only treat ";;" as comments, not single ";"
        let cleanExpr: String
        if let commentRange = expr.range(of: ";;") {
            cleanExpr = String(expr[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            cleanExpr = expr
        }
        
        for char in cleanExpr {
            if char == "\"" && inParens == 0 {
                inString.toggle()
                current.append(char)
            } else if inString {
                current.append(char)
            } else if char == "(" {
                if inParens > 0 { current.append(char) }
                inParens += 1
            } else if char == ")" {
                inParens -= 1
                if inParens > 0 { current.append(char) }
                else if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else if char.isWhitespace && inParens <= 1 {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        
        if !current.isEmpty {
            tokens.append(current)
        }
        
        return tokens
    }
}

// MARK: - TCP Client for Kanata

class KanataTCPClient: ObservableObject {
    @Published var currentLayer: String = "base"
    @Published var isConnected: Bool = false
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "kanata-tcp")
    
    func connect() {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(integerLiteral: 5829)
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    print("[TCP] Connected to kanata")
                case .failed(let error):
                    self?.isConnected = false
                    print("[TCP] Connection failed: \(error)")
                case .cancelled:
                    self?.isConnected = false
                    print("[TCP] Connection cancelled")
                default:
                    break
                }
            }
        }
        
        startReceiving()
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? ""
                self?.parseMessage(message)
            }
            
            if isComplete {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            } else if error == nil {
                self?.startReceiving()
            }
        }
    }
    
    private func parseMessage(_ message: String) {
        let lines = message.components(separatedBy: .newlines)
        for line in lines {
            if line.isEmpty { continue }
            
            print("[TCP] Raw message: \(line)")
            
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Handle layer changes
                if let layerChange = json["LayerChange"] as? [String: Any],
               let newLayer = layerChange["new"] as? String {
                
                DispatchQueue.main.async {
                    self.currentLayer = newLayer
                    print("[TCP] Layer changed to: \(newLayer)")
                    
                    // Notify about layer change for animation
                    NotificationCenter.default.post(
                        name: NSNotification.Name("LayerChanged"), 
                        object: newLayer
                    )
                }
            }
                
                // Check for caps-word or other state messages
                else {
                    print("[TCP] 🔍 Non-layer message detected: \(json)")
                    
                    // Look for caps-word indicators in various possible formats
                    if let msgType = json["type"] as? String {
                        print("[TCP] Message type: \(msgType)")
                        if msgType.lowercased().contains("caps") {
                            print("[TCP] 🅰 Caps-word related message detected!")
                        }
                    }
                    
                    // Check for any caps-word related keys
                    for (key, value) in json {
                        if key.lowercased().contains("caps") || "\(value)".lowercased().contains("caps") {
                            print("[TCP] 🅰 Caps-word key found: \(key) = \(value)")
                        }
                    }
                }
            } else {
                print("[TCP] 🔍 Non-JSON message: \(line)")
            }
        }
    }
}

// MARK: - Key Visual Components (using chromeless.swift styling)

enum TemporaryKeyState {
    case capsWordActive
    case layerHeld
    case none
    
    var backgroundColor: (active: [Color], inactive: [Color]) {
        switch self {
        case .capsWordActive:
            // Light blue gradient for caps-word
            return (
                active: [Color(hex: "87CEEB"), Color(hex: "4682B4")], // SkyBlue to SteelBlue
                inactive: [Color(hex: "B0E0E6"), Color(hex: "87CEEB")] // PowderBlue to SkyBlue
            )
        case .layerHeld:
            // Purple gradient for layer keys
            return (
                active: [Color(hex: "DDA0DD"), Color(hex: "9370DB")], // Plum to MediumPurple
                inactive: [Color(hex: "E6E6FA"), Color(hex: "DDA0DD")] // Lavender to Plum
            )
        case .none:
            // Default styling (will be ignored)
            return (active: [], inactive: [])
        }
    }
    
    var borderColor: (active: Color, inactive: Color) {
        switch self {
        case .capsWordActive:
            return (active: Color(hex: "4169E1"), inactive: Color(hex: "87CEEB")) // RoyalBlue to SkyBlue
        case .layerHeld:
            return (active: Color(hex: "8A2BE2"), inactive: Color(hex: "DDA0DD")) // BlueViolet to Plum
        case .none:
            return (active: Color.clear, inactive: Color.clear)
        }
    }
}

struct KeyCap: View {
    let label: String
    let symbol: String?
    let isArrow: Bool
    let isActive: Bool
    let arrowDirection: String? // "left", "right", "up", "down" for arrow keys
    let temporaryState: TemporaryKeyState? // For special temporary states like caps-word

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
                        .foregroundColor(isActive ? .white : arrowSymbolColor)
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
                    .foregroundColor(isActive ? .white : arrowLabelColor)
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
                if let tempState = temporaryState, tempState != .none {
                    // Use temporary state styling (like caps-word light blue)
                    let colors = tempState.backgroundColor
                    LinearGradient(
                        gradient: Gradient(colors: isActive ? colors.active : colors.inactive),
                        startPoint: .top, endPoint: .bottom
                    )
                } else if isArrow {
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(white: 0.22), Color(white: 0.13)]),
                            startPoint: .top, endPoint: .bottom
                        )
                        .opacity(0.7)
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "F9F8F8"), Color(hex: "D0CFCF")]),
                            startPoint: .top, endPoint: .bottom
                        )
                        .opacity(0.3)
                    }
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
                if let tempState = temporaryState, tempState != .none {
                    // Use temporary state border colors
                    let borderColors = tempState.borderColor
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? borderColors.active : borderColors.inactive, lineWidth: 3)
                } else if isArrow {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.white.opacity(0.7) : Color.black.opacity(0.4), lineWidth: 1)
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
        // Modifier key tilt and blur animation
        .modifier(ModifierKeyTiltBlur(isActive: isActive, isArrow: isArrow))
        // Arrow key tilt and invert effect
        .modifier(ArrowKeyTiltInvert(isActive: isActive, isArrow: isArrow, arrowDirection: arrowDirection))
    }
}

// Custom view modifier for modifier key tilt and blur
struct ModifierKeyTiltBlur: ViewModifier {
    let isActive: Bool
    let isArrow: Bool
    func body(content: Content) -> some View {
        if isArrow {
            content
        } else {
            content
                .rotation3DEffect(
                    .degrees(isActive ? 30 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center
                )
                .blur(radius: isActive ? 2.4 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
    }
}

// Custom view modifier for arrow key tilt and color invert
struct ArrowKeyTiltInvert: ViewModifier {
    let isActive: Bool
    let isArrow: Bool
    let arrowDirection: String?
    func body(content: Content) -> some View {
        if isArrow {
            let tilt: Double = isActive ? 30 : 0
            let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
            switch arrowDirection {
            case "left":
                axis = (x: 0, y: -1, z: 0)
            case "right":
                axis = (x: 0, y: 1, z: 0)
            case "up":
                axis = (x: 1, y: 0, z: 0)
            case "down":
                axis = (x: -1, y: 0, z: 0)
            default:
                axis = (x: 1, y: 0, z: 0)
            }
            return AnyView(
                content
                    .rotation3DEffect(
                        .degrees(tilt),
                        axis: axis,
                        anchor: .center
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            )
        } else {
            return AnyView(content)
        }
    }
}

// Keyboard layout structure
struct KeyboardRow {
    let keys: [String]
    let spacing: CGFloat
    let leftPadding: CGFloat
}

struct KeyboardLayout {
    static let qwertyRow = KeyboardRow(
        keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        spacing: 8, leftPadding: 25
    )
    
    static let homeRow = KeyboardRow(
        keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"],
        spacing: 8, leftPadding: 38
    )
    
    static let bottomRow = KeyboardRow(
        keys: ["z", "x", "c", "v", "b", "n", "m"],
        spacing: 8, leftPadding: 65
    )
    
    static let arrowKeys = ["left", "down", "up", "right"]
}

// MARK: - Main Dashboard View

struct LearnKeysView: View {
    @StateObject private var configParser = KanataConfigParser()
    @StateObject private var tcpClient = KanataTCPClient()
    @StateObject private var keyMonitor = GlobalKeyMonitor()
    
    @State private var config = KanataConfig()
    
    private let configPath: String
    
    init(configPath: String) {
        self.configPath = configPath
    }
    
    var currentLayerKeys: [String] {
        config.layers[tcpClient.currentLayer] ?? []
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            headerView
            
            // Animated letter row (always shown)
            animatedLetterRow
            
            // Key Layout
            if !config.defsrc.isEmpty {
                keyboardLayout
            } else {
                emptyStateView
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
            tcpClient.connect()
            loadConfigFromPath()
            setupLayerChangeListener()
        }
        .onDisappear {
            tcpClient.disconnect()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LearnKeys")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(URL(fileURLWithPath: configPath).lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Layer: \(tcpClient.currentLayer)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Circle()
                    .fill(tcpClient.isConnected ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text(tcpClient.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private var animatedLetterRow: some View {
        let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let smallFontSize: CGFloat = 60
        let largeFontSize: CGFloat = 120
        let overlayScale: CGFloat = 1.25
        let overlayFrameHeight: CGFloat = 160
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
                ZStack {
                    GeometryReader { geo in
                        // Only show the small letter if not active (not animating in overlay)
                        if !isLetterActive(letter) {
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
    
    private func overlayAnimatedLetters(letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat,
                                       largeFontSize: CGFloat, overlayScale: CGFloat, 
                                       overlayFrameHeight: CGFloat, drawWidth: CGFloat) -> some View {
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        return ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let letter = pair.element
                let isActive = isLetterActive(letter)
                
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
    
    private var keyboardLayout: some View {
        VStack(spacing: 16) {
            // Layer indicator
            if tcpClient.currentLayer != "base" {
                Text("Layer: \(tcpClient.currentLayer)")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                if tcpClient.currentLayer == "base" {
                    // Base layer: show only modifier keys in a compact row
                    modifierOnlyRow()
                } else {
                    // Other layers: show only non-transparent keys
                    nonTransparentKeysLayout()
                }
            }
            .padding(.top, 20)
        }
    }
    
    private func keyboardRow(_ row: KeyboardRow) -> some View {
        HStack(spacing: row.spacing) {
            Spacer().frame(width: row.leftPadding)
            
            ForEach(row.keys, id: \.self) { physicalKey in
                keyForPosition(physicalKey: physicalKey, isArrow: false)
            }
            
            Spacer()
        }
    }
    
    private func spacebarKey() -> some View {
        keyForPosition(physicalKey: "spc", isArrow: false)
    }
    
    private func modifierOnlyRow() -> some View {
        VStack(spacing: 12) {
            // Main home row modifiers aligned under letters
            alignedModifierRow()
            
            // Additional row for non-home-row keys like B
            additionalKeysRow()
        }
    }
    
    private func alignedModifierRow() -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        // Define modifier mappings for home row  
        let modifierMappings: [String: String] = [
            "a": "shift",
            "s": "control", 
            "d": "option",
            "f": "layer",
            "g": "command",
            "j": "rcommand",
            "k": "roption", 
            "l": "rcontrol",
            ";": "rshift"
        ]
        
        // Add space key if it has a layer action
        var allModifierMappings = modifierMappings
        if let spaceIndex = config.defsrc.firstIndex(of: "spc"),
           spaceIndex < config.layers["base"]?.count ?? 0,
           let baseLayer = config.layers["base"],
           baseLayer[spaceIndex].hasPrefix("@") {
            let aliasName = String(baseLayer[spaceIndex].dropFirst())
            if let alias = config.aliases[aliasName], alias.isLayer {
                allModifierMappings["spc"] = "layer"
            }
        }
        
        // Add ESC key if it has a caps-word action
        if let escIndex = config.defsrc.firstIndex(of: "esc"),
           escIndex < config.layers["base"]?.count ?? 0,
           let baseLayer = config.layers["base"],
           baseLayer[escIndex].hasPrefix("@") {
            let aliasName = String(baseLayer[escIndex].dropFirst())
            if let alias = config.aliases[aliasName], alias.holdAction == "caps-word" {
                allModifierMappings["esc"] = "caps-word"
            }
        }
        
        return ZStack {
            // Background for modifier groups
            modifierBackground(letters: letters, modifierMappings: allModifierMappings, slotWidth: slotWidth, slotSpacing: slotSpacing)
            
            // Position each modifier under its corresponding letter
            ForEach(letters, id: \.self) { letter in
                if let action = allModifierMappings[letter.lowercased()],
                   let letterIndex = letters.firstIndex(of: letter.lowercased()) {
                    modifierKeyForAction(action, physicalKey: letter)
                        .position(
                            x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                            y: 36 // Half height of the key
                        )
                }
            }
            
            // Add space key if it has a layer action (positioned below the home row)
            if allModifierMappings["spc"] != nil {
                modifierKeyForAction("layer", physicalKey: "spc")
                    .position(
                        x: CGFloat(letters.count / 2) * (slotWidth + slotSpacing) + slotWidth / 2,
                        y: 120 // Below the home row
                    )
            }
            
            // Add ESC key if it has a caps-word action (positioned above the home row)
            if allModifierMappings["esc"] != nil {
                modifierKeyForAction("caps-word", physicalKey: "esc")
                    .position(
                        x: CGFloat(0) * (slotWidth + slotSpacing) + slotWidth / 2, // Position above 'A'
                        y: -50 // Above the home row
                    )
            }
        }
        .frame(width: totalWidth, height: {
            var height: CGFloat = 72 // Base height
            if allModifierMappings["spc"] != nil { height = 150 } // Space below
            if allModifierMappings["esc"] != nil { height = max(height, 122) } // ESC above (72 + 50)
            return height
        }())
    }
    
    private func modifierBackground(letters: [String], modifierMappings: [String: String], slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        // Find positions of keys that have modifiers
        let modifierPositions = letters.enumerated().compactMap { index, letter -> Int? in
            modifierMappings[letter.lowercased()] != nil ? index : nil
        }
        
        // Group consecutive positions, separated by hand (based on actual key positions)
        let groups = groupConsecutivePositionsByHand(modifierPositions, letters: letters)
        let horizontalPadding: CGFloat = 45 // Half of chromeless.swift's 90px total padding
        let keyHeight: CGFloat = 72
        let backgroundHeight: CGFloat = keyHeight + 32 // Match chromeless.swift padding
        
        return ZStack {
            ForEach(groups, id: \.self) { group in
                if group.count > 1 { // Only show background if more than 1 key in group (modifiers look better grouped)
                    let startPos = group.first!
                    let endPos = group.last!
                    
                    // Calculate actual positions with proper width
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
    
    private func additionalKeysRow() -> some View {
        let letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]
        let slotWidth: CGFloat = 64
        let slotSpacing: CGFloat = 64 * 1.2
        let totalWidth = CGFloat(letters.count) * slotWidth + CGFloat(letters.count - 1) * slotSpacing
        
        // Keys that aren't in home row but appear in layers, positioned under closest home row key
        // Exclude keys already shown in alignedModifierRow to prevent duplicates
        let additionalKeys = getNonHomeRowKeys().filter { key in
            !isKeyAlreadyShownInModifierRow(key.physicalKey)
        }
        
        if additionalKeys.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack {
                // Background for additional keys
                backgroundForAdditionalKeys(additionalKeys, letters: letters, slotWidth: slotWidth, slotSpacing: slotSpacing)
                
                // Position each additional key under closest home row position
                ForEach(additionalKeys, id: \.physicalKey) { key in
                    let closestPosition = findClosestHomeRowPosition(for: key.physicalKey)
                    if let letterIndex = letters.firstIndex(of: closestPosition) {
                        modifierStyleNavigationKey(physicalKey: key.physicalKey, layerKey: key.layerKey, alias: key.alias)
                            .position(
                                x: CGFloat(letterIndex) * (slotWidth + slotSpacing) + slotWidth / 2,
                                y: 36
                            )
                    }
                }
            }
            .frame(width: totalWidth, height: 72)
        )
    }
    
    private func getNonHomeRowKeys() -> [(physicalKey: String, layerKey: String, alias: KanataAlias?)] {
        let homeRowKeys = Set(["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"])
        return getNonTransparentKeys().filter { !homeRowKeys.contains($0.physicalKey.lowercased()) }
    }
    
    private func isKeyAlreadyShownInModifierRow(_ physicalKey: String) -> Bool {
        // Check if this key is already shown in alignedModifierRow
        let homeRowKeys = Set(["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"])
        
        // Home row keys with modifiers
        if homeRowKeys.contains(physicalKey.lowercased()) {
            return true
        }
        
        // Check if space key is shown as a layer key in modifier row
        if physicalKey.lowercased() == "spc" {
            if let spaceIndex = config.defsrc.firstIndex(of: "spc"),
               spaceIndex < config.layers["base"]?.count ?? 0,
               let baseLayer = config.layers["base"],
               baseLayer[spaceIndex].hasPrefix("@") {
                let aliasName = String(baseLayer[spaceIndex].dropFirst())
                if let alias = config.aliases[aliasName], alias.isLayer {
                    return true // Space is already shown in alignedModifierRow
                }
            }
        }
        
        return false
    }
    
    private func findClosestHomeRowPosition(for key: String) -> String {
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
            
            // Function keys (distributed across home row)
            "f1": "a", "f2": "s", "f3": "d", "f4": "f", "f5": "g", "f6": "g",
            "f7": "h", "f8": "h", "f9": "j", "f10": "k", "f11": "l", "f12": ";",
            
            // Navigation keys (clustered on right side)
            "left": "j", "right": "l", "up": "k", "down": "k",
            "home": "j", "end": "l", "pgup": "k", "pgdn": "k",
            "ins": "j", "del": "l",
            
            // Modifier keys (based on typical hand usage)
            "lshift": "a", "rshift": ";", "shift": "a",
            "lctrl": "a", "rctrl": ";", "ctrl": "a", "control": "a",
            "lalt": "s", "ralt": "l", "alt": "s", "option": "s",
            "lcmd": "f", "rcmd": "j", "cmd": "f", "command": "f",
            "lmet": "f", "rmet": "j", "met": "f",
            "lwin": "f", "rwin": "j", "win": "f",
            
            // Right-hand modifiers (kanata style)  
            "rcontrol": "l", "roption": "k", "rcommand": "j",
            "rsft": ";", "lsft": "a",
            
            // Special keys
            "spc": "g", "space": "g",
            "enter": "l", "return": "l", "ret": "l",
            "tab": "a", "caps": "a", "capslock": "a",
            "esc": "a", "escape": "a",
            "backspace": ";", "bspc": ";",
            
            // Symbols and punctuation (based on physical position)
            "'": ";", "\"": ";", "grv": "a",
            
            // Shifted number symbols
            "~": "a", "!": "a", "@": "s", "#": "d", "$": "f", "%": "g",
            "^": "h", "&": "j", "*": "k", "(": "l", ")": ";",
            "_": ";", "+": ";",
            
            // Bracket and delimiter symbols
            "{": ";", "}": ";", "|": ";",
            ":": ";", "<": "k", ">": "l", "?": ";",
            
            // Numpad keys (mapped to right side)
            "kp0": "j", "kp1": "j", "kp2": "k", "kp3": "l",
            "kp4": "j", "kp5": "k", "kp6": "l",
            "kp7": "j", "kp8": "k", "kp9": "l",
            "kpdot": "l", "kpplus": "l", "kpminus": "l",
            "kpasterisk": "k", "kpslash": "j", "kpenter": "l",
            "nlck": "j", "slck": "l", "pause": ";",
            
            // Mouse buttons
            "mlft": "f", "mrgt": "j", "mmid": "g",
            "mback": "d", "mfwd": "k", "wheelup": "k", "wheeldown": "k",
            
            // Media and system keys (spread across right side)
            "mute": "j", "vold": "k", "volu": "l",
            "prev": "j", "play": "k", "next": "l",
            "stop": "k", "eject": "l",
            "mail": "j", "calc": "k", "www": "l",
            
            // Brightness and system
            "brid": "j", "briu": "k",
            "prnt": "k", "sclk": "l",
            
            // Additional common keys
            "menu": "l", "comp": "l", "app": "l",
            "pwr": "g", "slp": "g", "wake": "g",
            
            // International/variant keys
            "102d": ";", "intl": ";", "lang1": "h", "lang2": "j",
            "muhenkan": "h", "henkan": "j", "kana": "k",
            
            // Gaming keys
            "scroll": "l", "numlock": "j"
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
    
    private func backgroundForAdditionalKeys(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)], letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
        let keyPositions = keys.compactMap { key -> Int? in
            let closestPosition = findClosestHomeRowPosition(for: key.physicalKey)
            return letters.firstIndex(of: closestPosition)
        }.sorted()
        
        // Group consecutive positions, separated by hand (based on actual key positions)
        let groups = groupConsecutivePositionsByHand(keyPositions, letters: letters)
        let horizontalPadding: CGFloat = 45 // Half of chromeless.swift's 90px total padding
        let keyHeight: CGFloat = 72
        let backgroundHeight: CGFloat = keyHeight + 32 // Match chromeless.swift padding
        
        return ZStack {
            ForEach(groups, id: \.self) { group in
                if !group.isEmpty { // Show background for any group (even single keys)
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
    
    private func nonTransparentKeysLayout() -> some View {
        let nonTransparentKeys = getNonTransparentKeys()
        
        if nonTransparentKeys.isEmpty {
            return AnyView(
                Text("No active mappings in \(tcpClient.currentLayer) layer")
                    .foregroundColor(.gray)
                    .padding()
            )
        }
        
        return AnyView(
            VStack(spacing: 16) {
                // Group keys by type for better layout
                let arrowKeys = nonTransparentKeys.filter { isArrowKey($0.physicalKey) }
                let navigationKeys = nonTransparentKeys.filter { !isArrowKey($0.physicalKey) }
                
                // Navigation keys (like hjkl for arrows, etc.)
                if !navigationKeys.isEmpty {
                    navigationKeysSection(navigationKeys)
                }
                
                // Arrow keys
                if !arrowKeys.isEmpty {
                    arrowKeysSection(arrowKeys)
                }
            }
            .padding(.top, 20)
        )
    }
    
    private func getNonTransparentKeys() -> [(physicalKey: String, layerKey: String, alias: KanataAlias?)] {
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
    
    private func isTransparentKey(layerKey: String, physicalKey: String) -> Bool {
        return layerKey == "_" || 
               layerKey.isEmpty || 
               layerKey == physicalKey
    }
    
    private func isArrowKey(_ key: String) -> Bool {
        return ["left", "right", "up", "down"].contains(key.lowercased())
    }
    
    private func navigationKeysSection(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
        VStack(spacing: 8) {
            Text("Navigation")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Position buttons directly under corresponding letters
            alignedNavigationButtons(keys)
        }
    }
    
    private func alignedNavigationButtons(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
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
                            y: 36 // Half height of the key
                        )
                }
            }
        }
        .frame(width: totalWidth, height: 72)
    }
    
    private func backgroundForActiveKeys(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)], letters: [String], slotWidth: CGFloat, slotSpacing: CGFloat) -> some View {
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
    
    private func groupConsecutivePositions(_ positions: [Int]) -> [[Int]] {
        guard !positions.isEmpty else { return [] }
        
        var groups: [[Int]] = []
        var currentGroup: [Int] = [positions[0]]
        
        for index in 1..<positions.count {
            if positions[index] == positions[index-1] + 1 {
                currentGroup.append(positions[index])
            } else {
                groups.append(currentGroup)
                currentGroup = [positions[index]]
            }
        }
        groups.append(currentGroup)
        
        return groups
    }
    
    private func groupConsecutivePositionsByHand(_ positions: [Int], letters: [String]) -> [[Int]] {
        guard !positions.isEmpty else { return [] }
        
        // Dynamically determine hand boundary based on the middle of the available letters
        let handBoundary = letters.count / 2 // Split at middle position
        
        // Separate positions by hand
        let leftHandPositions = positions.filter { $0 < handBoundary }
        let rightHandPositions = positions.filter { $0 >= handBoundary }
        
        // Group consecutive positions within each hand
        let leftGroups = groupConsecutivePositions(leftHandPositions)
        let rightGroups = groupConsecutivePositions(rightHandPositions)
        
        return leftGroups + rightGroups
    }
    
    private func arrowKeysSection(_ keys: [(physicalKey: String, layerKey: String, alias: KanataAlias?)]) -> some View {
        VStack(spacing: 8) {
            Text("Arrow Keys")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Position arrow keys directly under corresponding letters
            alignedNavigationButtons(keys)
        }
    }
    
    private func keyForMappedKey(physicalKey: String, layerKey: String, alias: KanataAlias?) -> some View {
        let displayText: String
        let symbol: String?
        
        if layerKey.hasPrefix("@"), let alias = alias {
            print("DEBUG: Mapping alias '\(layerKey)' -> '\(alias.definition)' for key '\(physicalKey)'")
            // For aliases, check if they resolve to arrow directions
            switch alias.definition.lowercased() {
            case "left": displayText = "←"; symbol = nil
            case "right": displayText = "→"; symbol = nil
            case "up": displayText = "↑"; symbol = nil
            case "down": displayText = "↓"; symbol = nil
            case "pgup": displayText = "⇞"; symbol = nil
            case "pgdn": displayText = "⇟"; symbol = nil
            case "esc": displayText = "⎋"; symbol = nil
            case "spc": displayText = "⎵"; symbol = nil
            default: displayText = alias.definition.uppercased(); symbol = nil
            }
        } else {
            print("DEBUG: Mapping direct key '\(layerKey)' for physical key '\(physicalKey)'")
            switch layerKey.lowercased() {
            case "left": displayText = "←"; symbol = nil
            case "right": displayText = "→"; symbol = nil
            case "up": displayText = "↑"; symbol = nil
            case "down": displayText = "↓"; symbol = nil
            case "pgup": displayText = "⇞"; symbol = nil
            case "pgdn": displayText = "⇟"; symbol = nil
            case "esc": displayText = "⎋"; symbol = nil
            case "spc": displayText = "⎵"; symbol = nil
            default: displayText = layerKey.uppercased(); symbol = nil
            }
        }
        
        return VStack(spacing: 2) {
            // Physical key label (small, on top)
            Text(physicalKey.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
            
            // Mapped action (main display)
            KeyCap(
                label: displayText,
                symbol: symbol,
                isArrow: displayText.count == 1 && ["←", "→", "↑", "↓"].contains(displayText),
                isActive: keyMonitor.activeKeys.contains(physicalKey.lowercased()),
                arrowDirection: displayText == "←" ? "left" : displayText == "→" ? "right" : displayText == "↑" ? "up" : displayText == "↓" ? "down" : nil,
                temporaryState: nil
            )
        }
    }
    
    private func modifierKeyForAction(_ action: String, physicalKey: String) -> some View {
        // Check if this modifier is currently active
        var isActive = keyMonitor.activeModifiers.contains(action.lowercased()) || 
                      keyMonitor.activeKeys.contains(physicalKey.lowercased())
        
        // Special case for layer key - check layer key activity
        if action.lowercased() == "layer" {
            isActive = isActive || keyMonitor.activeLayerKeys.contains("layer") ||
                      (keyMonitor.activeKeys.contains("f") && tcpClient.currentLayer != "base") ||
                      (keyMonitor.activeKeys.contains("spc") && tcpClient.currentLayer != "base")
        }
        
        let displayText: String
        let symbol: String
        
        switch action.lowercased() {
        case "shift", "rshift":
            displayText = physicalKey.uppercased()  // Show physical key (A or ;)
            symbol = "⇧"
        case "control", "rcontrol":
            displayText = physicalKey.uppercased()  // Show physical key (S or L)
            symbol = "⌃"
        case "option", "roption":
            displayText = physicalKey.uppercased()  // Show physical key (D or K)
            symbol = "⌥"
        case "command", "rcommand":
            displayText = physicalKey.uppercased()  // Show physical key (G or J)
            symbol = "⌘"
        case "layer":
            // Handle space key special case
            if physicalKey.lowercased() == "spc" {
                displayText = "space"
                symbol = "⎵"
            } else {
                displayText = physicalKey.uppercased()  // Show physical key (F)
                symbol = "☰"
            }
        case "caps-word":
            displayText = physicalKey.uppercased()  // Show physical key (ESC)
            symbol = "⇪"  // Caps lock symbol for caps-word
            // Show as active when caps-word mode is active, not just when key is pressed
            isActive = isActive || keyMonitor.isCapsWordActive
        default:
            displayText = physicalKey.uppercased()  // Default to physical key
            symbol = "◊"
        }
        
        // Determine temporary state for special keys
        let temporaryState: TemporaryKeyState?
        if action.lowercased() == "caps-word" && keyMonitor.isCapsWordActive {
            temporaryState = .capsWordActive
        } else {
            temporaryState = nil
        }
        
        return KeyCap(
            label: displayText,
            symbol: symbol,
            isArrow: false,
            isActive: isActive,
            arrowDirection: nil,
            temporaryState: temporaryState
        )
    }
    
    private func isLetterActive(_ letter: String) -> Bool {
        let physicalKey = letter.lowercased()
        
        // In base layer, check for physical key press
        if tcpClient.currentLayer == "base" {
            return keyMonitor.activeKeys.contains(physicalKey)
        }
        
        // In navigation layers, check if this letter position has a mapping and if that mapping is active
        if let srcIndex = config.defsrc.firstIndex(of: physicalKey),
           srcIndex < currentLayerKeys.count {
            let layerKey = currentLayerKeys[srcIndex]
            
            // Skip transparent keys
            if layerKey == "_" || layerKey.isEmpty {
                return keyMonitor.activeKeys.contains(physicalKey)
            }
            
            // Check if the mapped action is active
            let alias = layerKey.hasPrefix("@") ? config.aliases[String(layerKey.dropFirst())] : nil
            return isKeyActive(physicalKey: physicalKey, layerKey: layerKey, alias: alias)
        }
        
        return keyMonitor.activeKeys.contains(physicalKey)
    }
    
    private func isKeyActive(physicalKey: String, layerKey: String, alias: KanataAlias?) -> Bool {
        // In base layer, check for physical key press
        if tcpClient.currentLayer == "base" {
            return keyMonitor.activeKeys.contains(physicalKey.lowercased())
        }
        
        // In navigation layers, check for the transformed key press
        let resolvedAction: String
        if layerKey.hasPrefix("@") {
            let aliasName = String(layerKey.dropFirst())
            if let alias = alias {
                resolvedAction = alias.definition
            } else {
                // Fallback patterns
                switch aliasName {
                case "fnav_h": resolvedAction = "left"
                case "fnav_j": resolvedAction = "down"
                case "fnav_k": resolvedAction = "up"
                case "fnav_l": resolvedAction = "right"
                case "fnav_b": resolvedAction = "a-left"
                case "fnav_w": resolvedAction = "a-right"
                default: resolvedAction = layerKey
                }
            }
        } else {
            resolvedAction = layerKey
        }
        
        // Map transformed actions to the keys that kanata actually sends
        switch resolvedAction.lowercased() {
        case "left":
            return keyMonitor.activeKeys.contains("left")
        case "right":
            return keyMonitor.activeKeys.contains("right")
        case "up":
            return keyMonitor.activeKeys.contains("up")
        case "down":
            return keyMonitor.activeKeys.contains("down")
        case "a-left", "a-right", "m-left", "m-right":
            // For complex key combinations, we might need to check physical key too
            return keyMonitor.activeKeys.contains(physicalKey.lowercased())
        default:
            return keyMonitor.activeKeys.contains(physicalKey.lowercased())
        }
    }
    
    private func modifierStyleNavigationKey(physicalKey: String, layerKey: String, alias: KanataAlias?) -> some View {
        let isActive = isKeyActive(physicalKey: physicalKey, layerKey: layerKey, alias: alias)
        let resolvedAction = resolveKeyAction(layerKey: layerKey, alias: alias)
        let (displayText, symbol) = getDisplayTextAndSymbol(for: resolvedAction)
        
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
    
    private func resolveKeyAction(layerKey: String, alias: KanataAlias?) -> String {
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
                case "fnav_h": return "left"
                case "fnav_j": return "down"
                case "fnav_k": return "up"
                case "fnav_l": return "right"
                case "fnav_b": return "a-left"
                case "fnav_w": return "a-right"
                default: return layerKey
                }
            }
        } else {
            return layerKey
        }
    }
    
    private func getDisplayTextAndSymbol(for action: String) -> (String, String) {
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
        
        // Special function keys
        case "tab": return ("tab", "⇥")
        case "enter", "ret", "return": return ("enter", "⏎")
        case "bspc", "backspace": return ("backspace", "⌫")
        case "del", "delete": return ("delete", "⌦")
        case "caps", "capslock": return ("caps", "⇪")
        
        default: return (action.uppercased(), "◉")
        }
    }
    
    private func validateDisplayText(displayText: String, symbol: String, physicalKey: String, layerKey: String, alias: KanataAlias?) -> (String, String) {
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
    
    private func arrowKeyCluster() -> some View {
        VStack(spacing: 4) {
            // Up arrow
            HStack {
                Spacer()
                keyForPosition(physicalKey: "up", isArrow: true)
                Spacer()
            }
            
            // Left, Down, Right arrows
            HStack(spacing: 8) {
                keyForPosition(physicalKey: "left", isArrow: true)
                keyForPosition(physicalKey: "down", isArrow: true)
                keyForPosition(physicalKey: "right", isArrow: true)
            }
        }
        .padding(.top, 8)
    }
    
    private func keyForPosition(physicalKey: String, isArrow: Bool = false) -> some View {
        let srcIndex = config.defsrc.firstIndex(of: physicalKey)
        let layerKey: String
        let alias: KanataAlias?
        
        if let index = srcIndex, index < currentLayerKeys.count {
            layerKey = currentLayerKeys[index]
        } else {
            layerKey = physicalKey
        }
        
        if layerKey.hasPrefix("@") {
            alias = config.aliases[String(layerKey.dropFirst())]
        } else {
            alias = nil
        }
        
        let displayText: String
        let symbol: String?
        let arrowDirection: String?
        
        if isArrow {
            // Arrow keys
            switch physicalKey.lowercased() {
            case "left":
                displayText = "←"
                symbol = nil
                arrowDirection = "left"
            case "right":
                displayText = "→" 
                symbol = nil
                arrowDirection = "right"
            case "up":
                displayText = "↑"
                symbol = nil
                arrowDirection = "up"
            case "down":
                displayText = "↓"
                symbol = nil
                arrowDirection = "down"
            default:
                displayText = physicalKey.uppercased()
                symbol = nil
                arrowDirection = nil
            }
        } else {
            // Regular keys - show the layer mapping
            if layerKey == "_" || layerKey.isEmpty {
                displayText = physicalKey.uppercased()
                symbol = nil
            } else if layerKey.hasPrefix("@"), let alias = alias {
                displayText = alias.tapAction?.uppercased() ?? physicalKey.uppercased()
                symbol = nil
            } else {
                switch layerKey.lowercased() {
                case "left": displayText = "←"; symbol = nil
                case "right": displayText = "→"; symbol = nil
                case "up": displayText = "↑"; symbol = nil
                case "down": displayText = "↓"; symbol = nil
                case "pgup": displayText = "⇞"; symbol = nil
                case "pgdn": displayText = "⇟"; symbol = nil
                case "esc": displayText = "⎋"; symbol = nil
                case "spc": displayText = "⎵"; symbol = nil
                default: displayText = layerKey.uppercased(); symbol = nil
                }
            }
            arrowDirection = nil
        }
        
        return KeyCap(
            label: displayText,
            symbol: symbol,
            isArrow: isArrow,
            isActive: keyMonitor.activeKeys.contains(physicalKey.lowercased()),
            arrowDirection: arrowDirection,
            temporaryState: nil
        )
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
    
    private func loadConfigFromPath() {
        let url = URL(fileURLWithPath: configPath)
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            config = configParser.parseConfig(from: content)
            print("Loaded config '\(configPath)' with \(config.layers.count) layers")
            
            // Build dynamic modifier map from config
            updateModifierMapping()
        } catch {
            print("Error loading config '\(configPath)': \(error)")
            NSApp.terminate(nil)
        }
    }
    
    private func updateModifierMapping() {
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
        
        // Pass the caps-word config to the key monitor
        keyMonitor.updateCapsWordConfig(config.capsWordConfig)
        
        if let capsWordConfig = config.capsWordConfig {
            print("DEBUG: 🕒 ✅ Passed caps-word config to key monitor: tap=\(capsWordConfig.tapTimeout*1000)ms, hold=\(capsWordConfig.holdTimeout*1000)ms, duration=\(capsWordConfig.duration*1000)ms")
        } else {
            print("DEBUG: 🕒 ❌ No caps-word config found in parsed config")
        }
    }
    
    private func getSystemKeyCodeForModifier(_ modifierType: String, physicalKey: String) -> CGKeyCode? {
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
    
    private func isLeftHandKey(_ key: String) -> Bool {
        // Home row keys: left hand is a,s,d,f,g and right hand is h,j,k,l,;
        let leftHandKeys = Set(["a", "s", "d", "f", "g", "q", "w", "e", "r", "t", "z", "x", "c", "v", "b"])
        return leftHandKeys.contains(key.lowercased())
    }
    
    private func setupLayerChangeListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LayerChanged"),
            object: nil,
            queue: .main
        ) { notification in
            guard let newLayer = notification.object as? String else { return }
            
            // Find which physical key triggered this layer change
            let layerTriggerKey = findLayerTriggerKey(for: newLayer)
            
            if let triggerKey = layerTriggerKey {
                // Animate the layer trigger key for a short duration
                keyMonitor.updateLayerKeyState(physicalKey: triggerKey, isActive: true, layerType: "layer")
                
                // Auto-release the animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    keyMonitor.updateLayerKeyState(physicalKey: triggerKey, isActive: false, layerType: "layer")
                }
            }
        }
    }
    

    
    private func findLayerTriggerKey(for layerName: String) -> String? {
        // Find which key in the base layer has a layer action that leads to this layer
        guard let baseLayer = config.layers["base"] else { return nil }
        
        for (index, physicalKey) in config.defsrc.enumerated() {
            if index < baseLayer.count {
                let layerKey = baseLayer[index]
                
                if layerKey.hasPrefix("@") {
                    let aliasName = String(layerKey.dropFirst())
                    if let alias = config.aliases[aliasName] {
                        if let holdAction = alias.holdAction,
                           holdAction.contains("layer") && 
                           (holdAction.contains(layerName) || layerName != "base") {
                            return physicalKey
                        }
                    }
                }
            }
        }
        
        // Fallback: F key is commonly used for navigation layer
        if layerName.contains("nav") {
            return "f"
        }
        
        return nil
    }
    
    private func getModifierTypeAndFlag(for holdAction: String, config: KanataConfig) -> (type: String, flag: CGEventFlags)? {
        print("DEBUG: getModifierTypeAndFlag called with holdAction: '\(holdAction)'")
        
        // Handle caps-word directly first (before alias resolution)
        if holdAction.lowercased() == "caps-word" {
            print("DEBUG: ✅ Detected caps-word modifier")
            return ("caps-word", CGEventFlags(rawValue: 0)) // Special flag for caps-word
        }
        
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
        case "caps-word":
            return ("caps-word", CGEventFlags(rawValue: 0)) // Special flag for caps-word
        default:
            break // Continue to alias resolution
        }
        
        // If not a built-in modifier, try resolving as alias
        let resolvedAction: String
        if holdAction.hasPrefix("@") {
            let aliasName = String(holdAction.dropFirst())
            if let alias = config.aliases[aliasName] {
                resolvedAction = alias.definition
                print("DEBUG: Resolved alias '@\(aliasName)' to '\(resolvedAction)'")
                
                // Recursively check the resolved action for modifiers
                return getModifierTypeAndFlag(for: resolvedAction, config: config)
            } else {
                resolvedAction = holdAction
                print("DEBUG: Failed to resolve alias '@\(aliasName)', using as-is")
            }
        } else {
            resolvedAction = holdAction
        }
        
        // Check if this is a layer action
        if resolvedAction.contains("layer") {
            return ("layer", CGEventFlags(rawValue: 0)) // Special flag for layer keys
        }
        
        return nil
    }
}

// MARK: - Global Key Monitor

class GlobalKeyMonitor: ObservableObject {
    @Published var activeKeys: Set<String> = []
    @Published var activeModifiers: Set<String> = []
    @Published var activeLayerKeys: Set<String> = []
    @Published var isCapsWordActive: Bool = false
    
    private var eventTap: CFMachPort?
    private var capsWordKeyMap: [String: Bool] = [:]  // Track which keys trigger caps-word
    private var capsWordTimer: Timer?
    private var testCapsWordTimer: Timer?  // For manual testing
    private var capsWordConfig: CapsWordConfig? = nil  // Dynamic config from kanata
    
    // Track unhandled keycodes for analysis
    private var unhandledKeycodes: [Int: Int] = [:]  // keycode -> count
    private var lastLogTime: Date = Date()
    
    init() {
        setupEventTap()
    }
    
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
    
    private func setupEventTap() {
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                
                // Handle Command+Q to quit the app
                if type == .keyDown && flags.contains(.maskCommand) && keyCode == 12 { // 'q' key
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                    return Unmanaged.passUnretained(event)
                }
                
                // Handle Command+W to close window and quit the app
                if type == .keyDown && flags.contains(.maskCommand) && keyCode == 13 { // 'w' key
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                    return Unmanaged.passUnretained(event)
                }
                
                // Handle Command+T to test caps-word activation
                if type == .keyDown && flags.contains(.maskCommand) && keyCode == 17 { // 't' key
                    DispatchQueue.main.async {
                        print("🧪 MANUAL TEST: Activating caps-word visual for testing")
                        monitor.testCapsWordActivation()
                    }
                    return Unmanaged.passUnretained(event)
                }
                
                // Handle Command+E for quick caps-word test
                if type == .keyDown && flags.contains(.maskCommand) && keyCode == 14 { // 'e' key
                    DispatchQueue.main.async {
                        print("🧪 QUICK TEST: Command+E pressed - testing caps-word visual")
                        monitor.quickTestCapsWord()
                    }
                    return Unmanaged.passUnretained(event)
                }
                
                // Special debug for ESC key
                if keyCode == 53 {
                    print("🚨 ESC KEY DETECTED: keycode 53, type: \(type), flags: \(flags)")
                    if let keyString = keyStringFromCode(CGKeyCode(keyCode)) {
                        print("🚨 ESC KEY MAPPED TO: '\(keyString)'")
                    } else {
                        print("🚨 ESC KEY MAPPING FAILED!")
                    }
                }
                
                // Handle modifier flag changes
                if type == .flagsChanged {
                    monitor.handleModifierChange(keyCode: CGKeyCode(keyCode), flags: flags)
                } else if let keyString = keyStringFromCode(CGKeyCode(keyCode)) {
                    DispatchQueue.main.async {
                        if type == .keyDown {
                            print("DEBUG: Key down detected: '\(keyString)' (keycode: \(keyCode))")
                            monitor.activeKeys.insert(keyString)
                            monitor.handleCapsWordKeyDown(keyString)
                        } else if type == .keyUp {
                            print("DEBUG: Key up detected: '\(keyString)' (keycode: \(keyCode))")
                            monitor.activeKeys.remove(keyString)
                            monitor.handleCapsWordKeyUp(keyString)
                        }
                    }
                } else {
                    // Log unrecognized keys with detailed information
                    if type == .keyDown || type == .keyUp {
                        let eventType = type == .keyDown ? "DOWN" : "UP"
                        print("🔍 UNHANDLED KEY EVENT: keycode \(keyCode) (\(eventType)) - Consider adding to keyStringFromCode()")
                        
                        // Add helpful suggestions for common keycodes
                        let suggestion = getKeycodeHint(Int(keyCode))
                        if !suggestion.isEmpty {
                            print("   💡 Suggestion: keycode \(keyCode) might be '\(suggestion)'")
                        }
                        
                        // Track unhandled keycodes for analysis (only on key down to avoid duplicates)
                        if type == .keyDown {
                            monitor.trackUnhandledKeycode(Int(keyCode))
                        }
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    private func handleModifierChange(keyCode: CGKeyCode, flags: CGEventFlags) {
        print("DEBUG: handleModifierChange keyCode: \(keyCode), flags: \(flags)")
        
        // Check if this is a system modifier keycode we care about (using dynamic mapping)
        if let physicalKey = systemModifierMap[keyCode] {
            print("DEBUG: Found physical key '\(physicalKey)' for system keycode \(keyCode)")
            
            // Check if this physical key has a modifier hold action in the config
            if let modifierInfo = getModifierInfoForKey(physicalKey) {
                let isActive = flags.contains(modifierInfo.flag)
                print("DEBUG: Modifier '\(modifierInfo.type)' for key '\(physicalKey)' is \(isActive ? "active" : "inactive")")
                print("DEBUG: Flag check: flags \(flags.rawValue) contains \(modifierInfo.flag.rawValue) = \(isActive)")
                
                DispatchQueue.main.async {
                    if isActive {
                        self.activeModifiers.insert(modifierInfo.type)
                        self.activeKeys.insert(physicalKey)
                        print("DEBUG: ✅ Activated modifier '\(modifierInfo.type)' and key '\(physicalKey)'")
                    } else {
                        self.activeModifiers.remove(modifierInfo.type)
                        self.activeKeys.remove(physicalKey)
                        print("DEBUG: ❌ Deactivated modifier '\(modifierInfo.type)' and key '\(physicalKey)'")
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
        // This will be set from the main view when config is loaded
        return modifierKeyMap[physicalKey]
    }
    
    private var modifierKeyMap: [String: (type: String, flag: CGEventFlags)] = [:]
    private var systemModifierMap: [CGKeyCode: String] = [:]
    
    func updateModifierMap(_ map: [String: (type: String, flag: CGEventFlags)]) {
        modifierKeyMap = map
        
        // Extract caps-word keys from the modifier map
        capsWordKeyMap.removeAll()
        for (physicalKey, modifierInfo) in map {
            if modifierInfo.type == "caps-word" {
                capsWordKeyMap[physicalKey] = false
                print("DEBUG: Registered caps-word key: \(physicalKey)")
            }
        }
    }
    
    func updateSystemModifierMap(_ map: [CGKeyCode: String]) {
        systemModifierMap = map
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
    
    func handleCapsWordKeyDown(_ keyString: String) {
        print("DEBUG: handleCapsWordKeyDown called with key: '\(keyString)'")
        print("DEBUG: Registered caps-word keys: \(Array(capsWordKeyMap.keys))")
        
        // Check if this key is configured for caps-word
        if capsWordKeyMap.keys.contains(keyString) {
            print("DEBUG: ✅ Caps-word key '\(keyString)' pressed, starting hold detection")
            capsWordKeyMap[keyString] = true
            
            // Record the press time for debugging
            let pressTime = Date()
            
            // Use dynamic timing from kanata config, fallback to reasonable defaults
            // TEMPORARILY reduce hold timeout for easier testing
            let configHoldTimeout = capsWordConfig?.holdTimeout ?? 0.2
            let holdTimeout = min(configHoldTimeout, 0.1)  // Use 100ms for easier testing
            
            print("DEBUG: 🕒 Using hold timeout: \(holdTimeout*1000)ms (reduced from \(configHoldTimeout*1000)ms for testing)")
            
            // Start timer to detect hold behavior using kanata config timing
            capsWordTimer?.invalidate()
            capsWordTimer = Timer.scheduledTimer(withTimeInterval: holdTimeout, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    let holdDuration = Date().timeIntervalSince(pressTime) * 1000
                    // If key is still being held after the timeout, activate caps-word visual
                    print("DEBUG: 🕒 Hold timer triggered for '\(keyString)' after \(holdTimeout*1000)ms (actual hold: \(String(format: "%.1f", holdDuration))ms)")
                    print("DEBUG: 🔍 capsWordKeyMap[\(keyString)] = \(self?.capsWordKeyMap[keyString] ?? false)")
                    print("DEBUG: 🔍 activeKeys.contains(\(keyString)) = \(self?.activeKeys.contains(keyString) ?? false)")
                    print("DEBUG: 🔍 Current activeKeys: \(self?.activeKeys ?? [])")
                    
                    if self?.capsWordKeyMap[keyString] == true && self?.activeKeys.contains(keyString) == true {
                        print("DEBUG: ✅ CAPS-WORD VISUAL ACTIVATED from key '\(keyString)' - hold timeout reached!")
                        self?.activateCapsWord()
                    } else {
                        print("DEBUG: ❌ Caps-word NOT activated - key released before timeout")
                        if self?.capsWordKeyMap[keyString] != true {
                            print("DEBUG:    → capsWordKeyMap[\(keyString)] was reset to false (key released)")
                        }
                        if self?.activeKeys.contains(keyString) != true {
                            print("DEBUG:    → key '\(keyString)' not in activeKeys (key released)")
                        }
                    }
                }
            }
        } else {
            print("DEBUG: ❌ Key '\(keyString)' not registered for caps-word")
        }
    }
    
    func handleCapsWordKeyUp(_ keyString: String) {
        print("DEBUG: handleCapsWordKeyUp called with key: '\(keyString)'")
        
        // Check if this key is configured for caps-word
        if capsWordKeyMap.keys.contains(keyString) {
            let releaseTime = Date()
            print("DEBUG: ✅ Caps-word key '\(keyString)' released")
            capsWordKeyMap[keyString] = false
            capsWordTimer?.invalidate()
        } else {
            print("DEBUG: ❌ Key '\(keyString)' not registered for caps-word")
        }
    }
    
    private func activateCapsWord() {
        isCapsWordActive = true
        print("DEBUG: 🅰 CAPS-WORD VISUAL MODE ACTIVATED")
        
        // Use dynamic duration from kanata config, fallback to reasonable default
        let duration = capsWordConfig?.duration ?? 2.0  // Default 2000ms
        print("DEBUG: 🕒 Setting \(duration*1000)ms auto-deactivation timer from \(capsWordConfig != nil ? "kanata config" : "default")")
        
        // Set up auto-deactivation timer using kanata config timing
        capsWordTimer?.invalidate()
        capsWordTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("DEBUG: 🕒 \(duration*1000)ms timer expired - auto-deactivating caps-word visual")
                self?.deactivateCapsWord()
            }
        }
    }
    
    private func deactivateCapsWord() {
        isCapsWordActive = false
        print("DEBUG: 🅰 CAPS-WORD VISUAL MODE DEACTIVATED")
        print("DEBUG: 🔍 Deactivation source: \(Thread.callStackSymbols.first ?? "unknown")")
        capsWordTimer?.invalidate()
    }
    
    func trackUnhandledKeycode(_ keyCode: Int) {
        unhandledKeycodes[keyCode, default: 0] += 1
        
        // Log summary every 30 seconds
        let now = Date()
        if now.timeIntervalSince(lastLogTime) >= 30.0 {
            logUnhandledKeycodeSummary()
            lastLogTime = now
        }
    }
    
    private func logUnhandledKeycodeSummary() {
        guard !unhandledKeycodes.isEmpty else { return }
        
        print("\n📊 UNHANDLED KEYCODE SUMMARY (last 30 seconds):")
        print("   Total unhandled keycodes: \(unhandledKeycodes.count)")
        
        // Sort by frequency (most common first)
        let sortedKeycodes = unhandledKeycodes.sorted { $0.value > $1.value }
        
        print("   Most frequent unhandled keys:")
        for (keycode, count) in sortedKeycodes.prefix(5) {
            let hint = getKeycodeHint(keycode)
            let hintText = hint.isEmpty ? "unknown key" : hint
            print("     • Keycode \(keycode): \(count) presses (\(hintText))")
        }
        
        // Suggest which keys to add next
        let topKeycodes = sortedKeycodes.prefix(3).map { $0.key }
        if !topKeycodes.isEmpty {
            print("   🎯 Priority: Consider adding these keycodes to keyStringFromCode(): \(topKeycodes)")
        }
        
        print("")
        
        // Clear the tracking for next period
        unhandledKeycodes.removeAll()
    }
    
    func forceLogSummary() {
        print("\n🔍 MANUAL KEYCODE SUMMARY REQUEST:")
        logUnhandledKeycodeSummary()
    }
    
    // Manual caps-word testing function
    func testCapsWordActivation() {
        print("🧪 TESTING: Manually activating caps-word for 3 seconds")
        activateCapsWord()
        
        // Auto-deactivate after 3 seconds for testing
        testCapsWordTimer?.invalidate()
        testCapsWordTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("🧪 TESTING: Manually deactivating caps-word")
                self?.deactivateCapsWord()
            }
        }
    }
    
    // Quick caps-word test (shorter duration for rapid testing)
    func quickTestCapsWord() {
        print("🧪 QUICK TEST: Activating caps-word for 1 second")
        isCapsWordActive = true
        
        // Auto-deactivate after 1 second for quick testing
        testCapsWordTimer?.invalidate()
        testCapsWordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("🧪 QUICK TEST: Deactivating caps-word")
                self?.isCapsWordActive = false
            }
        }
    }
    
    func updateCapsWordConfig(_ config: CapsWordConfig?) {
        capsWordConfig = config
        if let config = config {
            print("DEBUG: 🕒 Updated caps-word config: tap=\(config.tapTimeout*1000)ms, hold=\(config.holdTimeout*1000)ms, duration=\(config.duration*1000)ms, key='\(config.triggerKey)'")
        }
    }
}

// Helper functions for key code mapping
private func mapLetterKeyCodes(_ keyCode: CGKeyCode) -> String? {
    switch keyCode {
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
    case 13: return "w"
    case 11: return "b"
    default: return nil
    }
}

private func mapArrowKeyCodes(_ keyCode: CGKeyCode) -> String? {
    switch keyCode {
    case 123: return "left"
    case 124: return "right"
    case 125: return "down"
    case 126: return "up"
    default: return nil
    }
}

private func mapSpecialKeyCodes(_ keyCode: CGKeyCode) -> String? {
    switch keyCode {
    // Numbers
    case 18: return "1"
    case 19: return "2"
    case 20: return "3"
    case 21: return "4"
    case 23: return "5"
    case 22: return "6"
    case 26: return "7"
    case 28: return "8"
    case 25: return "9"
    case 29: return "0"
    
    // QWERTY row
    case 12: return "q"
    case 13: return "w"
    case 14: return "e"
    case 15: return "r"
    case 17: return "t"
    case 16: return "y"
    case 32: return "u"
    case 34: return "i"
    case 31: return "o"
    case 35: return "p"
    
    // ZXCV row  
    case 6: return "z"
    case 7: return "x"
    case 8: return "c"
    case 9: return "v"
    case 11: return "b"
    case 45: return "n"
    case 46: return "m"
    
    // Special keys
    case 53: return "esc"    // ESC key
    case 49: return "spc"    // Space key
    case 51: return "bspc"   // Backspace
    case 36: return "ret"    // Return/Enter
    case 48: return "tab"    // Tab
    case 117: return "del"   // Delete
    case 115: return "home"  // Home
    case 119: return "end"   // End
    case 116: return "pgup"  // Page Up
    case 121: return "pgdn"  // Page Down
    
    // Punctuation and symbols
    case 27: return "-"      // Minus/hyphen
    case 24: return "="      // Equals
    case 33: return "["      // Left bracket
    case 30: return "]"      // Right bracket
    case 42: return "\\"     // Backslash
    case 39: return "'"      // Single quote
    case 41: return ";"      // Semicolon (handled in mapLetterKeyCodes but adding here too)
    case 43: return ","      // Comma
    case 47: return "."      // Period
    case 44: return "/"      // Forward slash
    case 50: return "`"      // Grave accent/backtick
    
    // Function keys
    case 122: return "f1"
    case 120: return "f2"
    case 99: return "f3"
    case 118: return "f4"
    case 96: return "f5"
    case 97: return "f6"
    case 98: return "f7"
    case 100: return "f8"
    case 101: return "f9"
    case 109: return "f10"
    case 103: return "f11"
    case 111: return "f12"
    
    default: return nil
    }
}

func keyStringFromCode(_ keyCode: CGKeyCode) -> String? {
    return mapLetterKeyCodes(keyCode) ?? 
           mapArrowKeyCodes(keyCode) ?? 
           mapSpecialKeyCodes(keyCode)
}

func getKeycodeHint(_ keyCode: Int) -> String {
    // Provide helpful hints for common unmapped keycodes
    // These are educated guesses based on common US keyboard layouts
    switch keyCode {
    // Modifier keys (these shouldn't be handled as regular keys anyway)
    case 54, 55: return "command keys (handled by modifier system)"
    case 56, 60: return "shift keys (handled by modifier system)"
    case 58, 61: return "option/alt keys (handled by modifier system)"
    case 59, 62: return "control keys (handled by modifier system)"
    case 57: return "caps lock (handled by modifier system)"
    case 63: return "fn key (system key)"
    
    // Numpad (if present)
    case 65: return "numpad decimal"
    case 67: return "numpad multiply"
    case 69: return "numpad plus"
    case 71: return "numpad clear"
    case 75: return "numpad divide"
    case 76: return "numpad enter"
    case 78: return "numpad minus"
    case 81: return "numpad equals"
    case 82: return "numpad 0"
    case 83: return "numpad 1"
    case 84: return "numpad 2"
    case 85: return "numpad 3"
    case 86: return "numpad 4"
    case 87: return "numpad 5"
    case 88: return "numpad 6"
    case 89: return "numpad 7"
    case 91: return "numpad 8"
    case 92: return "numpad 9"
    
    // System keys
    case 107: return "sysreq/print screen"
    case 113: return "scroll lock"
    case 114: return "pause/break"
    
    // Media keys
    case 144: return "brightness up"
    case 145: return "brightness down"
    case 160: return "volume up"
    case 161: return "volume down"
    case 162: return "mute"
    
    default: return ""
    }
}

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

// MARK: - App Entry Point

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