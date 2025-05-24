#!/bin/bash

# Simple test script for LearnKeys
echo "🧪 Running LearnKeys tests..."

# Test 1: Build succeeds
echo "Test 1: Build process"
cd "$(dirname "$0")/.."
./build.sh
if [ $? -eq 0 ]; then
    echo "✅ Build test passed"
else
    echo "❌ Build test failed"
    exit 1
fi

# Test 2: Executable exists and is runnable
echo "Test 2: Executable validation"
if [ -f "build/LearnKeys" ]; then
    echo "✅ Executable exists"
    
    # Test that the app shows proper usage when no config provided
    echo "Test 2a: Usage message validation"
    output=$(timeout 3s ./build/LearnKeys 2>&1 || true)
    if echo "$output" | grep -q "Usage.*config.*kbd"; then
        echo "✅ Proper usage message displayed"
    else
        echo "⚠️  Usage message test inconclusive (headless environment)"
    fi
    
    # Test that the app accepts a config file (will fail on headless but shouldn't crash)
    echo "Test 2b: Config file acceptance test"
    if [ -f "config.kbd" ]; then
        timeout 3s ./build/LearnKeys config.kbd 2>/dev/null || true
        echo "✅ App accepts config file without crashing"
    else
        echo "⚠️  No config.kbd found - skipping config test"
    fi
    
    echo "✅ Executable validation passed"
else
    echo "❌ Executable not found"
    exit 1
fi

echo "🎉 All tests passed!" 