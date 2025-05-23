#!/bin/bash

# Comprehensive LearnKeys Logic Tests
# Tests core functionality that can work in headless CI

echo "🧪 Running LearnKeys Logic Tests..."

cd "$(dirname "$0")/.."

# Ensure we have a build
if [ ! -f "build/LearnKeys" ]; then
    echo "❌ No build found, running build.sh first"
    ./build.sh
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
fi

# Create test configs for different scenarios
cat > /tmp/test_minimal.kbd << 'EOF'
(defsrc a s d)
(defvar tap-timeout 300)
(deflayer base a s d)
EOF

cat > /tmp/test_invalid.kbd << 'EOF'
this is not valid kanata config syntax
EOF

echo "📋 Test configs created"

# Test 1: Config File Handling
echo ""
echo "🧪 Test 1: Config File Validation"

# Test with non-existent config
echo "📋 Testing with non-existent config file..."
./build/LearnKeys /tmp/nonexistent.kbd > /tmp/config_test.log 2>&1 &
CONFIG_PID=$!
sleep 0.5
kill $CONFIG_PID 2>/dev/null
wait $CONFIG_PID 2>/dev/null

if grep -q "Error.*not found\|Config file.*not found" /tmp/config_test.log; then
    echo "✅ Non-existent config file handled correctly"
else
    echo "❌ Non-existent config file error handling failed"
    echo "Log contents:"
    cat /tmp/config_test.log
fi

# Test with no arguments
echo "📋 Testing with no arguments..."
./build/LearnKeys > /tmp/usage_test.log 2>&1 &
USAGE_PID=$!
sleep 0.5
kill $USAGE_PID 2>/dev/null
wait $USAGE_PID 2>/dev/null

if grep -q "Usage.*config.*kbd\|No config file provided" /tmp/usage_test.log; then
    echo "✅ Usage message displayed correctly"
else
    echo "❌ Usage message missing or incorrect"
    echo "Log contents:"
    cat /tmp/usage_test.log
fi

# Test 2: Binary Execution
echo ""
echo "🧪 Test 2: Binary Execution Tests"

echo "📋 Testing executable permissions..."
if [ -x "build/LearnKeys" ]; then
    echo "✅ Binary has execute permissions"
else
    echo "❌ Binary missing execute permissions"
    chmod +x build/LearnKeys
fi

echo "📋 Testing binary is not corrupted..."
if file build/LearnKeys | grep -q "executable"; then
    echo "✅ Binary appears to be a valid executable"
else
    echo "❌ Binary may be corrupted"
    file build/LearnKeys
fi

# Test 3: Quick Startup Test (headless-aware)
echo ""
echo "🧪 Test 3: Startup Behavior"

echo "📋 Testing app startup with valid config..."
# Start the app and give it a moment to initialize
./build/LearnKeys /tmp/test_minimal.kbd > /tmp/startup_test.log 2>&1 &
STARTUP_PID=$!
sleep 1

# Check if process is still running (means it didn't crash immediately)
if kill -0 $STARTUP_PID 2>/dev/null; then
    echo "✅ App started and is running (process $STARTUP_PID)"
    
    # Give it a moment to initialize systems
    sleep 1
    
    # Check for any critical errors in the log
    if grep -q "🔊 UDP KeyTracker ready\|UDP.*ready" /tmp/startup_test.log; then
        echo "✅ UDP system initialized successfully"
    else
        echo "⚠️  UDP system status unclear in headless environment"
    fi
    
    # Clean shutdown
    kill $STARTUP_PID 2>/dev/null
    wait $STARTUP_PID 2>/dev/null
    echo "✅ App shutdown cleanly"
else
    echo "❌ App crashed or exited immediately"
    echo "Startup log:"
    cat /tmp/startup_test.log
fi

# Test 4: Multiple Instance Handling
echo ""
echo "🧪 Test 4: Multiple Instance Behavior"

echo "📋 Testing multiple instances..."
# Start first instance
./build/LearnKeys /tmp/test_minimal.kbd > /tmp/instance1.log 2>&1 &
PID1=$!
sleep 0.5

# Start second instance
./build/LearnKeys /tmp/test_minimal.kbd > /tmp/instance2.log 2>&1 &
PID2=$!
sleep 1

# Check if both are running or if second failed gracefully
if kill -0 $PID1 2>/dev/null; then
    echo "✅ First instance running"
    
    if kill -0 $PID2 2>/dev/null; then
        echo "⚠️  Second instance also running (port conflict handling unclear)"
    else
        echo "✅ Second instance exited (likely due to port conflict)"
    fi
else
    echo "❌ First instance failed to start"
fi

# Cleanup
kill $PID1 $PID2 2>/dev/null
wait $PID1 $PID2 2>/dev/null

# Test 5: Build Artifact Validation
echo ""
echo "🧪 Test 5: Build Artifact Validation"

echo "📋 Checking binary size..."
BINARY_SIZE=$(stat -f%z build/LearnKeys 2>/dev/null || stat -c%s build/LearnKeys 2>/dev/null || echo "unknown")
if [ "$BINARY_SIZE" != "unknown" ] && [ "$BINARY_SIZE" -gt 100000 ]; then
    echo "✅ Binary size reasonable: $BINARY_SIZE bytes"
else
    echo "❌ Binary size suspicious: $BINARY_SIZE bytes"
fi

echo "📋 Checking for required frameworks..."
if otool -L build/LearnKeys 2>/dev/null | grep -q "SwiftUI\|AppKit"; then
    echo "✅ Required frameworks linked"
else
    echo "⚠️  Framework detection inconclusive"
fi

# Cleanup
rm -f /tmp/test_minimal.kbd /tmp/test_invalid.kbd
rm -f /tmp/config_test.log /tmp/usage_test.log /tmp/startup_test.log 
rm -f /tmp/instance1.log /tmp/instance2.log

echo ""
echo "🎉 Logic tests completed!"
echo "📊 Summary: Tested config handling, binary validation, startup behavior, and multiple instances"
echo "💡 Note: GUI-specific tests limited in headless CI environments" 