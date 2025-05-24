#!/bin/bash

echo "Testing TCP connection to kanata server..."
echo "Trying to connect to 127.0.0.1:5829"

# Test if the port is open
if nc -z 127.0.0.1 5829 2>/dev/null; then
    echo "✅ Port 5829 is open"
    echo "📡 Attempting to receive layer change messages..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Listen for messages (Ctrl+C to stop)
    nc 127.0.0.1 5829 | while read line; do
        echo "📥 Received: $line"
    done
    
    echo ""
    echo "Connection test completed."
else
    echo "❌ Port 5829 is not available"
    echo "Make sure kanata is running with TCP server enabled"
    echo ""
    echo "To enable kanata TCP server, make sure your kanata config includes:"
    echo "(defcfg"
    echo "  tcp-server 127.0.0.1:5829"
    echo "  ..."
    echo ")"
fi

echo ""
echo "Note: If kanata is not running, this is expected."
echo "The LearnKeys app will show 'Disconnected' status until kanata is started." 