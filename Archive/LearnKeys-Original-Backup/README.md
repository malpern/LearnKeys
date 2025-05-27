# LearnKeys - Keyboard Layout Visualizer

A real-time keyboard layout visualizer for Kanata configurations with beautiful animations and layer switching support.

![LearnKeys Demo](https://img.shields.io/badge/Platform-macOS-blue) ![Swift](https://img.shields.io/badge/Language-Swift-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **Real-time Key Visualization**: See your keystrokes with smooth animations
- **Layer Support**: Dynamic layer switching with visual feedback  
- **Home Row Modifiers**: Clear visualization of modifier key states
- **Beautiful UI**: Modern SwiftUI interface with 3D effects and animations
- **Kanata Integration**: Live TCP connection to Kanata for real-time updates
- **Smart Layout**: Shows only relevant keys for each layer

## 🚀 Quick Start

### Prerequisites
- macOS 14.5+ (tested)
- Swift compiler
- Kanata running with TCP server enabled

### Installation & Setup

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd chromeless
   ```

2. **Configure Kanata** - Add TCP server to your kanata config:
   ```lisp
   (defcfg
     process-unmapped-keys yes
     concurrent-tap-hold yes
     tcp-server-address 127.0.0.1:5829
   )
   ```

3. **Grant Accessibility Permissions**:
   - Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
   - Add your terminal application or the LearnKeys app

4. **Run LearnKeys**:
   ```bash
   # Quick start with default config
   ./lk
   
   # Or specify a custom config
   ./lk path/to/your/config.kbd
   ```

## 📖 Usage

### Basic Controls
- **Cmd+Q**: Quit the application
- **Cmd+W**: Close window (also quits)
- **Mouse drag**: Move the overlay window

### Understanding the Display

**Base Layer**: Shows animated letter row (A-S-D-F-G-H-J-K-L-;) with modifier row below
**Navigation Layers**: Displays only mapped keys with directional arrows
**Layer Indicator**: Yellow highlight shows active layer name

### Visual Feedback
- **Key Press Animation**: Letters scale dramatically when pressed
- **3D Modifier Effects**: Tilt and blur effects on modifier keys  
- **Arrow Directional Tilts**: Arrow keys tilt based on direction
- **Smooth Transitions**: Spring-based animations throughout

## 🏗️ Project Structure

```
LearnKeys/                  # Modern modular Swift application
├── App/                   # Application lifecycle
├── Models/                # Data structures
├── Services/              # Business logic (parsing, networking, monitoring)
├── Views/                 # UI components
├── Utils/                 # Utilities and extensions
├── build.sh              # Build script
└── config.kbd            # Default kanata configuration

prototypes/                # Archived prototype implementations
├── chromeless.swift      # Original monolithic prototype (DEPRECATED)
└── README.md            # Prototype documentation

docs/                     # Documentation
├── KANATA_CONFIG_GUIDE.md
└── MCP_SETUP.md
```

## 🔧 Development

### Building Manually
```bash
cd LearnKeys
./build.sh
./build/LearnKeys config.kbd
```

### Configuration Support
LearnKeys parses these kanata sections:
- `(defsrc ...)` - Physical key layout
- `(deflayer ...)` - Layer definitions  
- `(defalias ...)` - Key actions with tap-hold parsing
- `(defvar ...)` - Variables and timing

## 📚 Documentation

- **[Kanata Configuration Guide](docs/KANATA_CONFIG_GUIDE.md)** - Comprehensive kanata setup and best practices
- **[MCP Setup Guide](docs/MCP_SETUP.md)** - Screenshot server setup for development tools
- **[Prototypes](prototypes/README.md)** - Historical prototype implementations

## 🐛 Troubleshooting

### "Disconnected" Status
1. Ensure kanata is running
2. Verify TCP server in config: `tcp-server-address 127.0.0.1:5829`
3. Test connection: `nc 127.0.0.1 5829`

### Keys Not Highlighting  
1. Check accessibility permissions
2. Verify keys in `defsrc` section
3. Confirm config file loaded correctly

### Config Parsing Issues
1. **Avoid inline comments**: `;;` mid-expression breaks parsing
2. Check balanced parentheses
3. See [Kanata Configuration Guide](docs/KANATA_CONFIG_GUIDE.md) for best practices

## 🔮 Future Improvements

### Parser Enhancement
- **[ ] Switch to Official Rust Kanata Parser**: Replace custom Swift parser with official kanata parser to support:
  - Multi-line configuration formats (prettier, more readable configs)
  - Full kanata syntax compatibility 
  - Advanced features like chords, sequences, and complex expressions
  - Better error reporting and validation

### Kanata Integration Improvements  
- **[ ] Submit Feature Request to Kanata**: Request ability to define default UDP server configuration:
  ```lisp
  (defcfg
    udp-server-address 127.0.0.1:6789  ;; Default UDP endpoint
    udp-notifications yes              ;; Enable UDP notifications
  )
  
  ;; Then simple UDP tracking without repetition:
  (defalias
    a (tap-hold-release-keys 200 150 (multi a @tap (udp-notify keypress:a)) @shift)
    s (tap-hold-release-keys 200 150 (multi s @tap (udp-notify keypress:s)) @control)
  )
  ```
  This would eliminate the need to repeat `(cmd echo "keypress:key" | nc -u 127.0.0.1 6789)` for every key

### Additional Enhancements
- **[ ] Real-time Config Reloading**: Hot-reload configuration changes without restart
- **[ ] Visual Config Editor**: GUI editor for creating and modifying kanata configurations
- **[ ] Performance Analytics**: Track typing speed, accuracy, and key usage patterns
- **[ ] Custom Animation Themes**: User-defined color schemes and animation styles

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Work in the `LearnKeys/` modular codebase
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

---

**Note**: This project evolved from a prototype (`prototypes/chromeless.swift`) into a professional modular architecture. All active development uses the `LearnKeys/` directory structure. # Test keychain

# LearnKeys UDP-First

A clean, simple rewrite of LearnKeys using a **UDP-first architecture**.

## 🎯 **Key Benefits**

- ✅ **No Accessibility Permissions**: Uses UDP messages from Kanata instead of system key monitoring
- ✅ **Simple Architecture**: Single source of truth (UDP) drives all animations  
- ✅ **Reliable**: Direct messages from Kanata, no OS interference
- ✅ **Easy Testing**: Send UDP messages manually to test any scenario
- ✅ **Better Performance**: No OS-level key monitoring overhead

## 🏗️ **Architecture**

```
LearnKeysUDP/
├── App/                    # Minimal app structure
├── Core/                   # UDP-driven logic
│   ├── AnimationController # Single source of truth
│   └── UDPKeyTracker      # UDP message handling
├── Views/                  # Simple SwiftUI views
│   ├── KeyboardView       # Main keyboard display
│   └── KeyView           # Individual key with animations
├── Models/                 # Simple data models
└── Utils/                  # Helper utilities
```

## 🚀 **How It Works**

1. **Kanata sends UDP messages** for every key event:
   ```
   keypress:a              → Key press animation
   modifier:shift:down     → Modifier state change
   navkey:h               → Navigation animation
   layer:f-nav            → Layer transition
   ```

2. **AnimationController** receives UDP messages and updates state
3. **SwiftUI Views** automatically react to state changes
4. **No complex fallback logic** or multiple data sources

## 🧪 **Testing**

The app includes built-in test controls. You can also test manually:

```bash
# Test key press
printf "keypress:a\n" | nc -u -w 1 127.0.0.1 6789

# Test modifier
printf "modifier:shift:down\n" | nc -u -w 1 127.0.0.1 6789

# Test navigation
printf "navkey:h\n" | nc -u -w 1 127.0.0.1 6789
```

## 🔧 **Building**

```bash
swift build
swift run LearnKeysUDP
```

## 📋 **Kanata Configuration**

Your Kanata config needs UDP messages for the keys you want to track:

```kanata
;; Regular key with UDP
a (multi a (cmd echo "keypress:a" | nc -u 127.0.0.1 6789))

;; Modifier with UDP  
a (tap-hold-release-keys 200 150 
  (multi a (cmd echo "keypress:a" | nc -u 127.0.0.1 6789))
  (multi lsft (cmd echo "modifier:shift:down" | nc -u 127.0.0.1 6789))
  (a s d f g))
```

## 🎉 **Result**

A much simpler, more reliable LearnKeys that:
- Requires no special permissions
- Has predictable, consistent behavior  
- Is easy to test and debug
- Performs better than the complex multi-source original
