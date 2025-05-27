#!/bin/bash

echo "🔊 Testing UDP KeyTracker on port 6789..."
echo "=========================================="

# Check if port 6789 is available
echo "📡 Checking if port 6789 is listening..."
if lsof -i :6789 >/dev/null 2>&1; then
    echo "✅ Port 6789 is in use (LearnKeys UDP server is likely running)"
else
    echo "⚠️  Port 6789 is not in use"
    echo "   Make sure LearnKeys is running to test UDP functionality"
    echo ""
fi

# Function to test sending a UDP message
test_udp_message() {
    local message="$1"
    echo "📤 Sending UDP message: '$message'"
    echo "$message" | nc -u 127.0.0.1 6789
    sleep 0.5
}

echo ""
echo "🧪 Testing existing navigation key UDP messages..."
echo "------------------------------------------------"

# Test existing navigation key messages (these should work)
test_udp_message "navkey:h"
test_udp_message "navkey:j" 
test_udp_message "navkey:k"
test_udp_message "navkey:l"

echo ""
echo "🧪 Testing basic button press UDP messages..."
echo "---------------------------------------------"

# Test basic button press messages (these need to be implemented)
test_udp_message "keypress:a"
test_udp_message "keypress:s"
test_udp_message "keypress:d"
test_udp_message "keypress:f"

echo ""
echo "🧪 Testing modifier key UDP messages..."
echo "--------------------------------------"

# Test modifier key messages
test_udp_message "modifier:shift:down"
test_udp_message "modifier:shift:up"
test_udp_message "modifier:ctrl:down"
test_udp_message "modifier:ctrl:up"

echo ""
echo "🧪 Testing layer change UDP messages..."
echo "--------------------------------------"

# Test layer change messages
test_udp_message "layer:navfast"
test_udp_message "layer:base"

echo ""
echo "🧪 Testing invalid/unknown UDP messages..."
echo "-----------------------------------------"

# Test invalid messages to ensure graceful handling
test_udp_message "unknown:test"
test_udp_message "invalid message format"
test_udp_message ""

echo ""
echo "✅ UDP test completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run LearnKeys app and watch console output"
echo "2. Run this script in another terminal"
echo "3. Check that navigation keys (h,j,k,l) show '🔊 UDP received' messages"
echo "4. Expand UDPKeyTracker to handle basic button presses"
echo ""
echo "💡 To monitor UDP traffic in real time:"
echo "   tcpdump -i lo0 -A 'port 6789'" 