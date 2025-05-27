#!/bin/bash

echo "🔌 Testing TCP connection to kanata server..."
echo "Trying to connect to 127.0.0.1:5829"
echo "=========================================="

# Test if the port is open
if nc -z 127.0.0.1 5829 2>/dev/null; then
    echo "✅ Port 5829 is open"
    echo "📡 Listening for TCP messages from kanata..."
    echo "Expected message formats:"
    echo "  • navkey:h:down / navkey:h:up"
    echo "  • modifier:shift:down / modifier:shift:up"
    echo "  • layer:f-nav:down / layer:f-nav:up"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Listen for messages (Ctrl+C to stop)
    nc 127.0.0.1 5829 | while read line; do
        timestamp=$(date '+%H:%M:%S.%3N')
        echo "[$timestamp] 📥 $line"
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
    echo ""
    echo "💡 To test with the fixed fork config:"
    echo "   sudo kanata -c config_fixed_fork.kbd"
fi

echo ""
echo "📋 Note: If kanata is not running, this is expected."
echo "The LearnKeys app will show 'Disconnected' status until kanata is started." 