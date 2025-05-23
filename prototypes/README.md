# Prototypes Archive

This directory contains prototype implementations that were used during development but have been superseded by the modular architecture in the main project.

## Files

### `chromeless.swift` (796 lines)
**Status**: PROTOTYPE - DEPRECATED  
**Created**: Early development phase  
**Superseded by**: `LearnKeys/` modular implementation  

This was the original monolithic prototype implementation of the keyboard visualizer. It contains:
- Single-file implementation with all components mixed together
- Original KeyCap component design
- Basic key monitoring and visualization
- SwiftUI proof-of-concept

**⚠️ DO NOT USE FOR DEVELOPMENT**

This file is kept for reference only. All active development should use the modular `LearnKeys/` implementation which provides:
- Better code organization
- Improved maintainability  
- Proper separation of concerns
- Full feature parity with better architecture

## Usage

These files are archived for historical reference only. To run the current application, use:

```bash
./run_learnkeys.sh [config.kbd]
```

Or the short form:
```bash
./lk [config.kbd]
```

## Development

For all development work, use the modular codebase in `LearnKeys/` directory. 