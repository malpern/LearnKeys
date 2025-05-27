#!/bin/bash

echo "🔨 LearnKeys UDP Build Verification"
echo "==================================="

# Check if build artifact exists in the LearnKeysUDP-Clean directory
if [ -f "LearnKeysUDP-Clean/.build/arm64-apple-macosx/debug/LearnKeysUDP" ]; then
    echo "✅ Build artifact found: LearnKeysUDP-Clean/.build/arm64-apple-macosx/debug/LearnKeysUDP"
    ls -la LearnKeysUDP-Clean/.build/arm64-apple-macosx/debug/LearnKeysUDP
    echo "✅ Build verification passed!"
    exit 0
else
    echo "❌ Build artifact not found: LearnKeysUDP-Clean/.build/arm64-apple-macosx/debug/LearnKeysUDP"
    echo "💡 Run 'cd LearnKeysUDP-Clean && swift build' first"
    echo "📂 Available build directories:"
    find LearnKeysUDP-Clean -name ".build" -type d 2>/dev/null || echo "No .build directories found"
    exit 1
fi 