# LearnKeys UDP-First Implementation

![Build Status](https://github.com/malpern/LearnKeys/actions/workflows/swift.yml/badge.svg)

**Status:** ✅ **Phase 1 FULLY VERIFIED** - Production-ready UDP-driven keyboard visualizer with CI/CD

## 🚀 Quick Start

```bash
# Build the application
cd LearnKeysUDP-Clean
swift build

# Run with GUI (normal mode)
.build/arm64-apple-macosx/debug/LearnKeysUDP

# Run headless (for CI/testing - no GUI)
.build/arm64-apple-macosx/debug/LearnKeysUDP --headless

# Test UDP messages (in another terminal)
printf "keypress:a\n" | nc -u -w 1 127.0.0.1 6789
printf "navkey:h\n" | nc -u -w 1 127.0.0.1 6789  
printf "modifier:shift:down\n" | nc -u -w 1 127.0.0.1 6789
```

## 🎯 What This Is

A **clean, UDP-first reimplementation** of LearnKeys that:

- ✅ **No accessibility permissions** required
- ✅ **Single source of truth** - all events via UDP
- ✅ **Real-time animations** for key presses, navigation, and modifiers
- ✅ **Production-ready** with comprehensive logging and error handling
- ✅ **Easy testing** via manual UDP messages

## 📡 UDP Message Types

| Message | Description | Visual Effect |
|---------|-------------|---------------|
| `keypress:KEY` | Regular key press | 🟢 Green animation |
| `navkey:KEY` | Navigation key | 🔵 Blue animation |
| `modifier:MOD:down` | Modifier activation | 🟠 Orange highlighting |
| `modifier:MOD:up` | Modifier deactivation | ⚫ Return to normal |
| `layer:LAYER` | Layer change | 🎚️ Layer indicator update |
| `combo:KEY+KEY` | Key combination | 🔗 Multiple key animation |

## 🏗️ Architecture

```
LearnKeysUDP-Clean/
├── App/LearnKeysUDPApp.swift        # SwiftUI app entry point
├── Core/
│   ├── UDPKeyTracker.swift          # Primary UDP input system
│   ├── AnimationController.swift    # Single source of truth
│   └── LayerManager.swift           # Layer state management
├── Views/
│   ├── KeyboardView.swift           # Main keyboard display
│   ├── KeyView.swift                # Individual key with animations
│   └── LayerIndicator.swift         # Layer status display
├── Models/
│   ├── KeyState.swift               # Key state model
│   └── KanataConfig.swift           # Configuration parsing
└── Utils/
    ├── KeyCodeMapper.swift          # Key mapping utilities
    └── LogManager.swift             # Logging system
```

## 📊 Logging

### Console Logging
Real-time timestamped output with categories:
```
[2025-05-23T17:30:15Z] [INIT] 🎯 UDP-First KeyTracker ready on port 6789
[2025-05-23T17:30:20Z] [UDP] 📨 Received: keypress:a
[2025-05-23T17:30:20Z] [KEY] ⌨️ Key press: a
[2025-05-23T17:30:20Z] [ANIM] 🎨 Animating key press: a (type: regular)
```

### File Logging
- **Location:** `~/Documents/LearnKeysUDP.log`
- **Format:** Same as console with timestamps
- **Rotation:** Appends to existing file

### Configuration
```bash
# Disable console logging
LOG_CONSOLE=false swift run LearnKeysUDP

# Disable file logging  
LOG_FILE=false swift run LearnKeysUDP
```

## 🧪 Testing

### Headless Mode (CI/Testing)
Perfect for automated testing and CI environments:

```bash
# Start headless UDP server (no GUI)
.build/arm64-apple-macosx/debug/LearnKeysUDP --headless &

# Test all message types
echo "keypress:a" | nc -u -w 1 127.0.0.1 6789
echo "navkey:h" | nc -u -w 1 127.0.0.1 6789
echo "modifier:shift:down" | nc -u -w 1 127.0.0.1 6789
echo "layer:f-nav" | nc -u -w 1 127.0.0.1 6789

# Check processing in logs
tail ~/Documents/LearnKeysUDP.log
```

**Headless Mode Features:**
- ✅ No GUI dependencies - perfect for CI
- ✅ Full UDP message processing
- ✅ Comprehensive logging for verification
- ✅ All callbacks fire with `HEADLESS:` prefix
- ✅ Graceful signal handling (SIGINT/SIGTERM)

### Manual UDP Testing
```bash
# Basic key press
printf "keypress:a\n" | nc -u -w 1 127.0.0.1 6789

# Navigation key (blue)
printf "navkey:h\n" | nc -u -w 1 127.0.0.1 6789

# Modifier activation (orange)
printf "modifier:shift:down\n" | nc -u -w 1 127.0.0.1 6789

# Layer change
printf "layer:f-nav\n" | nc -u -w 1 127.0.0.1 6789

# Multiple keys
printf "keypress:a\nkeypress:s\nkeypress:d\n" | nc -u -w 1 127.0.0.1 6789
```

### Built-in Test Controls
The app includes test buttons for common UDP message types.

## 🎯 Phase 1 Achievements

✅ **Architecture Simplification**
- Replaced complex multi-source input with single UDP source
- Eliminated accessibility API dependencies
- Single source of truth for all animations

✅ **Real-time Performance**  
- Instant UDP message → UI animation updates
- Smooth, consistent animation timing
- No polling or event monitoring overhead

✅ **Production Quality**
- Comprehensive error handling and validation
- File and console logging with categories
- Clean separation of concerns
- 100% testable via UDP messages

## 🚀 Next Steps

### Phase 2: Full UI Recreation (Ready)
- Enhanced visual design and layouts
- Complete feature parity with original
- Advanced animation effects
- Multiple layer support

### Phase 3: Enhanced UDP Features (Future)
- Rich message types with duration/speed/pressure
- Advanced animation mapping
- Custom transition effects

## 🔗 Integration

### With Kanata
Add UDP output to your Kanata configuration:
```lisp
;; In your .kbd file
(defcfg
  process-unmapped-keys yes
  ;; ... other config
  danger-enable-cmd yes  ;; Required for UDP output
)

;; Add UDP notifications for key events
(deflayer base
  (tap-hold 200 200 a (cmd "printf 'keypress:a\n' | nc -u -w 1 127.0.0.1 6789"))
  ;; ... other keys
)
```

### Development
```bash
# Build for development
swift build

# Build for release
swift build --configuration release

# Run comprehensive test suite
cd Tests
./test_udp_functional.sh  # Full UDP functional tests
./test_build_only.sh      # Build verification only

# Run headless for CI/testing
.build/arm64-apple-macosx/debug/LearnKeysUDP --headless
```

### CI/CD Pipeline
- ✅ **Automated builds** on every push/PR
- ✅ **Headless UDP testing** with full functional verification
- ✅ **Architecture compliance** checks
- ✅ **Multi-configuration builds** (debug + release)
- ✅ **Test artifact archiving** with logs

---

**The UDP-first architecture has delivered on all promises: simpler, more reliable, and easier to maintain while providing better performance and user experience.** 🎉 