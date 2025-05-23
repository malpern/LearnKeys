#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Building LearnKeys..."
echo "📍 Working from: $SCRIPT_DIR"

# Check for config file argument
if [ $# -eq 0 ]; then
    if [ -f "config.kbd" ]; then
        CONFIG_FILE="config.kbd"
        echo "📁 Using config.kbd from current directory"
    else
        echo "❌ Error: No config file provided and config.kbd not found"
        echo "Usage: $0 <config-file.kbd>"
        exit 1
    fi
else
    CONFIG_FILE="$1"
    # Handle both absolute and relative paths
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Error: Config file '$CONFIG_FILE' not found"
        echo "   Tried: $(realpath "$CONFIG_FILE" 2>/dev/null || echo "$CONFIG_FILE")"
        exit 1
    fi
    echo "📁 Using config file: $CONFIG_FILE"
fi

# Convert to absolute path to avoid issues when changing directories
CONFIG_FILE="$(realpath "$CONFIG_FILE")"
echo "📁 Full path: $CONFIG_FILE"

# Check if we're in the right directory structure
if [ ! -d "LearnKeys" ]; then
    echo "❌ Error: LearnKeys directory not found"
    echo "   Make sure you're running this script from the chromeless project root"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Check if kanata TCP server is available
if nc -z 127.0.0.1 5829 2>/dev/null; then
    echo "✅ Kanata TCP server detected on port 5829"
else
    echo "⚠️  Kanata TCP server not detected"
    echo "   Make sure kanata is running with TCP server enabled"
fi

echo ""
echo "🚀 Starting LearnKeys..."
echo "   - Grant accessibility permissions if prompted"
echo "   - Use Cmd+Q to quit"
echo "   - Will display on secondary monitor if available"
echo ""

# Build using the modular build system
echo "🔧 Building in LearnKeys directory..."
cd LearnKeys

if [ ! -f "build.sh" ]; then
    echo "❌ Error: build.sh not found in LearnKeys directory"
    exit 1
fi

./build.sh

# Check if build was successful
if [ ! -f "build/LearnKeys" ]; then
    echo "❌ Error: Build failed - executable not found at LearnKeys/build/LearnKeys"
    echo "   Check the build output above for errors"
    exit 1
fi

echo "✅ Build successful!"
echo "🚀 Launching LearnKeys with config: $CONFIG_FILE"

# Run with absolute config file path
./build/LearnKeys "$CONFIG_FILE" 