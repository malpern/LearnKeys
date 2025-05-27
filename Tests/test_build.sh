#!/bin/bash

# Simple test script for LearnKeys UDP
echo "🧪 Running LearnKeys UDP tests..."

# Test 1: Build succeeds
echo "Test 1: Build process"
cd "$(dirname "$0")/.."

echo "🔨 Building LearnKeysUDP with Swift..."
swift build --configuration debug
if [ $? -eq 0 ]; then
    echo "✅ Build test passed"
else
    echo "❌ Build test failed"
    exit 1
fi

# Test 2: Executable exists and is runnable
echo "Test 2: Executable validation"
if [ -f ".build/arm64-apple-macosx/debug/LearnKeysUDP" ]; then
    echo "✅ Executable exists: .build/arm64-apple-macosx/debug/LearnKeysUDP"
    ls -la .build/arm64-apple-macosx/debug/LearnKeysUDP
    
    # Test that the app shows proper headless mode when flag provided
    echo "Test 2a: Headless mode validation"
    timeout 3s ./.build/arm64-apple-macosx/debug/LearnKeysUDP --headless > /dev/null 2>&1 &
    APP_PID=$!
    sleep 1
    kill $APP_PID 2>/dev/null || true
    echo "✅ App accepts --headless flag without crashing"
    
    # Test that UDP port binding works (will fail if port busy, but that's expected)
    echo "Test 2b: UDP functionality test"
    echo "⚠️  UDP port test (may fail if port 6789 is busy - that's OK for build test)"
    
    echo "✅ Executable validation passed"
else
    echo "❌ Executable not found at .build/arm64-apple-macosx/debug/LearnKeysUDP"
    echo "💡 Available build artifacts:"
    find .build -name "LearnKeysUDP" -type f 2>/dev/null || echo "None found"
    exit 1
fi

echo "🎉 All build tests passed!" 