# Kanata Config Guide for LearnKeys

This guide explains how to write kanata configuration files that work optimally with the LearnKeys dynamic dashboard parser.

## Table of Contents

1. [What the Parser Currently Understands](#what-the-parser-currently-understands)
2. [⚠️ Critical Issue: Comment Handling](#️-critical-issue-comment-handling)
3. [🅰️ Caps-Word Support](#️-caps-word-support)
4. [🔄 TCP Layer Monitoring](#-tcp-layer-monitoring)
5. [Best Practices for LearnKeys Compatibility](#best-practices-for-learnkeys-compatibility)
6. [Common Issues and Solutions](#common-issues-and-solutions)
7. [Parser Implementation Notes](#parser-implementation-notes)
8. [Recent Fixes](#recent-fixes)
9. [🔍 Parser Error Reporting & Debugging](#-parser-error-reporting--debugging)
10. [Future Improvements Roadmap](#future-improvements-roadmap)
11. [Contributing to Parser Development](#contributing-to-parser-development)

---

## What the Parser Currently Understands

### ✅ Fully Supported Features

#### **Configuration Sections**
- `(defcfg ...)` - Configuration settings (parsed but not used for visualization)
- `(defsrc ...)` - Physical key layout definition
- `(deflayer name ...)` - Layer definitions with key mappings
- `(defalias ...)` - Key action aliases with tap-hold parsing
- `(defvar ...)` - Variable definitions (timing, key groups, etc.)

#### **Key Types and Actions**
- **Basic Keys**: Letters, numbers, symbols display correctly
- **Transparent Keys**: `_` keys are properly hidden from display
- **Modifier Keys**: All standard modifiers with proper symbols
  ```lisp
  lsft rsft    → ⇧ (shift)
  lctl rctl    → ⌃ (control) 
  lalt ralt    → ⌥ (option)
  lmet rmet    → ⌘ (command)
  ```
- **Navigation Keys**: Directional arrows with symbols
  ```lisp
  left  → ←
  down  → ↓  
  up    → ↑
  right → →
  ```
- **Special Keys**: Common special keys with symbols
  ```lisp
  pgup  → ⇞
  pgdn  → ⇟
  esc   → ⎋
  spc   → ⎵
  ```

#### **Tap-Hold Actions**
LearnKeys can parse and display tap-hold modifier keys:

```lisp
;; ✅ GOOD: Properly parsed tap-hold modifiers
a (tap-hold-release-keys 200 150 a lsft ())
s (tap-hold-release-keys 200 150 s lctl ())

;; ✅ GOOD: With alias references  
a (tap-hold-release-keys $tap-time $hold-time (multi a @tap) @shift $left-hand-keys)
```

The parser detects:
- **Tap Action**: The letter/key that gets pressed on tap
- **Hold Action**: The modifier or layer that activates on hold
- **Modifier Type**: Whether it's shift, control, option, command
- **Layer Type**: Whether it activates a layer instead of a modifier

#### **Layer Operations**
```lisp
;; ✅ GOOD: Layer switching keys are detected
f (tap-hold-release-keys 200 150 f (layer-toggle f-nav) ())
spc (tap-hold-release-keys 200 150 spc (layer-while-held nav) ())
```

#### **Caps-Word Actions**
```lisp
;; ✅ FULLY SUPPORTED: Caps-word with timing configuration
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
```

The parser fully supports caps-word functionality:
- **Visual State**: Shows ⇪ symbol and special light blue styling when active
- **Timing Extraction**: Automatically extracts tap, hold, and duration timings
- **Debug Support**: Comprehensive debugging for caps-word activation/deactivation
- **Real-time Monitoring**: Tracks caps-word state changes via TCP and key monitoring

### ⚠️ Partially Supported Features

#### **Complex Multi-Actions**
```lisp
;; ✅ PARSED: But only tap action shown in UI
tap (multi 
  (layer-switch nomods)
  (on-idle-fakekey to-base tap 20)
)

;; ⚠️ PARTIALLY SUPPORTED: Complex sequences not fully visualized
complex_key (multi 
  (macro "git status")
  (layer-toggle dev-tools)
)
```

#### **Variable Substitution**
```lisp
;; ✅ PARSED: Variables work in expressions
(defvar tap-time 200)
a (tap-hold-release-keys $tap-time 150 a lsft ())
```

### ❌ Not Yet Supported

#### **Advanced Kanata Features**
- `(defchords...)` and `(defchordsv2...)` - Chord definitions
- `(deffakekeys...)` - Fake key definitions  
- `(defoverrides...)` - Override definitions
- `(defseq...)` - Sequence definitions
- `(deftemplate...)` - Template definitions

#### **Complex Action Parsing**
- Multi-step actions in `(multi ...)` expressions
- Conditional actions and complex logic
- Nested parentheses beyond basic tap-hold patterns
- Advanced timing configurations

#### **Layout Analysis**
- Physical key position relationships
- Ergonomic analysis of modifier placement
- Automatic conflict detection

## ⚠️ Critical Issue: Comment Handling

**The parser currently has significant problems with comments that can cause aliases to be lost or expressions to be truncated.**

### 🚨 **Known Comment Issues**

#### **Inline Comments Break Expressions**
```lisp
;; ❌ PROBLEM: Inline comments truncate expressions
(defalias
  fnav_h left        ;; left arrow
  fnav_j down        ;; down arrow
  fnav_k up          ;; up arrow
)
;; Result: Only fnav_h gets parsed, fnav_j and fnav_k are lost!
```

#### **Comment Parsing Problems**
- **Mid-Expression Comments**: Comments inside multi-line expressions break parsing
- **Token Truncation**: Everything after `;;` in a line gets discarded
- **Expression Boundary Issues**: Comments can prevent proper parentheses matching
- **Alias Loss**: Multiple aliases on same line with comments lose everything after first comment

### ✅ **Current Safe Comment Practices**

#### **Use Full-Line Comments Only**
```lisp
;; ✅ GOOD: Full-line comments work fine
;; This is a safe comment
(defalias
  shift lsft
  control lctl
)

;; ✅ GOOD: Comments between expressions
(deflayer base
  @a @s @d @f
)

;; Another safe comment here
(deflayer f-nav
  _ _ _ _
)
```

#### **Avoid Inline Comments Completely**
```lisp
;; ❌ AVOID: Any inline comments
fnav_h left ;; This breaks parsing!

;; ❌ AVOID: Comments in multi-line expressions  
(defalias
  a (tap-hold 200 150 a lsft) ;; This truncates!
  b (tap-hold 200 150 b lctl)  ;; Never reached
)
```

### 🔧 **Workarounds Until Fixed**

#### **Structure 1: Comment Blocks Above**
```lisp
;; Navigation aliases - vim motions
;; h=left, j=down, k=up, l=right
(defalias
  fnav_h left
  fnav_j down  
  fnav_k up
  fnav_l right
)
```

#### **Structure 2: Separate Expressions**
```lisp
;; Left arrow navigation
(defalias fnav_h left)

;; Down arrow navigation  
(defalias fnav_j down)

;; Up arrow navigation
(defalias fnav_k up)

;; Right arrow navigation
(defalias fnav_l right)
```

#### **Structure 3: Group with Block Comments**
```lisp
;;
;; NAVIGATION LAYER ALIASES
;; ========================
;; Basic vim movements for F-hold layer:
;;   h -> left arrow
;;   j -> down arrow  
;;   k -> up arrow
;;   l -> right arrow
;;

(defalias
  fnav_h left
  fnav_j down
  fnav_k up
  fnav_l right
)
```

### 📋 **Comment Best Practices**

#### **1. Documentation Structure**
```lisp
;; ============================================================================
;; HOME ROW MODIFIERS CONFIGURATION
;; ============================================================================
;; 
;; Left hand modifiers:  A(shift) S(ctrl) D(option) F(layer) G(command)
;; Right hand modifiers: J(command) K(option) L(ctrl) ;(shift)
;;
;; Timing: 200ms tap, 150ms hold
;; Features: Same-hand early activation, idle timeout
;;

(defvar
  tap-time 200
  hold-time 150
)

(defalias
  a (tap-hold-release-keys $tap-time $hold-time a lsft ())
  s (tap-hold-release-keys $tap-time $hold-time s lctl ())
)
```

#### **2. Section Dividers**
```lisp
;; ===================
;; MODIFIER DEFINITIONS
;; ===================

(defalias shift lsft control lctl)

;; ===================
;; HOME ROW SETUP  
;; ===================

(defalias
  a (tap-hold-release-keys 200 150 a @shift ())
  s (tap-hold-release-keys 200 150 s @control ())
)

;; ===================
;; NAVIGATION LAYERS
;; ===================

(deflayer f-nav
  _ _ _ _ _ @fnav_h @fnav_j @fnav_k @fnav_l _
)
```

#### **3. Debug-Friendly Formatting**
```lisp
;; Single aliases per line for easier debugging
(defalias shift lsft)
(defalias control lctl) 
(defalias option lalt)
(defalias command lmet)

;; Clear separation between logical groups
(defalias a (tap-hold-release-keys 200 150 a @shift ()))
(defalias s (tap-hold-release-keys 200 150 s @control ()))
```

### 🚀 **Future Comment Support**

These comment features will be added in future parser improvements:

- **Inline Comment Support**: Proper `;;` handling mid-expression
- **Block Comments**: `/* ... */` style multi-line comments  
- **Documentation Comments**: Special `;;;` comments for auto-documentation
- **Conditional Comments**: Comments that can be toggled on/off
- **Annotation Comments**: Metadata comments for parser hints

## 🅰️ Caps-Word Support

LearnKeys provides comprehensive support for kanata's caps-word functionality with real-time visual feedback and debugging capabilities.

### ✅ **Fully Supported Caps-Word Features**

#### **Basic Caps-Word Configuration**
```lisp
;; ✅ FULLY SUPPORTED: Standard caps-word setup
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
```

**What this does:**
- **Tap ESC**: Normal escape key
- **Hold ESC (200ms)**: Activates caps-word mode for 2000ms (2 seconds)
- **Visual Feedback**: Shows ⇪ symbol with light blue gradient when active

#### **Timing Configuration Extraction**
The parser automatically extracts all timing values:

```lisp
;; Example configuration with extracted timings:
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
;;                         ↑   ↑                    ↑
;;                       tap hold                duration
```

- **Tap Timeout**: `150ms` - Time before tap becomes hold
- **Hold Timeout**: `200ms` - Time before hold activates caps-word  
- **Duration**: `2000ms` - How long caps-word stays active

#### **Visual States**
Caps-word keys show different visual states:

- **Inactive**: Normal key appearance with ⇪ symbol
- **Pressed**: Standard pressed key styling
- **Caps-Word Active**: Special light blue gradient background
- **Debug Indicators**: ⚠️ or ❌ symbols for parsing issues

#### **Real-Time Monitoring**
LearnKeys tracks caps-word state through multiple channels:

- **Key Press Detection**: Monitors ESC key press/release timing
- **TCP Layer Changes**: Receives caps-word state from kanata via TCP
- **Visual State Sync**: Automatically updates UI when caps-word activates/deactivates

### 🔧 **Caps-Word Configuration Best Practices**

#### **Recommended Timing Values**
```lisp
;; ✅ GOOD: Conservative timing for reliable activation
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())

;; ✅ GOOD: Faster activation for experienced users
esc (tap-hold-release-keys 100 150 esc (caps-word 1500) ())

;; ⚠️ CAUTION: Very fast timing may cause accidental activation
esc (tap-hold-release-keys 50 100 esc (caps-word 1000) ())
```

#### **Variable-Based Configuration**
```lisp
;; ✅ GOOD: Use variables for consistent timing
(defvar
  esc-tap-time 150
  esc-hold-time 200
  caps-word-duration 2000
)

(defalias
  esc (tap-hold-release-keys $esc-tap-time $esc-hold-time esc (caps-word $caps-word-duration) ())
)
```

#### **Multiple Caps-Word Keys**
```lisp
;; ✅ SUPPORTED: Multiple keys can trigger caps-word
(defalias
  esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
  caps (tap-hold-release-keys 150 200 caps (caps-word 2000) ())
)
```

### 🐛 **Caps-Word Debugging**

#### **Debug Output Examples**
When caps-word is configured, you'll see detailed debug output:

```bash
# Configuration parsing
DEBUG: 🕒 Found caps-word alias 'esc' with definition: '(tap-hold-release-keys 150 200 esc (caps-word 2000) ())'
DEBUG: 🕒 ✅ Created caps-word config: tap=150ms, hold=200ms, duration=2000ms, key='esc'

# Key press monitoring  
DEBUG: handleCapsWordKeyDown called with key: 'esc'
DEBUG: Registered caps-word keys: ["esc"]
DEBUG: ✅ Caps-word key 'esc' pressed, starting hold detection

# Activation/deactivation
DEBUG: ✅ CAPS-WORD VISUAL ACTIVATED from key 'esc' - hold timeout reached!
DEBUG: 🅰 CAPS-WORD VISUAL MODE ACTIVATED
DEBUG: 🕒 2000ms timer expired - auto-deactivating caps-word visual
DEBUG: 🅰 CAPS-WORD VISUAL MODE DEACTIVATED
```

#### **Manual Testing Commands**
LearnKeys includes built-in testing for caps-word:

```bash
# Test caps-word activation (Command+T)
🧪 MANUAL TEST: Activating caps-word visual for testing

# Quick test (Command+E)  
🧪 QUICK TEST: Command+E pressed - testing caps-word visual
```

#### **Common Debug Patterns**
```bash
# Key not registered for caps-word
DEBUG: ❌ Key 'a' not registered for caps-word

# Caps-word config not found
DEBUG: 🕒 ❌ No caps-word config found in parsed config

# Timing validation
DEBUG: 🕒 Using hold timeout: 100ms (reduced from 200ms for testing)
```

### ⚠️ **Caps-Word Troubleshooting**

#### **Issue: Caps-Word Not Activating**
```lisp
;; ❌ PROBLEM: Key not in defsrc
(defsrc q w e r ...)  ;; Missing 'esc'

;; ✅ SOLUTION: Add caps-word key to defsrc
(defsrc q w e r ... esc)
```

#### **Issue: Timing Too Sensitive**
```lisp
;; ❌ PROBLEM: Accidental activation
esc (tap-hold-release-keys 50 100 esc (caps-word 2000) ())

;; ✅ SOLUTION: Increase hold timeout
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
```

#### **Issue: Visual Not Showing**
```bash
# Check if caps-word config was parsed
swift learnkeys.swift config.kbd 2>&1 | grep "caps-word config"

# Check for parsing errors
swift learnkeys.swift config.kbd 2>&1 | grep "🕒"
```

#### **Issue: Duration Too Short/Long**
```lisp
;; ❌ PROBLEM: Caps-word deactivates too quickly
esc (tap-hold-release-keys 150 200 esc (caps-word 500) ())

;; ✅ SOLUTION: Increase duration
esc (tap-hold-release-keys 150 200 esc (caps-word 3000) ())
```

### 🚀 **Advanced Caps-Word Features**

#### **Integration with Layer Switching**
```lisp
;; ✅ SUPPORTED: Caps-word works with layer changes
(defalias
  esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
  spc (tap-hold-release-keys 200 150 spc (layer-while-held nav) ())
)
```

#### **TCP State Monitoring**
LearnKeys monitors caps-word state via TCP connection:
```bash
[TCP] 🅰 Caps-word related message detected!
[TCP] 🅰 Caps-word key found: state = active
```

#### **Error Recovery**
If caps-word parsing fails, LearnKeys provides fallbacks:
- Shows physical key name with ⚠️ symbol
- Logs detailed error information for debugging
- Continues to function for other keys

### 📋 **Caps-Word Configuration Checklist**

- [ ] **Key in defsrc**: Ensure caps-word key is listed in `(defsrc ...)`
- [ ] **Proper syntax**: Use `(caps-word duration)` format
- [ ] **Reasonable timing**: Test tap/hold timeouts for your typing style
- [ ] **Duration testing**: Verify caps-word duration meets your needs
- [ ] **Debug verification**: Check parser output for successful configuration
- [ ] **Visual confirmation**: Test that caps-word visual state activates correctly

## 🔄 TCP Layer Monitoring

LearnKeys includes real-time TCP monitoring to track layer changes and state updates from kanata, providing live synchronization between your configuration and the visual display.

### ✅ **TCP Monitoring Features**

#### **Real-Time Layer Changes**
LearnKeys connects to kanata via TCP to receive live layer change notifications:

```bash
# Example TCP messages received from kanata
[TCP] Raw message: {"LayerChange":{"new":"base"}}
[TCP] Layer changed to: base

[TCP] Raw message: {"LayerChange":{"new":"nomods"}}
[TCP] Layer changed to: nomods

[TCP] Raw message: {"LayerChange":{"new":"navfast"}}
[TCP] Layer changed to: navfast
```

#### **Automatic Layer Synchronization**
- **Live Updates**: Layer changes in kanata immediately update the LearnKeys display
- **State Tracking**: Current layer is tracked and displayed in real-time
- **Visual Feedback**: Active layer keys are highlighted when their layer is active

#### **TCP Connection Management**
```bash
# Connection status monitoring
[TCP] Connected to kanata on port 1337
[TCP] Connection established successfully
[TCP] Monitoring layer changes...

# Error handling
[TCP] Connection failed - retrying...
[TCP] TCP timeout - attempting reconnection
```

### 🔧 **TCP Configuration**

#### **Default TCP Settings**
LearnKeys uses these default TCP settings to connect to kanata:
- **Host**: `localhost` (127.0.0.1)
- **Port**: `1337` (kanata's default TCP port)
- **Auto-reconnect**: Enabled with exponential backoff
- **Message parsing**: JSON-based layer change detection

#### **Kanata TCP Setup**
To enable TCP monitoring in kanata, add this to your configuration:

```lisp
;; Enable TCP server for LearnKeys integration
(defcfg
  process-unmapped-keys yes
  tcp-server 1337
)
```

### 🐛 **TCP Debugging**

#### **TCP Debug Output**
Monitor TCP connection and messages:

```bash
# Monitor all TCP activity
swift learnkeys.swift config.kbd 2>&1 | grep "\[TCP\]"

# Track layer changes specifically
swift learnkeys.swift config.kbd 2>&1 | grep "Layer changed"

# Monitor raw TCP messages
swift learnkeys.swift config.kbd 2>&1 | grep "Raw message"

# Check connection status
swift learnkeys.swift config.kbd 2>&1 | grep -E "(Connected|Connection|TCP.*error)"
```

#### **Common TCP Debug Patterns**
```bash
# Successful layer change
[TCP] Raw message: {"LayerChange":{"new":"f-nav"}}
[TCP] Layer changed to: f-nav

# Non-layer messages (filtered out)
[TCP] 🔍 Non-layer message detected: {"KeyPress":{"key":"a"}}

# Caps-word detection attempts
[TCP] 🅰 Caps-word related message detected!
[TCP] 🅰 Caps-word key found: state = active
```

### ⚠️ **TCP Troubleshooting**

#### **Issue: No TCP Connection**
```bash
# Check if kanata TCP server is enabled
# Add to your kanata config:
(defcfg tcp-server 1337)

# Verify kanata is running with TCP enabled
ps aux | grep kanata
netstat -an | grep 1337
```

#### **Issue: Layer Changes Not Detected**
```bash
# Check TCP message format
swift learnkeys.swift config.kbd 2>&1 | grep "Raw message"

# Verify layer names match your config
swift learnkeys.swift config.kbd 2>&1 | grep "Layer changed"
```

#### **Issue: Connection Drops**
```bash
# Monitor connection stability
swift learnkeys.swift config.kbd 2>&1 | grep -E "(timeout|reconnect|failed)"

# Check for network issues
lsof -i :1337
```

### 🚀 **Advanced TCP Features**

#### **Message Type Detection**
LearnKeys can detect various message types from kanata:
- **Layer Changes**: Primary focus for visual updates
- **Key Events**: Monitored but not currently used for display
- **State Changes**: Including caps-word and other mode changes
- **Error Messages**: Logged for debugging purposes

#### **Future TCP Enhancements**
- **Bidirectional Communication**: Send commands back to kanata
- **Configuration Sync**: Automatically reload config when kanata restarts
- **Performance Metrics**: Track kanata performance via TCP
- **Custom Message Types**: Support for user-defined state messages

### 📋 **TCP Setup Checklist**

- [ ] **Kanata TCP enabled**: Add `tcp-server 1337` to kanata config
- [ ] **Port available**: Ensure port 1337 is not blocked
- [ ] **Kanata running**: Verify kanata is active and listening
- [ ] **Connection verified**: Check LearnKeys debug output for TCP messages
- [ ] **Layer changes working**: Test layer switching and verify TCP updates
- [ ] **Error handling**: Monitor for connection drops and reconnection attempts

## Best Practices for LearnKeys Compatibility

### 1. **Clear Alias Naming**
```lisp
;; ✅ GOOD: Descriptive names that indicate function
defalias
  shift lsft           ;; Modifier aliases
  fnav_h left          ;; Navigation aliases  
  fnav_j down
  fast_home M-left     ;; Fast movement aliases

;; ❌ AVOID: Cryptic or ambiguous names
defalias
  x1 lsft
  mv1 left
  a1 (tap-hold ...)
```

### 2. **Consistent Layer Organization**
```lisp
;; ✅ GOOD: Logical layer hierarchy
deflayer base          ;; Main typing layer
deflayer f-nav         ;; Basic navigation (F-hold)
deflayer nav-fast      ;; Fast navigation (chord)
deflayer symbols       ;; Symbol layer

;; ✅ GOOD: Use transparent keys to show only relevant mappings
deflayer f-nav
  _ _ _ _ _ _ _ _ _ _        ;; Hide unused keys
  _ _ _ _ _ @fnav_h @fnav_j @fnav_k @fnav_l _   ;; Show only nav keys
```

### 3. **Structured Alias Definitions**
```lisp
;; ✅ GOOD: Group related aliases together
defalias
  ;; Basic modifiers
  shift lsft
  control lctl
  
  ;; Home row mods (left hand)
  a (tap-hold-release-keys $tap-time $hold-time a @shift ())
  s (tap-hold-release-keys $tap-time $hold-time s @control ())
  
  ;; Navigation layer
  fnav_h left
  fnav_j down
```

### 4. **Variable Usage**
```lisp
;; ✅ GOOD: Define timing variables for consistency
defvar
  tap-time 200
  hold-time 150
  chord-timeout 250

;; ✅ GOOD: Use descriptive variable names
defvar
  left-hand-keys (q w e r t a s d f g z x c v b)
  navigation-layer f-nav
```

### 5. **Comment Your Config**
```lisp
;; ✅ GOOD: Clear section headers and explanations
;; HOME ROW MODIFIERS:
;; - Left hand:  A(shift) S(ctrl) D(option) F(nav)  
;; - Right hand: J(cmd) K(option) L(ctrl) ;(shift)

defalias
  ;; Left pinky gets extra time for tap-hold
  a (tap-hold-release-keys $a-tap-time $a-hold-time a @shift $left-hand-keys)
```

## Common Issues and Solutions

### Issue: Keys Not Displaying
```lisp
;; ❌ PROBLEM: Key not in defsrc
defsrc
  a s d f g h j k l

deflayer base  
  @a @s @d @f @g @custom_key j k l  ;; @custom_key won't show

;; ✅ SOLUTION: Add key to defsrc
defsrc
  a s d f g h j k l custom_key

deflayer base
  @a @s @d @f @g h j k l @custom_key  ;; Now shows properly
```

### Issue: Tap-Hold Not Detected
```lisp
;; ❌ PROBLEM: Complex expressions confuse parser
a (tap-hold 200 150 
    (multi a (layer-switch nomods)) 
    (multi lsft (layer-switch base))
  )

;; ✅ SOLUTION: Simplify for better parsing
a (tap-hold-release-keys 200 150 a lsft ())
```

### Issue: Layer Keys Not Recognized
```lisp
;; ❌ PROBLEM: Indirect layer reference
nav_key (layer-toggle my-nav-layer)

;; ✅ SOLUTION: Direct layer name works better
f (tap-hold-release-keys 200 150 f (layer-toggle f-nav) ())
```

### Issue: Aliases Missing or Incomplete
```lisp
;; ❌ PROBLEM: Inline comments break parsing
(defalias
  fnav_h left   ;; left arrow
  fnav_j down   ;; down arrow - NEVER PARSED!
  fnav_k up     ;; up arrow   - NEVER PARSED!
)

;; ✅ SOLUTION: Remove inline comments  
(defalias
  fnav_h left
  fnav_j down
  fnav_k up
)

;; ✅ ALTERNATIVE: Separate expressions
(defalias fnav_h left)   ;; left arrow
(defalias fnav_j down)   ;; down arrow  
(defalias fnav_k up)     ;; up arrow
```

### Issue: Expression Truncated Mid-Parse
```lisp
;; ❌ PROBLEM: Comment breaks multi-line expression
a (tap-hold-release-keys 200 150 a lsft) ;; This comment breaks everything after it!

;; ✅ SOLUTION: Move comment above
;; Home row modifier: A = tap a, hold shift
a (tap-hold-release-keys 200 150 a lsft)
```

## Parser Implementation Notes

### Current Parsing Strategy
1. **Parentheses Matching**: Tracks nested expressions by counting parentheses
2. **Expression Tokenization**: Splits expressions into tokens respecting nested structures
3. **Simple Pattern Matching**: Uses string contains/regex for tap-hold detection
4. **Alias Resolution**: Resolves `@` references to show actual actions

### Parser Limitations
- **Single-Pass**: Only makes one pass through the config
- **Simple Regex**: Uses basic pattern matching, not full expression parsing
- **Limited Nesting**: Complex nested expressions may not parse correctly
- **No Semantic Analysis**: Doesn't understand kanata's execution model

## 🔍 Parser Error Reporting & Debugging

### Comprehensive Error Detection
LearnKeys now includes advanced error reporting to catch parsing issues early and prevent broken UI display:

#### **Real-time Parsing Summary**
Every config load shows a detailed summary:
```
=== PARSING SUMMARY ===
✅ Parsed 21 aliases, 4 layers
⚠️  WARNINGS (2):
   • Alias 'complex_key': Unsupported hold action 'custom-macro' - may not display correctly
   • Alias 'broken_tap': Failed to parse tap action  
❌ ERRORS (1):
   • Failed to parse hold action for alias 'incomplete' with definition: (tap-hold...)
🔍 Validating aliases for display compatibility...
✅ No parsing issues detected
=======================
```

#### **Advanced Debug Output Categories**

**🕒 Caps-Word Debugging**
```bash
# Configuration parsing
DEBUG: 🕒 Found caps-word alias 'esc' with definition: '(tap-hold-release-keys 150 200 esc (caps-word 2000) ())'
DEBUG: 🕒 ✅ Created caps-word config: tap=150ms, hold=200ms, duration=2000ms, key='esc'

# Real-time key monitoring
DEBUG: handleCapsWordKeyDown called with key: 'esc'
DEBUG: Registered caps-word keys: ["esc"]
DEBUG: ✅ Caps-word key 'esc' pressed, starting hold detection

# State changes
DEBUG: ✅ CAPS-WORD VISUAL ACTIVATED from key 'esc' - hold timeout reached!
DEBUG: 🅰 CAPS-WORD VISUAL MODE ACTIVATED
DEBUG: 🕒 2000ms timer expired - auto-deactivating caps-word visual
DEBUG: 🅰 CAPS-WORD VISUAL MODE DEACTIVATED
```

**🔄 Layer Change Monitoring**
```bash
# TCP layer changes from kanata
[TCP] Raw message: {"LayerChange":{"new":"nomods"}}
[TCP] Layer changed to: nomods
[TCP] Raw message: {"LayerChange":{"new":"base"}}
[TCP] Layer changed to: base
[TCP] Raw message: {"LayerChange":{"new":"navfast"}}
[TCP] Layer changed to: navfast
```

**⌨️ Key Event Tracking**
```bash
# Individual key press/release events
DEBUG: Key down detected: 'd' (keycode: 2)
DEBUG: Key up detected: 'd' (keycode: 2)
DEBUG: Key down detected: 'spc' (keycode: 49)
DEBUG: Key up detected: 'spc' (keycode: 49)

# Modifier key detection
DEBUG: handleModifierChange keyCode: 55, flags: CGEventFlags(rawValue: 1048840)
DEBUG: Found physical key 'g' for system keycode 55
DEBUG: Modifier 'command' for key 'g' is active
DEBUG: ✅ Activated modifier 'command' and key 'g'
```

**🔍 Alias Parsing Details**
```bash
# Alias creation and validation
DEBUG: Adding alias 'a' -> '(tap-hold-release-keys 200 150 a lsft ())'
DEBUG: Parsed tap action: 'a' hold action: 'lsft'
DEBUG: Total aliases loaded: 42

# FNAV alias debugging
DEBUG: FNAV alias 'fnav_h' -> 'left'
DEBUG: FNAV alias 'fnav_j' -> 'down'
DEBUG: FNAV alias 'fnav_k' -> 'up'
DEBUG: FNAV alias 'fnav_l' -> 'right'
```

#### **Display Validation System**
Prevents broken UI elements like "(TAP-HO..." through active validation:

- **Text Length Validation**: Catches overly long or complex definitions
- **Content Validation**: Detects unparsed expressions containing "(", "tap-hold", "multi"  
- **Fallback System**: Uses tap actions or physical keys when parsing fails
- **Error Symbols**: Shows ⚠️ or ❌ symbols for problematic keys

#### **Enhanced Debug Commands**

**Basic Debugging**
```bash
# Full parsing summary with errors/warnings
swift learnkeys.swift config.kbd

# Show only errors and warnings
swift learnkeys.swift config.kbd 2>&1 | grep -E "(⚠️|❌|===)"

# Detailed parser debug information
swift learnkeys.swift config.kbd 2>&1 | grep DEBUG
```

**Caps-Word Specific Debugging**
```bash
# Monitor caps-word configuration parsing
swift learnkeys.swift config.kbd 2>&1 | grep "🕒"

# Track caps-word key registration
swift learnkeys.swift config.kbd 2>&1 | grep "Registered caps-word"

# Monitor caps-word activation/deactivation
swift learnkeys.swift config.kbd 2>&1 | grep "🅰"

# Check caps-word timing configuration
swift learnkeys.swift config.kbd 2>&1 | grep "caps-word config"
```

**Layer and Key Monitoring**
```bash
# Monitor layer changes via TCP
swift learnkeys.swift config.kbd 2>&1 | grep "\[TCP\]"

# Track specific key events
swift learnkeys.swift config.kbd 2>&1 | grep "Key.*detected"

# Monitor modifier key activation
swift learnkeys.swift config.kbd 2>&1 | grep "Modifier.*active"

# Track alias parsing for specific keys
swift learnkeys.swift config.kbd 2>&1 | grep "Adding alias"
```

**Advanced Debugging Patterns**
```bash
# Monitor FNAV navigation aliases specifically
swift learnkeys.swift config.kbd 2>&1 | grep "FNAV alias"

# Check for unhandled key events
swift learnkeys.swift config.kbd 2>&1 | grep "UNHANDLED KEY"

# Monitor system keycode mappings
swift learnkeys.swift config.kbd 2>&1 | grep "System keycode mapping"

# Track timing validation
swift learnkeys.swift config.kbd 2>&1 | grep "Using.*timeout"
```

#### **Interactive Testing Features**

**Built-in Test Commands**
```bash
# Manual caps-word testing (Command+T while app is running)
🧪 MANUAL TEST: Activating caps-word visual for testing

# Quick caps-word test (Command+E while app is running)  
🧪 QUICK TEST: Command+E pressed - testing caps-word visual

# Force keycode summary logging
🔍 MANUAL KEYCODE SUMMARY REQUEST:
```

**Real-time State Monitoring**
LearnKeys provides live monitoring of:
- Active keys and modifiers
- Layer state changes
- Caps-word activation status
- TCP connection status
- Key event processing

#### **Error Categories**

**🔴 ERRORS (require fixing):**
- Failed to parse tap/hold actions in tap-hold expressions
- Insufficient tokens in expressions  
- Missing required alias definitions
- TCP connection failures
- Caps-word configuration parsing errors

**🟡 WARNINGS (may affect display):**
- Unsupported hold actions (custom macros, complex sequences)
- Complex multi-actions not fully parsed
- Suspiciously few aliases (likely comment parsing issues)
- Duplicate alias definitions
- Missing keys in defsrc that are referenced in layers

**🟢 DISPLAY FALLBACKS:**
- Shows physical key + ❌ when parsing completely fails
- Shows tap action + ⚠️ when hold action unsupported
- Shows "?" for empty/missing definitions
- Uses fallback symbols for unrecognized keys

#### **Debug Output Filtering**

**Focus on Specific Issues**
```bash
# Only caps-word related debug output
swift learnkeys.swift config.kbd 2>&1 | grep -E "(🕒|🅰|caps-word)"

# Only parsing errors and warnings
swift learnkeys.swift config.kbd 2>&1 | grep -E "(❌|⚠️|ERROR|WARNING)"

# Only layer and key events
swift learnkeys.swift config.kbd 2>&1 | grep -E "(\[TCP\]|Key.*detected|Layer.*changed)"

# Only alias parsing
swift learnkeys.swift config.kbd 2>&1 | grep -E "(Adding alias|FNAV alias|Total aliases)"
```

**Performance Monitoring**
```bash
# Monitor parsing performance
swift learnkeys.swift config.kbd 2>&1 | grep -E "(Parsing.*took|Total.*loaded)"

# Track memory usage patterns
swift learnkeys.swift config.kbd 2>&1 | grep -E "(Memory|Cache|Buffer)"

# Monitor TCP connection health
swift learnkeys.swift config.kbd 2>&1 | grep -E "(TCP.*connected|TCP.*error|TCP.*timeout)"
```

### Future Error Detection Features
- **Layer validation**: Check for undefined layer references
- **Key conflict detection**: Identify overlapping key mappings  
- **Timing validation**: Verify tap-hold timing values
- **Dependency analysis**: Check for missing alias references
- **Performance profiling**: Track parsing and rendering performance
- **Configuration linting**: Real-time syntax and logic validation

---

## Future Improvements Roadmap

### Phase 1: Enhanced Parsing (Near-term)

#### **Better Expression Parser**
- **Full AST Parsing**: Build complete abstract syntax tree instead of simple tokenization
- **Semantic Understanding**: Understand kanata's execution model for accurate action detection
- **Complex Multi-Actions**: Parse `(multi ...)` expressions to show all actions
- **Conditional Logic**: Support `(if ...)` and other conditional expressions

#### **Advanced Tap-Hold Support**
```lisp
;; Future support for complex tap-hold patterns
a (tap-hold-press 200 150 
    (multi a (layer-switch nomods))    ;; Complex tap action
    (multi lsft (timeout 500 lctl))    ;; Complex hold with timeout
  )
```

#### **Critical Comment Parser Fix**
- **Inline Comment Support**: Proper `;;` handling that doesn't break expressions
- **Comment-Aware Tokenization**: Parse comments without truncating subsequent tokens
- **Expression Preservation**: Maintain parsing state across comment boundaries
- **Multi-line Comment Safety**: Handle comments in complex nested expressions

#### **Variable System Enhancement**
- **Full Variable Substitution**: Proper `$variable` replacement throughout config
- **Computed Variables**: Support for calculated timing values
- **Variable Validation**: Check for undefined variable references

### Phase 2: Advanced Features (Medium-term)

#### **Chord Support**
```lisp
;; Visualize chord definitions
defchords
  (d f) 200 (layer-while-held navfast) :base
  (j k) 150 (macro "hello") :all
```
- **Chord Visualization**: Show which key combinations trigger chords
- **Timing Display**: Indicate chord timeout values
- **Layer Context**: Show which layers chords are active in

#### **Sequence and Macro Support**
```lisp
;; Display macro and sequence content
defseq
  my-macro (macro "git status" ret)
  
defalias
  git (sequence my-macro)
```
- **Macro Preview**: Show what text/keys a macro produces
- **Sequence Steps**: Display individual steps in sequences
- **Unicode Support**: Handle unicode output in macros

#### **Layout Analysis**
- **Ergonomic Scoring**: Analyze modifier placement for comfort
- **Conflict Detection**: Identify potentially problematic key combinations
- **Usage Statistics**: Track which layers and keys are used most
- **Heat Map**: Visual representation of key usage patterns

### Phase 3: Smart Features (Long-term)

#### **Configuration Validation**
- **Syntax Checking**: Real-time validation of kanata syntax
- **Logic Analysis**: Detect unreachable layers or conflicting definitions
- **Performance Warnings**: Identify configurations that might cause timing issues
- **Best Practice Suggestions**: Recommend improvements based on common patterns

#### **Intelligent Suggestions**
- **Auto-Complete**: Suggest key mappings based on existing patterns
- **Layer Optimization**: Recommend layer consolidation or splitting
- **Timing Tuning**: Suggest optimal timing values based on key combinations
- **Accessibility Analysis**: Check for accessible modifier arrangements

#### **Advanced Visualization**
- **3D Layer View**: Interactive 3D representation of layer hierarchy
- **Flow Analysis**: Show how key presses flow through layers
- **Timing Visualization**: Real-time display of tap-hold timing windows
- **Usage Analytics**: Historical data on key usage patterns

#### **Integration Features**
- **Live Config Editing**: Edit configuration directly in LearnKeys with instant preview
- **A/B Testing**: Compare different configurations side-by-side
- **Backup and Versioning**: Automatic config versioning and rollback
- **Community Sharing**: Share and discover configurations from other users

### Phase 4: Ecosystem Integration (Future)

#### **Multi-Device Support**
- **Config Synchronization**: Sync configurations across multiple devices
- **Device-Specific Layers**: Different configs for laptop vs external keyboard
- **Cloud Backup**: Automatic cloud storage of configurations

#### **Advanced Analytics**
- **Typing Analysis**: Real-time analysis of typing patterns and efficiency
- **Learning Assistance**: Adaptive training for new layouts
- **Ergonomic Recommendations**: AI-powered suggestions for healthier typing

#### **IDE Integration**
- **VSCode Extension**: Real-time kanata config editing with LearnKeys preview
- **Language Server**: Full language support for kanata configuration files
- **Debugging Tools**: Step-through debugging of key press handling

## Contributing to Parser Development

### Testing New Features
1. **Create Test Configs**: Write configs that exercise new parsing features
2. **Debug Logging**: Enable parser debug output to understand tokenization
3. **Edge Cases**: Test with unusual but valid kanata configurations
4. **Performance Testing**: Ensure parser scales with large configurations

### Parser Architecture Improvements
1. **Modular Design**: Split parser into specialized components
2. **Error Recovery**: Graceful handling of malformed configurations  
3. **Incremental Parsing**: Only re-parse changed sections
4. **Configuration Caching**: Cache parsed results for better performance

---

*This guide will be updated as the LearnKeys parser evolves. For the latest parser capabilities, check the main README.md and examine the debug output when loading your configuration.* 