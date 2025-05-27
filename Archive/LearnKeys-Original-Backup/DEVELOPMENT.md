# LearnKeys - Development Documentation

This directory contains the modular Swift implementation of LearnKeys, a real-time keyboard layout visualizer for Kanata configurations.

## 🏗️ Architecture

This is a clean, modular Swift application following best practices with proper separation of concerns.

### Directory Structure

```
LearnKeys/
├── App/                        # Application lifecycle
│   ├── AppDelegate.swift      # Window management and app setup
│   └── main.swift            # Application entry point
├── Models/                     # Data structures
│   ├── KanataConfig.swift    # Configuration models
│   └── KeyboardLayout.swift  # Layout and visual state models
├── Services/                   # Business logic
│   ├── KanataConfigParser.swift      # Config file parsing
│   ├── KanataTCPClient.swift        # Network communication
│   ├── GlobalKeyMonitor.swift      # Key monitoring core
│   └── GlobalKeyMonitor+Extensions.swift # Extended monitoring
├── Views/                      # UI components
│   ├── KeyCap.swift          # Individual key rendering
│   ├── LearnKeysView.swift   # Main view structure
│   ├── LearnKeysView+Extensions.swift   # Layout methods
│   └── LearnKeysView+Helpers.swift     # Utility methods
├── Utils/                      # Utilities and extensions
│   ├── Extensions.swift      # Color utilities and helpers
│   └── KeyCodeMapper.swift   # Key code mapping
├── build/                      # Build output
│   └── LearnKeys             # Compiled executable
├── build.sh                   # Build script
├── config.kbd                 # Default kanata configuration
└── README.md                  # This file
```

## 🔧 Building and Development

### Prerequisites
- macOS 14.5+
- Swift compiler (comes with Xcode or Command Line Tools)
- Kanata with TCP server support

### Building
```bash
# From the LearnKeys directory
./build.sh

# Run with a config file
./build/LearnKeys config.kbd
```

### Development Workflow
```bash
# From project root - this is the main way to build and run
./lk [config-file.kbd]

# For development in LearnKeys directory
cd LearnKeys
./build.sh
./build/LearnKeys config.kbd
```

## 📋 Component Responsibilities

### Models/
- **KanataConfig.swift**: Core data structures for configuration parsing
- **KeyboardLayout.swift**: Visual state management and layout definitions

### Services/
- **KanataConfigParser.swift**: Advanced multi-line expression parser for kanata configs
- **KanataTCPClient.swift**: Real-time TCP connection to kanata with JSON message handling
- **GlobalKeyMonitor.swift**: System-wide key monitoring with accessibility integration
- **GlobalKeyMonitor+Extensions.swift**: Extended monitoring features

### Views/
- **KeyCap.swift**: Individual key component with 3D animations and styling
- **LearnKeysView.swift**: Main view coordinator and state management
- **LearnKeysView+Extensions.swift**: Layout calculations and positioning
- **LearnKeysView+Helpers.swift**: Utility methods and helper functions

### Utils/
- **Extensions.swift**: Color utilities, helper extensions for SwiftUI
- **KeyCodeMapper.swift**: Key code to key name mapping functionality

### App/
- **AppDelegate.swift**: Window management, menu setup, display positioning
- **main.swift**: Application entry point with NSApplication configuration

## 🎨 UI Architecture

### Design Principles
- **Layer-Responsive**: Different layouts for different kanata layers
- **Animated Feedback**: Spring-based animations for all interactions
- **Modular Components**: Reusable KeyCap components with configurable styling
- **3D Effects**: Tilt, blur, and gradient effects for visual polish

### KeyCap Component Features
- Configurable as modifier key or arrow key
- 3D tilt animations based on key type and direction
- Active state with background/border changes
- Symbol display for modifier keys (⇧⌃⌥⌘)
- Temporary state support for special effects

### Layout System
- **Letter Row**: 10-slot animated display for home row (A-;)
- **Modifier Row**: Background grouped modifier keys with proper spacing
- **Arrow Section**: Dedicated cluster for navigation keys
- **Dynamic Filtering**: Shows only relevant keys for active layer

## 🔗 Dependencies

### System Frameworks
- **SwiftUI**: Modern declarative UI framework
- **AppKit**: Window management and system integration
- **Network**: TCP client for kanata communication
- **CoreGraphics**: Low-level graphics and event monitoring

### External Dependencies
- **None**: Pure Swift implementation with only system frameworks

## 🧪 Testing

### Manual Testing
```bash
# Test TCP connection
nc 127.0.0.1 5829

# Test with different configs
./lk examples/qwerty.kbd
./lk examples/colemak.kbd
```

### Configuration Testing
- Test with various kanata config formats
- Verify layer switching works correctly
- Check modifier key highlighting
- Validate arrow key directional tilts

## 🚀 Performance Characteristics

### Efficient Design
- **Single-pass parsing**: Config parsed once at startup
- **Real-time updates**: Instant layer switching via TCP
- **GPU acceleration**: SwiftUI animations use Core Animation
- **Low latency**: Direct system key monitoring

### Resource Usage
- Minimal CPU usage when idle
- Small memory footprint (~10-20MB)
- No disk I/O during runtime
- Efficient network handling

## 🛠️ Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use clear, descriptive naming
- Prefer composition over inheritance
- Keep functions focused and small

### Architecture Patterns
- **MVVM-style**: Views observe model state
- **Service Layer**: Business logic isolated from UI
- **Dependency Injection**: Services passed to views as needed
- **Extension-based Organization**: Large files split via extensions

### Adding Features

1. **New Key Types**: Extend KeyCap component with new styling
2. **Parser Features**: Modify KanataConfigParser for new syntax
3. **UI Components**: Add to Views/ with proper separation
4. **Network Features**: Extend KanataTCPClient for new message types

## 📝 Build System

The `build.sh` script handles:
- Dependency resolution
- Compilation order
- Framework linking
- Output organization
- Error reporting

### Build Process
1. Create build directory
2. Compile in dependency order: Utils → Models → Services → Views → App
3. Link required frameworks
4. Generate executable

## 🔄 Migration from Prototype

This modular implementation replaced a 796-line monolithic prototype (`prototypes/chromeless.swift`). Key improvements:

- **Maintainability**: Each file has single responsibility
- **Testability**: Services can be unit tested in isolation
- **Extensibility**: Clear extension points for new features
- **Team Development**: Multiple developers can work simultaneously

## 📚 References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [Kanata Configuration Guide](../docs/KANATA_CONFIG_GUIDE.md)

---

For user-facing documentation and quick start guide, see the main [README.md](../README.md). 