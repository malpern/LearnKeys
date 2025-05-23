#!/bin/bash

# LearnKeys Build Script
# Compiles the modular Swift project into a single executable

echo "🚀 Building LearnKeys..."

# Create output directory
mkdir -p build

# Find all Swift files in the correct order
SWIFT_FILES=""

# Core utilities and models first
SWIFT_FILES+="Utils/Extensions.swift "
SWIFT_FILES+="Utils/KeyCodeMapper.swift "
SWIFT_FILES+="Models/KanataConfig.swift "
SWIFT_FILES+="Models/KeyboardLayout.swift "

# Services
SWIFT_FILES+="Services/KanataConfigParser.swift "
SWIFT_FILES+="Services/KanataTCPClient.swift "
SWIFT_FILES+="Services/GlobalKeyMonitor.swift "
SWIFT_FILES+="Services/GlobalKeyMonitor+Extensions.swift "

# Views  
SWIFT_FILES+="Views/KeyCap.swift "
SWIFT_FILES+="Views/LearnKeysView.swift "
SWIFT_FILES+="Views/LearnKeysView+Extensions.swift "
SWIFT_FILES+="Views/LearnKeysView+Helpers.swift "

# App entry point last
SWIFT_FILES+="App/AppDelegate.swift "
SWIFT_FILES+="App/main.swift "

# Compile with SwiftUI and networking frameworks
swiftc -o build/LearnKeys \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework CoreGraphics \
  $SWIFT_FILES

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Executable created at build/LearnKeys"
    echo ""
    echo "Usage: ./build/LearnKeys <config-file.kbd>"
    echo "Example: ./build/LearnKeys ../config.kbd"
else
    echo "❌ Build failed!"
    exit 1
fi 