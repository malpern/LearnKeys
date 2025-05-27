#!/bin/bash

echo "🧪 FINAL MODIFIER TEST - CMD-Enabled Kanata"
echo "==========================================="
echo "Testing if SHIFT_UP messages are now working with CMD-enabled binary"
echo ""

# Cleanup any existing processes
sudo pkill -f kanata 2>/dev/null
pkill -f UDPTestMonitor 2>/dev/null
sleep 1

# Start UDP monitor and capture output
echo "📡 Starting UDP monitor..."
swift UDPTestMonitor.swift > test_results.log 2>&1 &
UDP_PID=$!
sleep 3

# Start Kanata with UDP config
echo "🚀 Starting Kanata with UDP config..."
sudo kanata --cfg udp_test_config.kbd > kanata.log 2>&1 &
KANATA_PID=$!
sleep 4

echo "⌨️  Simulating key presses..."
echo "   1. Quick tap 'a' (should see KEY_A)"
echo "   2. Hold 'a' for 3 seconds (should see SHIFT_DOWN then SHIFT_UP)"

# Simulate key presses with longer timing
osascript -e '
tell application "System Events"
    delay 1
    
    -- Test 1: Quick tap
    key code 0
    delay 1
    
    -- Test 2: Long hold
    key down 0
    delay 3
    key up 0
    delay 1
    
    -- Test 3: Another tap to confirm
    key code 0
    delay 1
end tell'

echo "⏹️  Stopping processes..."
kill $UDP_PID 2>/dev/null
sudo kill $KANATA_PID 2>/dev/null
sleep 2

echo ""
echo "📊 TEST RESULTS:"
echo "================"

if [ -f test_results.log ]; then
    echo "UDP Monitor Output:"
    cat test_results.log
    echo ""
    
    # Count messages
    KEY_A_COUNT=$(grep -c "KEY_A" test_results.log 2>/dev/null || echo "0")
    SHIFT_DOWN_COUNT=$(grep -c "SHIFT_DOWN" test_results.log 2>/dev/null || echo "0")
    SHIFT_UP_COUNT=$(grep -c "SHIFT_UP" test_results.log 2>/dev/null || echo "0")
    
    echo "📈 Message Summary:"
    echo "   KEY_A messages: $KEY_A_COUNT"
    echo "   SHIFT_DOWN messages: $SHIFT_DOWN_COUNT"
    echo "   SHIFT_UP messages: $SHIFT_UP_COUNT"
    echo ""
    
    if [ "$SHIFT_UP_COUNT" -gt 0 ]; then
        echo "✅ SUCCESS: SHIFT_UP messages detected! Issue is RESOLVED!"
        echo "   Balance: $SHIFT_DOWN_COUNT downs, $SHIFT_UP_COUNT ups"
    else
        echo "❌ FAILURE: No SHIFT_UP messages detected. Issue persists."
        echo "   Balance: $SHIFT_DOWN_COUNT downs, $SHIFT_UP_COUNT ups"
    fi
else
    echo "❌ No UDP output captured"
fi

echo ""
echo "🔧 Kanata Status:"
if [ -f kanata.log ]; then
    echo "Last few lines of Kanata output:"
    tail -10 kanata.log
else
    echo "❌ No Kanata output captured"
fi

# Cleanup
rm -f test_results.log kanata.log 