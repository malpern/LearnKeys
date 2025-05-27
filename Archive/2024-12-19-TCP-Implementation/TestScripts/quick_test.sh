#!/bin/bash

echo "🧪 Quick Modifier Test with CMD-Enabled Kanata"
echo "=============================================="

# Start UDP monitor in background and capture output
echo "Starting UDP monitor..."
swift UDPTestMonitor.swift > udp_output.log 2>&1 &
UDP_PID=$!
sleep 2

# Start Kanata in background
echo "Starting Kanata..."
sudo kanata --cfg test_harness_config.kbd > kanata_output.log 2>&1 &
KANATA_PID=$!
sleep 3

echo "Running key simulation..."
# Use AppleScript to simulate key presses
osascript -e '
tell application "System Events"
    delay 1
    -- Quick tap
    key code 0
    delay 0.5
    -- Hold sequence
    key down 0
    delay 2
    key up 0
    delay 1
end tell'

echo "Stopping processes..."
kill $UDP_PID 2>/dev/null
sudo kill $KANATA_PID 2>/dev/null
sleep 2

echo ""
echo "📊 UDP Monitor Results:"
echo "======================"
if [ -f udp_output.log ]; then
    cat udp_output.log
else
    echo "❌ No UDP output found"
fi

echo ""
echo "📊 Kanata Output:"
echo "================"
if [ -f kanata_output.log ]; then
    tail -20 kanata_output.log
else
    echo "❌ No Kanata output found"
fi

# Cleanup
rm -f udp_output.log kanata_output.log 