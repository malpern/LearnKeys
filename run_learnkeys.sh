#!/bin/bash

echo "🔨 Building LearnKeys..."

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
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Error: Config file '$CONFIG_FILE' not found"
        exit 1
    fi
    echo "📁 Using config file: $CONFIG_FILE"
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

# Compile and run with config file argument
swift learnkeys.swift "$CONFIG_FILE" 