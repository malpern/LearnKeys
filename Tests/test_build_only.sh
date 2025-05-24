#!/bin/bash

echo "🔨 LearnKeys UDP Build Verification"
echo "==================================="

# Check if build artifact exists
if [ -f ".build/arm64-apple-macosx/debug/LearnKeysUDP" ]; then
    echo "✅ Build artifact found: .build/arm64-apple-macosx/debug/LearnKeysUDP"
    ls -la .build/arm64-apple-macosx/debug/LearnKeysUDP
    echo "✅ Build verification passed!"
    exit 0
else
    echo "❌ Build artifact not found: .build/arm64-apple-macosx/debug/LearnKeysUDP"
    echo "💡 Run 'swift build' first"
    exit 1
fi 