# Kanata Config Guide for LearnKeys

This guide explains how to write kanata configuration files that work optimally with the LearnKeys dynamic dashboard parser.

## Table of Contents

1. [What the Parser Currently Understands](#what-the-parser-currently-understands)
2. [⚠️ Critical Issue: Comment Handling](#️-critical-issue-comment-handling)
3. [Best Practices for LearnKeys Compatibility](#best-practices-for-learnkeys-compatibility)
4. [Common Issues and Solutions](#common-issues-and-solutions)
5. [Parser Implementation Notes](#parser-implementation-notes)
6. [Recent Fixes](#recent-fixes)
7. [🔍 Parser Error Reporting & Debugging](#-parser-error-reporting--debugging)
8. [Future Improvements Roadmap](#future-improvements-roadmap)
9. [Contributing to Parser Development](#contributing-to-parser-development)

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

### ⚠️ Partially Supported Features

#### **Complex Multi-Actions**
```lisp
;; ✅ PARSED: But only tap action shown in UI
tap (multi 
  (layer-switch nomods)
  (on-idle-fakekey to-base tap 20)
)

;; ✅ PARSED: But complex hold action simplified
esc (tap-hold-release-keys 150 200 esc (caps-word 2000) ())
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

#### **Display Validation System**
Prevents broken UI elements like "(TAP-HO..." through active validation:

- **Text Length Validation**: Catches overly long or complex definitions
- **Content Validation**: Detects unparsed expressions containing "(", "tap-hold", "multi"  
- **Fallback System**: Uses tap actions or physical keys when parsing fails
- **Error Symbols**: Shows ⚠️ or ❌ symbols for problematic keys

#### **Debug Commands**
```bash
# Full parsing summary with errors/warnings
swift learnkeys.swift config.kbd

# Show only errors and warnings
swift learnkeys.swift config.kbd 2>&1 | grep -E "(⚠️|❌|===)"

# Detailed parser debug information
swift learnkeys.swift config.kbd 2>&1 | grep DEBUG

# Monitor specific alias parsing
swift learnkeys.swift config.kbd 2>&1 | grep "Adding alias"
```

#### **Error Categories**

**🔴 ERRORS (require fixing):**
- Failed to parse tap/hold actions in tap-hold expressions
- Insufficient tokens in expressions  
- Missing required alias definitions

**🟡 WARNINGS (may affect display):**
- Unsupported hold actions (caps-word, custom macros, etc.)
- Complex multi-actions not fully parsed
- Suspiciously few aliases (likely comment parsing issues)
- Duplicate alias definitions

**🟢 DISPLAY FALLBACKS:**
- Shows physical key + ❌ when parsing completely fails
- Shows tap action + ⚠️ when hold action unsupported
- Shows "?" for empty/missing definitions

### Future Error Detection Features
- **Layer validation**: Check for undefined layer references
- **Key conflict detection**: Identify overlapping key mappings  
- **Timing validation**: Verify tap-hold timing values
- **Dependency analysis**: Check for missing alias references

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