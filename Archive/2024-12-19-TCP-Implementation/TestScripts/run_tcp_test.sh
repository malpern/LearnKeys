#!/bin/bash

# TCP Test Harness for No-Fork Kanata Configuration
# Tests the layer switching approach on TCP port 6790

set -e

echo "🚀 TCP No-Fork Test Harness"
echo "=" * 50
echo ""

# Check if we're in the right directory
if [ ! -f "tcp_test_harness.swift" ]; then
    echo "❌ Error: tcp_test_harness.swift not found"
    echo "💡 Run this script from the Tests directory"
    exit 1
fi

# Check if Kanata is running
echo "🔍 Checking if Kanata is running..."
if pgrep -f kanata > /dev/null; then
    echo "✅ Kanata process found"
else
    echo "⚠️  Kanata not detected - make sure it's running with the no-fork config"
    echo ""
    echo "💡 To start Kanata with no-fork config:"
    echo "   cd ../LearnKeysUDP-Clean"
    echo "   sudo kanata --cfg config.kbd"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if TCP port 6790 is available for connection
echo "🔍 Checking TCP port 6790..."
if nc -z 127.0.0.1 6790 2>/dev/null; then
    echo "✅ TCP port 6790 is accepting connections"
else
    echo "⚠️  TCP port 6790 not responding"
    echo "💡 Make sure Kanata is running with the TCP no-fork config"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🧪 Starting TCP Test Harness..."
echo "⏱️  Test will run for 30 seconds"
echo "🎯 Testing no-fork layer switching method"
echo ""
echo "📋 TESTING INSTRUCTIONS:"
echo "   1. Wait for 'TCP connection established' message"
echo "   2. Hold 'a' key for 1 second, then release"
echo "   3. Should see: keypress:a, SHIFT DOWN, SHIFT UP"
echo "   4. Try other home row modifiers: s(ctrl), d(option), g(cmd)"
echo "   5. Try right hand: j(cmd), k(option), l(ctrl), ;(shift)"
echo "   6. Test will auto-complete after 30 seconds"
echo ""
echo "🎯 SUCCESS CRITERIA:"
echo "   ✅ Equal number of modifier downs and ups"
echo "   ✅ No stuck modifiers (balance = 0)"
echo "   ✅ Release events detected (proving layer switching works)"
echo ""

# Compile and run the Swift test harness
echo "🔨 Compiling TCP test harness..."
if swift tcp_test_harness.swift; then
    echo ""
    echo "✅ Test completed successfully!"
else
    echo ""
    echo "❌ Test failed or was interrupted"
    exit 1
fi

echo ""
echo "🎉 TCP No-Fork Test Complete!"
echo "📊 Check the test results above for modifier balance analysis"
echo ""
echo "💡 Next steps:"
echo "   - If balance = 0: ✅ No-fork solution working perfectly!"
echo "   - If balance > 0: ⚠️  Some modifiers may be stuck"
echo "   - If no UP events: ❌ Layer switching not working" 