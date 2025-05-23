# LearnKeys - Modular Swift Project

A well-architected Swift application for visualizing and learning Kanata keyboard configurations with real-time key monitoring and beautiful animations.

## 🏗️ Project Structure

The project has been refactored from a single large file into a clean, modular architecture following Swift best practices:

```
LearnKeys/
├── Models/                     # Data models and structures
│   ├── KanataConfig.swift     # Core config models (KanataConfig, KanataAlias)
│   └── KeyboardLayout.swift   # Layout models (KeyboardRow, KeyboardLayout, TemporaryKeyState)
├── Services/                  # Business logic and services
│   ├── KanataConfigParser.swift           # Kanata config file parsing
│   ├── KanataTCPClient.swift             # TCP communication with Kanata
│   ├── GlobalKeyMonitor.swift            # Key monitoring and event handling
│   └── GlobalKeyMonitor+Extensions.swift # Extended key monitoring functionality
├── Views/                     # SwiftUI views and UI components
│   ├── KeyCap.swift                      # Individual key rendering component
│   ├── LearnKeysView.swift              # Main dashboard view
│   ├── LearnKeysView+Extensions.swift    # View layout methods
│   └── LearnKeysView+Helpers.swift      # View helper and utility methods
├── Utils/                     # Utilities and extensions
│   ├── Extensions.swift       # Color extensions and utility functions
│   └── KeyCodeMapper.swift    # Key code mapping utilities
├── App/                       # Application setup and entry point
│   ├── AppDelegate.swift      # App delegate and window management
│   └── main.swift            # Application entry point
├── build.sh                  # Build script
└── README.md                 # This file
```

## 🚀 Building and Running

### Build the Project

```bash
cd LearnKeys
./build.sh
```

This will compile all Swift files in the correct order and create an executable at `build/LearnKeys`.

### Run the Application

```bash
./build/LearnKeys path/to/your/config.kbd
```

Example:
```bash
./build/LearnKeys ../config.kbd
```

## 🎯 Features

### Core Functionality
- **Real-time Key Visualization**: Live monitoring of key presses with beautiful animations
- **Layer Support**: Dynamic display of different Kanata layers with smooth transitions
- **Modifier Key Highlighting**: Visual feedback for modifier keys (Shift, Ctrl, Alt, Cmd)
- **TCP Integration**: Real-time communication with Kanata via TCP for layer changes

### Visual Features
- **Animated Letter Row**: Home row letters with scaling animations on key press
- **Smart Key Layout**: Intelligent positioning of keys based on physical layout
- **Temporary States**: Special visual states for layer keys
- **Background Grouping**: Visual grouping of related keys with backgrounds
- **Arrow Key Support**: Special handling and animations for arrow keys

### Architecture Benefits
- **Modular Design**: Clean separation of concerns across Models, Views, Services, and Utils
- **Maintainable Code**: Each component has a single responsibility
- **Extensible**: Easy to add new features or modify existing ones
- **Testable**: Services and utilities can be easily unit tested
- **Reusable**: Components can be reused across different parts of the app

## 📦 Dependencies

The project uses only built-in macOS frameworks:
- **SwiftUI**: UI framework
- **AppKit**: macOS application framework  
- **Network**: TCP networking
- **CoreGraphics**: Low-level graphics and event handling
- **Foundation**: Core utilities

## 🔧 Development

### Adding New Features

1. **Models**: Add new data structures to `Models/`
2. **Services**: Add business logic to `Services/`
3. **Views**: Add UI components to `Views/`
4. **Utils**: Add utilities to `Utils/`

### Key Components

- **KanataConfigParser**: Handles parsing of Kanata configuration files
- **GlobalKeyMonitor**: Manages global key event monitoring
- **KanataTCPClient**: Handles TCP communication with Kanata for layer changes
- **LearnKeysView**: Main UI component with keyboard visualization
- **KeyCap**: Individual key rendering with animations and state management

### Build Process

The `build.sh` script compiles files in dependency order:
1. Core utilities and extensions
2. Data models
3. Services (parsing, networking, monitoring)
4. Views (UI components)
5. App setup and entry point

## 🎨 Visual Design

The app maintains the original chromeless.swift visual style with:
- Dark theme with gradient backgrounds
- Smooth animations and transitions
- Professional key cap styling
- Real-time visual feedback
- Multi-monitor support

## 🚦 Usage Notes

- Requires a Kanata configuration file as command line argument
- Connects to Kanata TCP server on localhost:5829
- Supports Command+Q and Command+W to quit
- Displays on secondary monitor if available

## 🔍 Troubleshooting

- **Build Issues**: Ensure all Swift files are present and `build.sh` is executable
- **TCP Connection**: Verify Kanata is running with TCP enabled on port 5829
- **Key Detection**: Check that the app has accessibility permissions in System Preferences
- **Config Parsing**: Review config file syntax if parsing fails

## 📝 License

This project maintains the same license as the original LearnKeys implementation. 