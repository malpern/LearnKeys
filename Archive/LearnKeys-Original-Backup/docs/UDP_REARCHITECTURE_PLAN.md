# LearnKeys TCP Migration Plan

## 🎯 **Primary Goal: UDP → TCP Migration**

**Switch from UDP + shell commands to native TCP communication for better security, performance, and standard Kanata compatibility.**

## 📊 **Current Status: Foundation Complete ✅ | TCP Migration Needed 🎯**

### **✅ COMPLETED - Phase 1: UDP Foundation**
```
COMPLETED INFRASTRUCTURE:
├── UDPKeyTracker                   ✅ Complete - All message types working
├── Headless Mode                   ✅ Complete - CI-ready with --headless flag
├── Message Processing              ✅ Complete - keypress:*, navkey:*, modifier:*, layer:*
├── Logging System                  ✅ Complete - File + console with categories
├── Signal Handling                 ✅ Complete - Graceful SIGINT/SIGTERM shutdown
├── Build System                    ✅ Complete - Swift Package + CI ready
├── Basic GUI Framework             ✅ Complete - SwiftUI app structure
└── CI/CD Pipeline                  ✅ Complete - GitHub Actions with automated testing

ARCHITECTURE ACHIEVEMENTS:
├── Accessibility API Dependencies  ✅ Eliminated - No permissions required
├── Complex Permission Handling     ✅ Eliminated - Permission-free operation
└── Multiple Input Sources          ✅ Eliminated - Single source of truth
```

## 🎯 **ACTIVE GOAL: TCP Migration (Phase 2)**

### **Why TCP Over Current UDP Approach**
```
CURRENT UDP + CMD ISSUES:
├── Security Risk                   ⚠️  Shell command execution per keypress
├── Performance Overhead            ⚠️  Process spawning (~50ms per key)
├── Custom Kanata Build            ⚠️  Requires danger-enable-cmd
├── Attack Surface                 ⚠️  Shell → nc → UDP stack
└── Delivery Guarantees            ⚠️  UDP packets can be lost

TCP MIGRATION BENEFITS:
├── Native Socket Communication     ✅ No shell commands
├── Standard Kanata Builds         ✅ Homebrew compatible
├── Guaranteed Delivery            ✅ TCP reliability
├── Better Performance             ✅ Direct socket vs process spawning
├── Connection Awareness           ✅ Know when Kanata disconnects
└── Reduced Attack Surface         ✅ Direct TCP only
```

### **TCP Migration Tasks**

#### **2.0 Kanata Installation Migration (0.5 days)**
```bash
# Remove current cmd-enabled Kanata
which kanata  # Identify current installation
ps aux | grep kanata && killall kanata  # Stop running instances
rm $(which kanata)  # Remove custom build

# Install standard Homebrew Kanata
brew install kanata
which kanata  # Verify: /opt/homebrew/bin/kanata
kanata --help | grep -i tcp  # Check TCP server support

# Backup current configs (they contain cmd statements)
cp *.kbd ./kbd-backups/
```

#### **2.1 Research & Validation (1-2 days)**
```bash
# Verify standard Kanata TCP capability
kanata --port 5829 --cfg config.kbd
# Note: Will fail initially - configs have cmd statements

# Test TCP message formats
echo "keypress:a" | nc 127.0.0.1 5829

# Document TCP vs UDP message differences
```

#### **2.2 Swift TCP Client Implementation (2-3 days)**
```
CREATE: Core/TCPKeyTracker.swift
├── Native Swift NWConnection (TCP)
├── Replace UDPKeyTracker functionality
├── Maintain same message format
├── Add connection state management
└── Preserve all existing callbacks

MODIFY: App/LearnKeysUDPApp.swift  
├── Switch from UDPKeyTracker to TCPKeyTracker
├── Handle TCP connection states
├── Update logging messages
└── Maintain headless mode support
```

#### **2.3 Configuration Migration (1 day)**
```
UPDATE: Kanata .kbd files
├── Remove all cmd statements
├── Use native TCP output instead
├── Remove danger-enable-cmd requirement
└── Test with standard Kanata builds

EXAMPLE MIGRATION:
Before: (tap-hold 200 200 a (cmd "printf 'keypress:a\n' | nc -u 127.0.0.1 6789"))
After:  (tap-hold 200 200 a (tcp-send "keypress:a"))  # or whatever TCP syntax
```

#### **2.4 Testing & Validation (1-2 days)**
```
COMPREHENSIVE TCP TESTING:
├── Port existing UDP tests to TCP
├── Connection handling (connect/disconnect/reconnect)
├── Message delivery verification
├── Performance comparison (TCP vs UDP+cmd)
├── Headless mode with TCP
└── CI/CD pipeline updates
```

#### **2.5 Documentation Update (0.5 days)**
```
UPDATE DOCS:
├── Installation guides (standard Kanata)
├── Configuration examples (TCP-based)
├── Performance improvements documented
├── Security benefits explained
└── Migration guide for UDP → TCP users
```

## 🧪 **TCP Migration Testing Plan**

### **Phase 2.1: Basic TCP Connection**
```bash
# Test 1: Kanata TCP server
kanata --port 5829 --cfg test-config.kbd

# Test 2: Manual TCP message
echo "keypress:a" | nc 127.0.0.1 5829

# Test 3: Connection handling
# Start/stop Kanata, verify Swift app handles gracefully
```

### **Phase 2.2: Swift TCP Integration**
```bash
# Test 1: TCP message processing
swift run LearnKeysUDP  # (renamed to TCPKeyTracker)

# Test 2: Headless TCP mode  
swift run LearnKeysUDP --headless

# Test 3: Performance comparison
# Benchmark TCP vs UDP+cmd approach
```

### **Phase 2.3: End-to-end Workflow**
```bash
# Test 1: Standard Kanata build
brew install kanata
kanata --port 5829 --cfg config.kbd

# Test 2: No danger-enable-cmd needed
# Verify config works without cmd statements

# Test 3: Production workflow
# Complete setup from scratch
```

## 📊 **Success Criteria**

### **TCP Migration Complete When:**
- ✅ **Native TCP Communication**: No shell commands executed
- ✅ **Standard Kanata Compatible**: Works with Homebrew Kanata
- ✅ **Performance Improved**: Faster than UDP+cmd approach
- ✅ **Security Enhanced**: No shell injection risk
- ✅ **Connection Reliable**: Handles disconnects gracefully
- ✅ **All Tests Pass**: Existing functionality preserved

## 🗂️ **ARCHIVED: Secondary Priorities**

### **Visual Parity Work (Future Phase 3)**
```
MOVED TO ARCHIVE - TACKLE AFTER TCP MIGRATION:
├── Visual Recreation (match original colors/fonts)
├── Animation Completion (green/blue/orange effects) 
├── Layer Visual Indicators (clear feedback)
├── Performance Tuning (match original speed)
├── Real Kanata Testing (end-to-end workflows)
└── Advanced Features (themes, customization)

RATIONALE: TCP migration is architectural foundation
Visual work is polish on top of solid architecture
```

## 🎯 **Immediate Next Steps**

### **Week 1: TCP Migration Focus**
1. **Day 1**: Remove cmd-enabled Kanata, install standard Homebrew version
2. **Day 1-2**: Research standard Kanata TCP capabilities and message formats
3. **Day 3-5**: Implement Swift TCP client (TCPKeyTracker)
4. **Day 6-7**: Update Kanata configs to remove cmd statements and use TCP

### **Week 2: Testing & Validation**
1. **Day 1-3**: Comprehensive TCP testing and performance validation
2. **Day 4-5**: Documentation updates and migration guides
3. **Day 6-7**: CI/CD pipeline updates for TCP testing

### **Future: Visual Polish (After TCP Complete)**
- Visual parity work becomes Phase 3
- Build on solid TCP foundation
- Focus on user experience improvements

## 🏆 **Expected Outcomes**

### **Immediate Benefits (TCP Migration)**
- **Eliminated Security Risk**: No more shell command execution
- **Better Performance**: Direct TCP vs process spawning
- **Standard Compatibility**: Works with any Kanata build
- **Improved Reliability**: TCP guarantees vs UDP best-effort
- **Cleaner Architecture**: Remove command execution complexity

### **Foundation for Future**
- Solid TCP base for visual enhancements
- Production-ready security posture
- Standard toolchain compatibility
- Performance optimized for real-world use

---

**Focus: Complete TCP migration first. Everything else builds on this foundation.** 🎯