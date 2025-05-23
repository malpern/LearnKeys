# LearnKeys - Dynamic Kanata Dashboard

LearnKeys is a SwiftUI application that creates a real-time visual dashboard for your kanata keyboard configuration. It parses your kanata config file and displays your key mappings dynamically, updating in real-time as you switch between layers.

## Features

### Core Functionality
- **Real-time Layer Tracking**: Connects to kanata's TCP server to show current active layer
- **Dynamic Key Mapping Display**: Shows tap/hold actions for each key based on your config
- **Visual Key Press Feedback**: Highlights keys as you press them with smooth animations
- **Command Line Interface**: Takes config file as argument, no GUI file loading
- **Second Monitor Support**: Automatically displays on secondary monitor if available
- **Quick Exit**: Command+Q or Command+W to quit
- **Process Management**: Handles multiple instances gracefully

### Visual Experience
- **Chromeless-Style UI**: Beautiful animated interface inspired by the chromeless.swift design
- **Animated Letter Row**: Large animated letters that scale and transform when pressed
- **3D Key Transformations**: Modifier keys tilt and blur when active
- **Arrow Key Effects**: Directional tilt animations for arrow keys
- **Layer-Based Display**: Shows only relevant keys for the current layer
- **Modern Styling**: Gradients, shadows, and smooth spring animations

### Keyboard Support
- **Home Row Modifiers**: Full support for tap-hold modifier keys
- **Layer Keys**: Visual indication of layer switching keys
- **Navigation Layers**: Arrow keys and vim-style navigation
- **Transparent Keys**: Proper handling of passthrough keys
- **Modifier Key Display**: Shows modifier symbols (⇧⌃⌥⌘☰) with proper mapping

## Why Dynamic Configuration?

### Advantages Over Hard-Coded Solutions

Unlike static SwiftUI implementations that require manual coding of each key mapping, LearnKeys offers significant advantages through its dynamic configuration approach:

#### 🔄 **Automatic Adaptation**
- **No Recompilation**: Change your kanata config and the visualization updates instantly
- **Zero Code Changes**: Works with any kanata configuration without modifying Swift code
- **Future-Proof**: Automatically supports new layouts, layers, and key mappings as you evolve your setup

#### 🎯 **Perfect Accuracy**
- **Source of Truth**: Shows exactly what your kanata config defines, eliminating discrepancies
- **Real-Time Sync**: Connects to kanata's TCP server to display the actual current layer
- **No Manual Maintenance**: Key mappings stay synchronized automatically with your config changes

#### 🛠️ **Ease of Use**
- **No Programming Required**: Update your keyboard layout without touching Swift code
- **Multiple Configs**: Switch between different configuration files for work, gaming, etc.
- **Command Line Flexibility**: Drop in any `.kbd` file as an argument

#### 🎨 **Dynamic Layout Intelligence**
- **Layer-Aware Display**: Shows only relevant keys for each layer, reducing visual clutter
- **Smart Key Detection**: Automatically identifies tap-hold modifiers, layer keys, and navigation mappings
- **Transparent Key Handling**: Hides passthrough keys (`_`) automatically

#### 🔧 **Configuration Flexibility**
- **Complex Parsing**: Handles multi-line expressions, nested aliases, and advanced kanata features
- **Any Layout Support**: Works with QWERTY, Dvorak, Colemak, or any custom layout
- **Modifier Combinations**: Automatically detects and displays complex modifier arrangements

#### 📈 **Scalability**
- **Large Configs**: Efficiently parses configs with dozens of layers and hundreds of key mappings
- **Performance**: Real-time updates without performance degradation
- **Memory Efficient**: Only loads and displays active layer information

**Example**: With a hard-coded solution, adding a new layer with vim navigation would require:
1. Writing new Swift code for each key mapping
2. Manually coding the layer switching logic  
3. Recompiling and testing the application
4. Maintaining two separate configurations (kanata + SwiftUI)

With LearnKeys, you simply add the layer to your kanata config and it appears automatically with full functionality.

## Requirements

- macOS (SwiftUI application)
- kanata running with TCP server enabled
- Accessibility permissions for key monitoring

## Quick Start

📋 **First time?** Read [`KANATA_CONFIG_GUIDE.md`](KANATA_CONFIG_GUIDE.md) for config best practices and troubleshooting.

## Setup

### 1. Configure Kanata with TCP Server

Add TCP server configuration to your kanata config file:

```lisp
(defcfg
  process-unmapped-keys yes
  concurrent-tap-hold yes
  ;; TCP server configuration:
  tcp-server-address 127.0.0.1:5829
)
```

**Note**: TCP server syntax varies by kanata version. Check your kanata documentation for the correct configuration.

### 2. Grant Accessibility Permissions

LearnKeys needs accessibility permissions to monitor key presses:

1. Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock to make changes
3. Add your terminal application (if running from terminal) or the LearnKeys app

### 3. Run LearnKeys

Compile and run the application with a config file:

```bash
swift learnkeys.swift config.kbd
```

Or use the convenient run script:

```bash
./run_learnkeys.sh [config-file.kbd]
```

## Usage

### Loading a Configuration

LearnKeys requires a kanata config file as a command line argument:

- `swift learnkeys.swift <config-file.kbd>` - Direct execution
- `./run_learnkeys.sh [config-file.kbd]` - If no file specified, tries `config.kbd` in current directory

### Understanding the Display

The interface is designed to show only the keys that matter for the current layer:

#### Base Layer
- **Animated Letter Row**: Shows A S D F G H J K L ; with smooth scaling animations
- **Modifier Row**: Displays home row modifiers with proper symbols and 3D effects
- **Connection Status**: Green/red indicator showing kanata TCP connection

#### Other Layers (e.g., F-Navigation)
- **Navigation Keys**: Shows only the keys that have mappings in the current layer
- **Arrow Keys**: Special section for directional navigation with tilt animations
- **Layer Indicator**: Yellow highlight showing the active layer name

### Visual Feedback

- **Key Press Animation**: Letters scale up dramatically when pressed
- **Modifier Effects**: 3D tilt and blur effects on modifier keys
- **Arrow Key Tilts**: Directional tilting based on arrow direction
- **Smooth Transitions**: Spring-based animations for all state changes

## Example Config Support

LearnKeys supports the key features from your sample config:

- **Home Row Modifiers**: `@a` (tap=a, hold=shift) with visual modifier symbols
- **Layer Keys**: `@f` (tap=f, hold=f-nav layer) with layer switching indication
- **Navigation Layers**: Shows arrow mappings and vim movements with arrows (←↓↑→)
- **Transparent Keys**: `_` keys are hidden from display
- **Multi-expression Parsing**: Properly handles complex multi-line alias definitions

## Configuration Structure

LearnKeys parses these kanata config sections:

- `(defsrc ...)` - Physical key layout
- `(deflayer name ...)` - Layer definitions  
- `(defalias ...)` - Key action definitions with tap-hold parsing
- `(defvar ...)` - Variables (timing, etc.)

### Advanced Parser Features

- **Multi-line Expression Support**: Handles complex nested expressions
- **Tap-Hold Detection**: Automatically identifies modifier and layer keys
- **Alias Resolution**: Resolves `@` references to show actual actions
- **Error Handling**: Graceful degradation for malformed configs

### Parser Limitations

- **Inline Comments**: `;;` comments mid-expression break parsing and cause alias loss
- **Complex Multi-Actions**: Only simple tap-hold patterns fully supported
- **Advanced Features**: Chords, sequences, macros not yet supported

📖 **For detailed configuration guidance, parser capabilities, and best practices, see [`KANATA_CONFIG_GUIDE.md`](KANATA_CONFIG_GUIDE.md)**

## Troubleshooting

### "Disconnected" Status

If the app shows "Disconnected":

1. Make sure kanata is running
2. Verify TCP server is enabled in your config
3. Test connection: `nc 127.0.0.1 5829`

### Keys Not Highlighting

1. Check accessibility permissions
2. Make sure your keys are defined in `defsrc`
3. Verify the app has the correct config loaded

### Config Not Loading

1. Ensure you're providing the correct file path as command line argument
2. Check file path and permissions
3. Verify config syntax (balanced parentheses)
4. **Check for inline comments** - `;;` comments mid-expression break parsing
5. Look for error messages in terminal - app will quit with error if config is invalid

⚠️ **Critical**: Avoid inline comments in your config! See `KANATA_CONFIG_GUIDE.md` for details.

### Multiple Processes

If Command+Q isn't working:

1. Check for multiple processes: `ps aux | grep learnkeys`
2. Kill old processes: `kill <PID>`
3. Relaunch the app

## Testing TCP Connection

Use the included test script:

```bash
./test_tcp.sh
```

This will verify kanata's TCP server is accessible and show layer change messages.

## Architecture

- **KanataConfigParser**: Advanced parser with multi-line expression support
- **KanataTCPClient**: Real-time TCP connection to kanata with JSON message parsing
- **GlobalKeyMonitor**: System-wide key monitoring with Command+Q handling
- **KeyCap**: Chromeless-style key visualization with 3D effects and animations
- **LearnKeysView**: Main dashboard with layer-based key filtering

## UI Components

### KeyCap Component
- **Styling**: Matches chromeless.swift exactly with gradients and borders
- **Animations**: 3D transformations and blur effects for modifiers
- **Arrow Effects**: Directional tilting for arrow keys
- **State Management**: Active/inactive visual states

### Layout System
- **Letter Row**: 10-slot animated letter display (A-;)
- **Modifier Row**: Home row modifiers with background panels
- **Arrow Section**: Dedicated arrow key cluster with proper spacing
- **Layer-Responsive**: Shows different content based on active layer

## Supported Key Types

- ✅ Basic keys (letters, numbers, symbols)
- ✅ Tap-hold modifiers (shift, ctrl, option, command) with visual symbols
- ✅ Layer toggle/switch keys with layer indicator
- ✅ Arrow keys and navigation with directional symbols (←↓↑→)
- ✅ Transparent keys (`_`) with proper hiding
- ✅ Complex multi-line alias definitions
- ✅ Page up/down, escape, space with proper symbols (⇞⇟⎋⎵)

## Performance Features

- **Efficient Parsing**: Single-pass config parser with proper tokenization
- **Real-time Updates**: Instant layer switching via TCP
- **Smooth Animations**: GPU-accelerated SwiftUI animations
- **Low Latency**: Direct system key monitoring for immediate feedback

## Files

- `learnkeys.swift` - Main application (1258 lines)
- `chromeless.swift` - Reference implementation for UI styling
- `config.kbd` - Example kanata configuration with TCP settings
- `run_learnkeys.sh` - Launch script with config argument handling
- `test_tcp.sh` - TCP connection test script
- `KANATA_CONFIG_GUIDE.md` - **Comprehensive guide for writing compatible configs**
- `README.md` - This documentation

## Recent Improvements

- **Fixed Parser Bug**: Resolved issue where multi-line expressions were combined incorrectly
- **Enhanced UI**: Implemented exact chromeless.swift styling and animations
- **Better Process Management**: Proper Command+Q handling and process cleanup
- **Improved Error Handling**: Clear error messages for missing configs
- **Layer Detection**: Smart filtering to show only relevant keys per layer
- **Configuration Guide**: Added comprehensive [`KANATA_CONFIG_GUIDE.md`](KANATA_CONFIG_GUIDE.md) with parser details and best practices
- **Fixed Key Duplication**: Resolved issue where keys (like space) were shown multiple times in base layer
- **Dynamic Container Sizing**: Background containers now properly size themselves based on actual key positions and config

## Known Issues

- **Comment Parsing**: Inline comments (`;;`) break expression parsing and cause alias loss
- **Advanced Features**: Chords, macros, and complex multi-actions not fully supported yet

*See [`KANATA_CONFIG_GUIDE.md`](KANATA_CONFIG_GUIDE.md) for detailed workarounds and future roadmap.*

---

*Note: This application replicates the visual experience of chromeless.swift while adding dynamic kanata config parsing and real-time layer switching. The UI shows only the keys that matter for each layer, creating a clean and focused learning experience.* 