#!/bin/bash

# Automated Key Press Test with TCP Monitoring
# Uses AppleScript to simulate key presses while monitoring TCP messages

set -e

echo "🚀 Automated Key Press Test for TCP No-Fork Configuration"
echo "=" * 60
echo ""

# Check if Kanata is running
if ! pgrep -f kanata > /dev/null; then
    echo "❌ Kanata not running"
    echo "💡 Start Kanata first: cd ../LearnKeysUDP-Clean && sudo kanata --cfg config.kbd"
    exit 1
fi

echo "✅ Kanata is running"
echo ""

# Start TCP monitor in background
echo "🔨 Starting TCP monitor..."
swift tcp_test_harness.swift &
TCP_MONITOR_PID=$!

# Wait for monitor to start
sleep 2

echo "🤖 Starting automated key press simulation..."
echo "📋 Test sequence: Press 'a' key (should trigger shift modifier)"
echo ""

# Use AppleScript to simulate key press
osascript << 'EOF'
tell application "System Events"
    -- Wait a moment for setup
    delay 1
    
    -- Simulate pressing 'a' key briefly (tap)
    key code 0  -- 'a' key
    delay 0.5
    
    -- Simulate holding 'a' key (for modifier activation)
    key down 0  -- 'a' key down
    delay 1     -- Hold for 1 second
    key up 0    -- 'a' key up
    delay 0.5
    
    -- Another tap test
    key code 0  -- 'a' key
    delay 0.5
end tell
EOF

echo "✅ Key simulation completed"
echo "⏳ Waiting for TCP monitor to finish (25 more seconds)..."

# Wait for TCP monitor to complete
wait $TCP_MONITOR_PID

echo ""
echo "🎉 Automated Key Press Test Complete!"
echo ""
echo "📊 Analysis:"
echo "   ✅ If you saw TCP messages: Configuration is working!"
echo "   ❌ If no messages: Check Kanata configuration or CMD support" 