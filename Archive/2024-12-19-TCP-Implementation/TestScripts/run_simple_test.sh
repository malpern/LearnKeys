#!/bin/bash

echo "🧪 Simple 'a' Key Modifier Test"
echo "==============================="
echo ""
echo "This test isolates the 'a' key modifier issue to verify press/release events."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}✅ $message${NC}" ;;
        "FAIL") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "WARN") echo -e "${YELLOW}⚠️  $message${NC}" ;;
    esac
}

# Check if Kanata is running
if pgrep -x "kanata" > /dev/null; then
    print_status "WARN" "Kanata is already running. Please stop it first:"
    echo "  sudo pkill kanata"
    echo ""
fi

# Check dependencies
print_status "INFO" "Checking dependencies..."
if ! command -v swift >/dev/null 2>&1; then
    print_status "FAIL" "Swift not found - required for UDP monitor"
    exit 1
fi

if ! command -v nc >/dev/null 2>&1; then
    print_status "FAIL" "netcat (nc) not found - required for UDP testing"
    exit 1
fi

print_status "PASS" "All dependencies found"
echo ""

# Make Swift monitor executable
chmod +x Tests/UDPTestMonitor.swift

print_status "INFO" "Test Setup:"
echo "  1. Test config: Tests/test_harness_config.kbd"
echo "  2. UDP monitor: Tests/UDPTestMonitor.swift"
echo "  3. Expected messages:"
echo "     • KEY_A (when you tap 'a')"
echo "     • SHIFT_DOWN (when you hold 'a')"
echo "     • SHIFT_UP (when you release 'a')"
echo ""

print_status "INFO" "Manual Test Instructions:"
echo "  1. Start the UDP monitor in one terminal:"
echo "     ./Tests/UDPTestMonitor.swift"
echo ""
echo "  2. Start Kanata with test config in another terminal:"
echo "     sudo kanata --cfg Tests/test_harness_config.kbd"
echo ""
echo "  3. Test the 'a' key:"
echo "     • Quick tap 'a' → should see KEY_A"
echo "     • Hold 'a' for 1+ seconds → should see SHIFT_DOWN then SHIFT_UP"
echo ""
echo "  4. Stop both programs with Ctrl+C to see results"
echo ""

print_status "INFO" "Automated Test (requires manual key presses):"
echo "  Run: ./Tests/run_simple_test.sh auto"
echo ""

# If 'auto' argument provided, try to run automated test
if [ "$1" = "auto" ]; then
    print_status "INFO" "Starting automated test..."
    
    # Start UDP monitor in background
    ./Tests/UDPTestMonitor.swift &
    MONITOR_PID=$!
    
    sleep 2
    
    print_status "INFO" "UDP monitor started (PID: $MONITOR_PID)"
    print_status "WARN" "Now manually press 'a' key to test (tap and hold)"
    print_status "INFO" "Press Enter when done testing..."
    
    read -r
    
    # Stop monitor
    kill $MONITOR_PID 2>/dev/null
    
    print_status "INFO" "Test completed. Check output above for results."
fi

echo ""
print_status "INFO" "Test files created:"
echo "  • Tests/test_harness_config.kbd (minimal Kanata config)"
echo "  • Tests/UDPTestMonitor.swift (simple UDP monitor)"
echo "  • Tests/run_simple_test.sh (this script)" 