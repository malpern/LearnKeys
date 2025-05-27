#!/bin/bash

# Full TCP No-Fork Test Suite
# Comprehensive test of the layer switching approach with TCP

set -e

echo "🚀 Full TCP No-Fork Test Suite"
echo "=" * 60
echo ""
echo "🎯 Testing the breakthrough layer switching solution"
echo "🔧 This test will:"
echo "   1. Stop any running Kanata processes"
echo "   2. Start Kanata with the no-fork TCP configuration"
echo "   3. Run the TCP test harness"
echo "   4. Analyze results for modifier balance"
echo ""

# Check if we're in the right directory
if [ ! -f "tcp_test_harness.swift" ]; then
    echo "❌ Error: tcp_test_harness.swift not found"
    echo "💡 Run this script from the Tests directory"
    exit 1
fi

# Check if config file exists
if [ ! -f "../LearnKeysUDP-Clean/config.kbd" ]; then
    echo "❌ Error: config.kbd not found"
    echo "💡 Make sure you're in the Tests directory of the LearnKeys project"
    exit 1
fi

echo "🛑 Stopping any existing Kanata processes..."
sudo pkill -f kanata || true
sleep 2

echo "🔍 Checking if CMD-enabled Kanata is available..."
if command -v kanata &> /dev/null; then
    KANATA_PATH=$(which kanata)
    echo "✅ Found Kanata at: $KANATA_PATH"
    
    # Check if it supports CMD
    if strings "$KANATA_PATH" | grep -q "cmd is not enabled"; then
        echo "⚠️  Standard Kanata binary detected (no CMD support)"
        echo "💡 For full testing, consider using kanata_macos_cmd_allowed_arm64"
    else
        echo "✅ CMD-enabled Kanata binary detected"
    fi
else
    echo "❌ Kanata not found in PATH"
    echo "💡 Install Kanata or add it to your PATH"
    exit 1
fi

echo ""
echo "🚀 Starting Kanata with no-fork TCP configuration..."
echo "📁 Config: ../LearnKeysUDP-Clean/config.kbd"
echo "🔌 TCP Port: 6790"
echo ""

# Start Kanata in background
cd ../LearnKeysUDP-Clean
sudo kanata --cfg config.kbd &
KANATA_PID=$!
cd ../Tests

# Wait for Kanata to start
echo "⏳ Waiting for Kanata to initialize..."
sleep 3

# Check if Kanata is running
if ! kill -0 $KANATA_PID 2>/dev/null; then
    echo "❌ Kanata failed to start"
    echo "💡 Check the configuration file for syntax errors"
    exit 1
fi

echo "✅ Kanata started (PID: $KANATA_PID)"

# Wait for TCP port to be available
echo "🔍 Waiting for TCP port 6790..."
for i in {1..10}; do
    if nc -z 127.0.0.1 6790 2>/dev/null; then
        echo "✅ TCP port 6790 is ready"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ TCP port 6790 not responding after 10 seconds"
        echo "🛑 Stopping Kanata..."
        sudo kill $KANATA_PID
        exit 1
    fi
    sleep 1
done

echo ""
echo "🧪 Starting TCP Test Harness..."
echo "⏱️  Test duration: 30 seconds"
echo ""
echo "📋 TESTING INSTRUCTIONS:"
echo "   🎯 CRITICAL TEST: Hold 'a' key for 1 second, then release"
echo "   ✅ Expected: keypress:a, modifier:shift:down, modifier:shift:up"
echo "   🔄 Repeat with: s(ctrl), d(option), g(cmd), j(cmd), k(option), l(ctrl), ;(shift)"
echo "   📊 Success = Equal downs and ups (balance = 0)"
echo ""
echo "🚨 BREAKTHROUGH TEST: This proves layer switching works!"
echo "   - If you see UP events: ✅ No-fork solution SUCCESS"
echo "   - If no UP events: ❌ Layer switching failed"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Cleaning up..."
    if kill -0 $KANATA_PID 2>/dev/null; then
        echo "🛑 Stopping Kanata (PID: $KANATA_PID)..."
        sudo kill $KANATA_PID
        sleep 2
    fi
    echo "✅ Cleanup complete"
}

# Set trap for cleanup
trap cleanup EXIT

# Run the test harness
echo "🔨 Compiling and running TCP test harness..."
if swift tcp_test_harness.swift; then
    echo ""
    echo "🎉 TEST COMPLETED SUCCESSFULLY!"
    echo ""
    echo "📊 ANALYSIS GUIDE:"
    echo "   ✅ Balance = 0: Perfect! No stuck modifiers"
    echo "   ⚠️  Balance > 0: Some modifiers stuck (downs > ups)"
    echo "   ⚠️  Balance < 0: Extra releases (ups > downs)"
    echo "   🎯 UP events > 0: Layer switching method WORKS!"
    echo ""
    echo "🏆 SUCCESS CRITERIA MET IF:"
    echo "   1. Modifier balance = 0"
    echo "   2. UP events detected"
    echo "   3. No error messages"
    echo ""
else
    echo ""
    echo "❌ TEST FAILED OR INTERRUPTED"
    echo "💡 Check the error messages above"
    exit 1
fi

echo "🎉 Full TCP No-Fork Test Suite Complete!"
echo ""
echo "📈 NEXT STEPS:"
echo "   ✅ If test passed: Deploy to production!"
echo "   ⚠️  If issues found: Check configuration syntax"
echo "   🔧 For debugging: Check Kanata logs for errors" 