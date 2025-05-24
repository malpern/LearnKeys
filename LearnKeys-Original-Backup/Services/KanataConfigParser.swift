import Foundation

// MARK: - Kanata Config Parser Service

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
            if trimmed.isEmpty { continue }
            
            // Check for display metadata comments
            if trimmed.hasPrefix(";;DISPLAY:") {
                parseDisplayComment(trimmed, config: &config)
                continue
            }
            
            // Skip other comments
            if trimmed.hasPrefix(";;") { continue }
            
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
    
    private func parseDisplayComment(_ line: String, config: inout KanataConfig) {
        // Parse format: ;;DISPLAY: alias-name "display-text" "symbol"
        let content = String(line.dropFirst(11)) // Remove ";;DISPLAY: "
        let parts = parseQuotedString(content)
        
        guard parts.count >= 3 else {
            parseWarnings.append("Invalid display comment format: \(line)")
            return
        }
        
        let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = parts[1]
        let symbol = parts[2]
        
        let displayMapping = DisplayMapping(key: key, displayText: displayText, symbol: symbol)
        config.displayMappings[key] = displayMapping
        
        print("DEBUG: Added display mapping from comment: '\(key)' -> '\(displayText)' (\(symbol))")
    }
    
    private func parseQuotedString(_ input: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var inQuotes = false
        var index = input.startIndex
        
        while index < input.endIndex {
            let char = input[index]
            
            if char == "\"" {
                if inQuotes {
                    // End of quoted string
                    parts.append(current)
                    current = ""
                    inQuotes = false
                } else {
                    // Start of quoted string
                    inQuotes = true
                }
            } else if inQuotes {
                current.append(char)
            } else if !char.isWhitespace {
                // Non-quoted content (like the key name)
                current.append(char)
            } else if !current.isEmpty {
                // End of non-quoted content
                parts.append(current)
                current = ""
            }
            
            index = input.index(after: index)
        }
        
        // Add any remaining content
        if !current.isEmpty {
            parts.append(current)
        }
        
        return parts
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
            "layer"
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
} 