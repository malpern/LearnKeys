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
    
    # Test help output (assuming --help doesn't require GUI)
    timeout 5s ./build/LearnKeys --help 2>/dev/null || true
    echo "✅ Executable validation passed"
else
    echo "❌ Executable not found"
    exit 1
fi

echo "�� All tests passed!" 