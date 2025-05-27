#!/bin/bash

echo "🧪 NO-FORK TEST - tap-hold-release approach"
echo "==========================================="
echo "Testing if tap-hold-release resolves the modifier release issue"
echo ""

# Cleanup
sudo pkill -f kanata 2>/dev/null
sudo rm -f /tmp/kanata_test.log
sleep 1

echo "🚀 Starting Kanata with no-fork config..."
sudo kanata --cfg no_fork_test.kbd &
KANATA_PID=$!
sleep 4

echo "⌨️  Simulating key presses..."
echo "   1. Quick tap 'a' (should see KEY_A)"
echo "   2. Hold 'a' for 3 seconds (should see SHIFT_DOWN then SHIFT_UP)"

# Simulate key presses
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
    
    -- Test 3: Another tap
    key code 0
    delay 1
end tell'

echo "⏹️  Stopping Kanata..."
sudo kill $KANATA_PID 2>/dev/null
sleep 2

echo ""
echo "📊 TEST RESULTS:"
echo "================"

if [ -f /tmp/kanata_test.log ]; then
    echo "Log file contents:"
    cat /tmp/kanata_test.log
    echo ""
    
    # Count messages
    KEY_A_COUNT=$(grep -c "KEY_A" /tmp/kanata_test.log 2>/dev/null || echo "0")
    SHIFT_DOWN_COUNT=$(grep -c "SHIFT_DOWN" /tmp/kanata_test.log 2>/dev/null || echo "0")
    SHIFT_UP_COUNT=$(grep -c "SHIFT_UP" /tmp/kanata_test.log 2>/dev/null || echo "0")
    
    echo "📈 Message Summary:"
    echo "   KEY_A messages: $KEY_A_COUNT"
    echo "   SHIFT_DOWN messages: $SHIFT_DOWN_COUNT"
    echo "   SHIFT_UP messages: $SHIFT_UP_COUNT"
    echo ""
    
    if [ "$SHIFT_UP_COUNT" -gt 0 ]; then
        echo "✅ SUCCESS: SHIFT_UP messages detected! No-fork approach WORKS!"
        echo "   Balance: $SHIFT_DOWN_COUNT downs, $SHIFT_UP_COUNT ups"
    else
        echo "❌ FAILURE: No SHIFT_UP messages. Issue persists even without fork."
        echo "   Balance: $SHIFT_DOWN_COUNT downs, $SHIFT_UP_COUNT ups"
    fi
else
    echo "❌ No log file found - test may have failed to run"
fi

# Cleanup
sudo rm -f /tmp/kanata_test.log 