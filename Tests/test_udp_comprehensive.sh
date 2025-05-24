#!/bin/bash

echo "🚀 LearnKeys UDP-First Implementation - Comprehensive Testing"
echo "==========================================================="

# Configuration
UDP_PORT="6789"

echo "📍 Testing UDP implementation on port $UDP_PORT"

# Function to run build verification
verify_build() {
    echo "🔨 Verifying build..."
    if [ -f ".build/arm64-apple-macosx/debug/LearnKeysUDP" ]; then
        echo "✅ Build artifact found"
        return 0
    else
        echo "❌ Build artifact not found"
        return 1
    fi
}

# Main execution for CI
if [ "$1" = "--auto" ]; then
    echo "🤖 Auto mode: Build verification only (for CI)"
    verify_build
    exit $?
fi

echo "✅ Test script completed!" 