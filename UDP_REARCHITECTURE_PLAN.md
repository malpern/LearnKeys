# LearnKeys UDP-First Rearchitecture Plan

## 🎯 **Vision: Simple, Reliable, UDP-Driven Architecture**

Move from complex multi-source architecture to a clean UDP-first design that's simpler, more reliable, and easier to maintain.

## 📊 **Current Architecture Issues**

### **Complex Multi-Source Input**
```
Current Sources:
├── KeyMonitor (Accessibility APIs) ❌ Complex, permission-heavy
├── TCPClient (Layer changes)       ⚠️  Necessary but can be simplified  
├── UDPKeyTracker (New)            ✅ Reliable, fast, deterministic
└── Multiple fallback systems      ❌ Confusing logic
```

### **Problems to Solve:**
- **Accessibility Permission Hell**: Users struggle with macOS permissions
- **Timing Inconsistencies**: Different sources have different latencies
- **Complex Fallback Logic**: Multiple code paths for the same functionality
- **Debugging Difficulty**: Hard to trace which source triggered what
- **Performance Overhead**: OS-level key monitoring is expensive

## 🏗️ **New UDP-First Architecture**

### **Core Principle: Single Source of Truth**
```
New Simple Architecture:
├── UDPKeyTracker (Primary)    ✅ All key events, modifiers, navigation
├── TCPClient (Minimal)        ✅ Layer changes only (if needed)
└── Clean Animation System     ✅ Driven entirely by UDP events
```

### **UDP Message Types (Already Working)**
```
keypress:KEY        → Key tap animations
navkey:KEY          → Navigation animations  
modifier:MOD:down   → Modifier state changes
layer:LAYER         → Layer transitions
```

## 🚀 **Implementation Plan**

### **Phase 1: UDP-Only Validation (1-2 hours)**

#### **1.1 Create UDP-Only Test App**
```swift
// Minimal test app to validate UDP-only approach
class UDPOnlyApp: ObservableObject {
    @Published var udpTracker = UDPKeyTracker()
    @Published var activeKeys: Set<String> = []
    @Published var activeModifiers: Set<String> = []
    @Published var currentLayer: String = "base"
    
    // Simple state management driven only by UDP
    func handleUDPUpdate() {
        activeKeys = udpTracker.getActiveKeys()
        activeModifiers = udpTracker.getActiveModifiers()
        currentLayer = udpTracker.currentLayer
    }
}
```

#### **1.2 Test All Functionality**
- ✅ Key press animations work
- ✅ Modifier state changes work  
- ✅ Navigation keys work
- ✅ Layer changes work (UDP or minimal TCP)
- ✅ No accessibility permissions needed

### **Phase 2: Clean Architecture Design (2-3 hours)**

#### **2.1 New Service Architecture**
```
LearnKeys/
├── App/
│   └── LearnKeysApp.swift         # Minimal app lifecycle
├── Core/                          # NEW: Core UDP-driven logic
│   ├── UDPKeyTracker.swift       # Enhanced UDP tracker (primary)
│   ├── AnimationController.swift  # UDP → Animation mapping
│   └── LayerManager.swift        # Layer state management
├── Views/
│   ├── KeyboardView.swift        # Simplified keyboard display
│   ├── KeyView.swift             # Individual key with UDP animations
│   └── LayerIndicator.swift      # Layer status display
└── Models/
    ├── KeyState.swift            # Simple key state model
    └── KanataConfig.swift        # Minimal config parsing
```

#### **2.2 Remove Complex Components**
```
REMOVE:
├── KeyMonitor.swift              # ❌ Accessibility-based monitoring
├── ComplexFallbackLogic          # ❌ Multi-source coordination
├── CapsWordManager               # ❌ Can be UDP-driven instead
└── ModifierKeyMonitor            # ❌ Replace with UDP modifiers
```

#### **2.3 Simplified State Management**
```swift
// Single source of truth - UDP events
class AnimationController: ObservableObject {
    @Published var keyStates: [String: KeyState] = [:]
    private let udpTracker = UDPKeyTracker()
    
    init() {
        udpTracker.onKeyPress = { key in
            self.animateKeyPress(key)
        }
        udpTracker.onModifierChange = { modifier, isActive in
            self.updateModifierState(modifier, isActive)
        }
        udpTracker.onLayerChange = { layer in
            self.transitionToLayer(layer)
        }
    }
}
```

### **Phase 3: Enhanced UDP Features (2-4 hours)**

#### **3.1 Rich UDP Message Types**
```
// Expand UDP vocabulary for better animations
keypress:a:duration:300     → Key with custom duration
modifier:shift:down:force   → Modifier with pressure info
navkey:h:speed:fast         → Navigation with speed indication
combo:d+f:chord             → Chord combinations
layer:navfast:transition    → Layer with transition type
```

#### **3.2 Smart Animation Mapping**
```swift
extension AnimationController {
    func handleUDPMessage(_ message: String) {
        let components = message.split(separator: ":")
        
        switch components[0] {
        case "keypress":
            let key = String(components[1])
            let duration = components.count > 2 ? Int(components[2]) : 300
            animateKeyPress(key, duration: duration)
            
        case "combo":
            let keys = String(components[1]).split(separator: "+")
            animateCombo(keys.map(String.init))
            
        case "navkey":
            let key = String(components[1])
            let speed = components.count > 2 ? String(components[2]) : "normal"
            animateNavigation(key, speed: speed)
        }
    }
}
```

### **Phase 4: Performance & Polish (1-2 hours)**

#### **4.1 Optimized Rendering**
```swift
// Efficient view updates driven by UDP state
struct KeyView: View {
    let physicalKey: String
    @EnvironmentObject var animationController: AnimationController
    
    var body: some View {
        KeyShape()
            .scaleEffect(keyState.isPressed ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: keyState.isPressed)
    }
    
    private var keyState: KeyState {
        animationController.keyStates[physicalKey] ?? .inactive
    }
}
```

#### **4.2 Clean Configuration**
```swift
// Minimal config parsing - only what's needed for display
struct DisplayConfig {
    let physicalKeys: [String]      // From defsrc
    let layers: [String: [String]]  // Layer mappings
    let displayMappings: [String: DisplayMapping]  // Visual symbols
    
    // Remove complex alias parsing - rely on UDP for behavior
}
```

## 🎯 **Benefits of UDP-First Architecture**

### **Simplicity**
- ✅ **Single data source**: No complex coordination logic
- ✅ **No permissions**: No accessibility API requirements
- ✅ **Predictable timing**: UDP messages arrive when keys are actually pressed
- ✅ **Easy testing**: Send UDP messages to test any scenario

### **Reliability**  
- ✅ **Direct from source**: Kanata sends exactly what happened
- ✅ **No OS interference**: No macOS permission or timing issues
- ✅ **Deterministic**: Same input always produces same output
- ✅ **Immediate feedback**: No polling or event monitoring delays

### **Performance**
- ✅ **Lightweight**: No OS-level key monitoring
- ✅ **Efficient**: Only process events that matter
- ✅ **Smooth animations**: Consistent timing from UDP
- ✅ **Lower CPU**: No accessibility event processing

### **Developer Experience**
- ✅ **Easy debugging**: `printf "keypress:a\n" | nc -u 127.0.0.1 6789`
- ✅ **Simple testing**: Mock UDP messages for any scenario
- ✅ **Clear architecture**: One way data flows
- ✅ **Easy extensions**: Add new UDP message types as needed

## 🚧 **Migration Strategy**

### **Option A: Clean Rewrite (Recommended)**
```bash
# Create new UDP-first implementation
mkdir LearnKeysUDP
cp -r LearnKeys/Models/ LearnKeysUDP/
cp LearnKeys/Services/UDPKeyTracker.swift LearnKeysUDP/
# Build new clean architecture from scratch
```

### **Option B: Gradual Migration**
```bash
# Disable old systems one by one
1. Comment out KeyMonitor initialization
2. Disable fallback logic
3. Remove unused services
4. Simplify view logic
```

## 📝 **Implementation Checklist**

### **Core UDP System**
- [ ] Enhanced UDPKeyTracker with rich message types
- [ ] AnimationController driven by UDP events
- [ ] LayerManager for UDP-based layer changes
- [ ] Simple KeyState model

### **Views**
- [ ] KeyboardView using only UDP state
- [ ] KeyView with UDP-driven animations
- [ ] LayerIndicator showing UDP layer state
- [ ] Remove accessibility-dependent views

### **Configuration**
- [ ] Minimal config parsing (display-only)
- [ ] Remove complex alias parsing
- [ ] Focus on layout and visual mapping

### **Testing**
- [ ] UDP message test suite
- [ ] Animation verification
- [ ] Performance benchmarking
- [ ] No-permission validation

## 🎉 **Expected Results**

### **Before (Complex)**
- Multiple data sources with coordination logic
- Accessibility permissions required
- Inconsistent timing and fallback behavior
- Difficult to debug and test

### **After (Simple)**
- Single UDP data source
- No special permissions needed
- Consistent, predictable behavior
- Easy to test and extend

### **User Experience**
- ✅ **Easier setup**: No accessibility configuration
- ✅ **More reliable**: Direct from kanata, no OS interference
- ✅ **Better performance**: Lighter, more responsive
- ✅ **Cleaner animations**: Consistent timing and behavior

---

**This UDP-first rearchitecture will create a much simpler, more reliable, and easier-to-maintain application while providing better user experience and performance.** 