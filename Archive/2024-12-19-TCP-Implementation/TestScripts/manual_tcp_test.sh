#!/bin/bash

# Manual TCP Test - Start Kanata and Test Harness Separately
# This allows manual testing without waiting for TCP port availability

set -e

echo "🚀 Manual TCP No-Fork Test"
echo "=" * 50
echo ""

# Check if we're in the right directory
if [ ! -f "tcp_test_harness.swift" ]; then
    echo "❌ Error: tcp_test_harness.swift not found"
    echo "💡 Run this script from the Tests directory"
    exit 1
fi

# Stop any existing Kanata processes
echo "🛑 Stopping any existing Kanata processes..."
sudo pkill -f kanata || true
sleep 2

echo "🚀 Starting Kanata with no-fork TCP configuration..."
echo "📁 Config: ../LearnKeysUDP-Clean/config.kbd"
echo "🔌 TCP Port: 6790 (activated when keys are pressed)"
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
echo ""
echo "🧪 Starting TCP Test Harness..."
echo "⏱️  Test duration: 30 seconds"
echo ""
echo "📋 MANUAL TESTING INSTRUCTIONS:"
echo "   🎯 CRITICAL: Wait for 'TCP connection established' OR start typing"
echo "   ✅ Test sequence:"
echo "      1. Hold 'a' key for 1 second, then release"
echo "      2. Should see: keypress:a, modifier:shift:down, modifier:shift:up"
echo "      3. Try: s(ctrl), d(option), g(cmd), j(cmd), k(option), l(ctrl), ;(shift)"
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

# Run the test harness (it will try to connect and wait)
echo "🔨 Compiling and running TCP test harness..."
echo "💡 The test harness will try to connect to TCP port 6790"
echo "💡 Start typing to activate the TCP commands!"
echo ""

if swift tcp_test_harness.swift; then
    echo ""
    echo "🎉 TEST COMPLETED!"
    echo ""
    echo "📊 Check the results above for modifier balance analysis"
else
    echo ""
    echo "❌ TEST FAILED OR INTERRUPTED"
    echo "💡 Check the error messages above"
    exit 1
fi

echo "🎉 Manual TCP Test Complete!" 