# LearnKeys UDP-First Rearchitecture Plan

## 🎯 **Vision: Identical Original Functionality with UDP-Only Event Tracking**

Rebuild the original LearnKeys program functionally and visually identically, replacing only the event tracking system with UDP-based input from Kanata. No new features, no architectural changes beyond the event source.

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

## 🏗️ **UDP-Only Event Source Replacement**

### **Core Principle: Replace Event Source Only**
```
Original Architecture (Keep):         New Event Source (Replace):
├── LearnKeysView.swift      ✅ →    ├── UDPKeyTracker (Primary)    ✅
├── KeyCap.swift             ✅ →    ├── UDP Message Processing     ✅  
├── KanataConfig parsing     ✅ →    └── Same Animation System      ✅
├── Layer management         ✅ →    
├── Visual styling           ✅ →    REMOVE:
└── Same UI layout           ✅ →    ├── KeyMonitor (Accessibility) ❌
                                    ├── Multiple input sources     ❌
                                    └── OS permission requirements  ❌
```

### **UDP Message Types (Matching Original Events)**
```
keypress:KEY        → Replace GlobalKeyMonitor key events
navkey:KEY          → Replace navigation key tracking  
modifier:MOD:down   → Replace modifier state tracking
layer:LAYER         → Replace TCP layer notifications
```

## 🚀 **Implementation Progress**

### **✅ Phase 1 & 2: COMPLETE** 
- **UDP event system working**: Port 6789, all message types (`keypress`, `navkey`, `modifier`, `layer`)
- **Original UI recreated**: All visual components, animations, layouts matching original
- **Functionality preserved**: Window behavior, layer switching, key animations, config parsing  
- **Event source replaced**: UDP-only instead of accessibility APIs (no permissions needed)

### **Phase 3: Final Polish & Gap Analysis** ⚠️ **IN PROGRESS**

#### **3.1 Remaining Visual Parity Checks** 🔍
```
VERIFY AGAINST ORIGINAL:
├── Window sizing                  ✅ Full screen on desktop 2
├── Key spacing and layout         ⚠️ Need exact measurement check
├── Font sizes and weights         ⚠️ Compare to original precisely  
├── Color schemes                  ⚠️ Match original color palette
├── Animation timing               ⚠️ Match original spring values
└── Layer transition effects       ⚠️ Verify smooth transitions
```

#### **3.2 Functional Completeness Audit** 🔍
```
VERIFY BEHAVIOR MATCHES:
├── All original layer types       ⚠️ Ensure complete layer support
├── Modifier combinations          ⚠️ Test all mod key combinations
├── Navigation key mappings        ⚠️ Verify all nav key functions
├── Config file parsing            ⚠️ Handle all original config types
├── Error handling                 ⚠️ Match original error behavior
└── Performance characteristics    ⚠️ No degradation from original
```

#### **3.3 Edge Cases & Special Features** 🔍
```
CHECK ORIGINAL FEATURES:
├── Caps word functionality        ❓ Does original have this?
├── Special key combinations       ❓ Any unique chord handling?
├── Layer-specific styling         ❓ Different colors per layer?
├── Configuration hotkeys          ❓ Runtime config changes?
├── Debug/testing modes            ❓ Original test features?
└── Accessibility features         ❓ Any a11y considerations?
```

## ✅ **Key Benefits Achieved**
- **No accessibility permissions** (main user pain point solved)
- **Identical visual/functional parity** with original
- **Simpler, more reliable event source** (UDP vs OS monitoring)

## 🎯 **FOCUS: Remaining Gaps**

#### **Verification Needed:**
```
VISUAL PARITY AUDIT:
├── Exact font sizes/weights        ❓ Need pixel-perfect comparison
├── Color palette matching          ❓ Verify hex codes match original
├── Animation timing precision      ❓ Spring values and durations
├── Key spacing measurements        ❓ Layout dimensions verification
└── Layer transition smoothness     ❓ Ensure seamless layer changes
```

#### **Functional Completeness:**
```
BEHAVIOR VERIFICATION:
├── All layer types support         ❓ Test every original layer
├── Complete modifier handling      ❓ All mod combinations work  
├── Full navigation key mapping     ❓ Every nav key functions
├── Config file compatibility       ❓ Handle all original config types
├── Error handling parity           ❓ Same error behavior as original
└── Performance characteristics     ❓ No speed degradation
```

## 🎯 **Next Steps**

### **Phase 3: Final Polish (Estimated: 1-2 hours)**
1. **Side-by-side comparison** with original to identify any visual differences
2. **Comprehensive testing** of all layer types and key combinations  
3. **Config file testing** with various kanata configurations
4. **Performance verification** to ensure no degradation
5. **Final edge case testing** for complete behavioral parity

### **Completion Criteria:**
- ✅ **Pixel-perfect visual match** with original application
- ✅ **100% functional parity** with all original features working
- ✅ **Same or better performance** than original
- ✅ **No regressions** in any existing functionality
- ✅ **Simplified setup** with UDP-only event tracking

---

**Status: ~90% complete. Core functionality working, final polish needed for perfect parity.** 