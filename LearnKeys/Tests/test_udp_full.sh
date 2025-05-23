#!/bin/bash

echo "🚀 Comprehensive UDP Button Press Testing"
echo "========================================"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
TEST_CONFIG="test_config.kbd"
LEARNKEYS_DIR="LearnKeys"

echo "📍 Working from: $SCRIPT_DIR"
echo "📁 Test config: $TEST_CONFIG"
echo ""

# Check dependencies
echo "🔍 Checking dependencies..."

if ! command -v nc >/dev/null 2>&1; then
    echo "❌ netcat (nc) not found - required for UDP testing"
    exit 1
fi

if ! command -v lsof >/dev/null 2>&1; then
    echo "❌ lsof not found - required for port checking"
    exit 1
fi

if [ ! -f "$TEST_CONFIG" ]; then
    echo "❌ Test config file '$TEST_CONFIG' not found"
    exit 1
fi

if [ ! -d "$LEARNKEYS_DIR" ]; then
    echo "❌ LearnKeys directory not found"
    exit 1
fi

echo "✅ All dependencies found"
echo ""

# Build LearnKeys
echo "🔨 Building LearnKeys..."
cd "$LEARNKEYS_DIR"

if [ ! -f "build.sh" ]; then
    echo "❌ build.sh not found in LearnKeys directory"
    exit 1
fi

./build.sh
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Go back to main directory
cd "$SCRIPT_DIR"

# Function to test UDP connectivity
test_udp_port() {
    local port="$1"
    local max_attempts=30
    local attempt=0
    
    echo "📡 Waiting for port $port to be available..."
    
    while [ $attempt -lt $max_attempts ]; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo "✅ Port $port is now listening"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 1
        echo -n "."
    done
    
    echo ""
    echo "❌ Port $port not available after $max_attempts seconds"
    return 1
}

# Function to send UDP test message
send_udp_test() {
    local message="$1"
    echo "📤 Testing: '$message'"
    echo "$message" | nc -u 127.0.0.1 6789
    sleep 0.3
}

# Function to run UDP tests
run_udp_tests() {
    echo ""
    echo "🧪 Running UDP Tests..."
    echo "====================="
    
    echo ""
    echo "1️⃣ Testing basic key presses..."
    send_udp_test "keypress:a"
    send_udp_test "keypress:s"
    send_udp_test "keypress:d"
    send_udp_test "keypress:f"
    send_udp_test "keypress:g"
    send_udp_test "keypress:h"
    send_udp_test "keypress:j"
    send_udp_test "keypress:k"
    send_udp_test "keypress:l"
    send_udp_test "keypress:spc"
    
    echo ""
    echo "2️⃣ Testing modifier keys..."
    send_udp_test "modifier:shift:down"
    sleep 0.5
    send_udp_test "modifier:shift:up"
    send_udp_test "modifier:ctrl:down"
    sleep 0.5
    send_udp_test "modifier:ctrl:up"
    send_udp_test "modifier:option:down"
    sleep 0.5
    send_udp_test "modifier:option:up"
    send_udp_test "modifier:cmd:down"
    sleep 0.5
    send_udp_test "modifier:cmd:up"
    
    echo ""
    echo "3️⃣ Testing navigation keys (existing functionality)..."
    send_udp_test "navkey:h"
    send_udp_test "navkey:j"
    send_udp_test "navkey:k"
    send_udp_test "navkey:l"
    
    echo ""
    echo "4️⃣ Testing layer changes..."
    send_udp_test "layer:navfast"
    sleep 0.5
    send_udp_test "layer:base"
    
    echo ""
    echo "5️⃣ Testing invalid messages (should be handled gracefully)..."
    send_udp_test "unknown:test"
    send_udp_test "invalid format"
    send_udp_test ""
    
    echo ""
    echo "✅ UDP tests completed!"
}

# Interactive mode selection
echo "🎯 Choose test mode:"
echo "1) Run LearnKeys and UDP tests interactively"
echo "2) Just run UDP tests (requires LearnKeys already running)"
echo "3) Just build and run LearnKeys (no tests)"
echo ""

read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting interactive test mode..."
        echo ""
        echo "📋 Instructions:"
        echo "1. LearnKeys will start in a moment"
        echo "2. Grant accessibility permissions if prompted"
        echo "3. After LearnKeys is running, UDP tests will start automatically"
        echo "4. Watch the console output for UDP messages"
        echo "5. Press Ctrl+C to stop"
        echo ""
        echo "Press Enter to continue..."
        read
        
        # Start LearnKeys in background
        echo "🚀 Starting LearnKeys with test config..."
        "$LEARNKEYS_DIR/build/LearnKeys" "$TEST_CONFIG" &
        LEARNKEYS_PID=$!
        
        # Wait for UDP port to be available
        if test_udp_port 6789; then
            sleep 2  # Give it a moment to fully initialize
            run_udp_tests
            
            echo ""
            echo "✅ Tests completed! LearnKeys is still running (PID: $LEARNKEYS_PID)"
            echo "💡 Try typing keys and watch for UDP messages in the console"
            echo "🛑 Press Ctrl+C or close the LearnKeys window to stop"
            wait $LEARNKEYS_PID
        else
            echo "❌ Failed to start LearnKeys UDP server"
            kill $LEARNKEYS_PID 2>/dev/null
            exit 1
        fi
        ;;
        
    2)
        echo ""
        echo "🧪 Running UDP tests only..."
        if lsof -i :6789 >/dev/null 2>&1; then
            run_udp_tests
        else
            echo "❌ Port 6789 not available. Make sure LearnKeys is running first."
            exit 1
        fi
        ;;
        
    3)
        echo ""
        echo "🚀 Starting LearnKeys only..."
        echo "💡 After it starts, you can run './test_udp.sh' in another terminal to test UDP"
        exec "$LEARNKEYS_DIR/build/LearnKeys" "$TEST_CONFIG"
        ;;
        
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Test script completed!" 