#!/bin/bash

echo "🧪 Complete 'a' Key Modifier Test"
echo "=================================="
echo ""
echo "This test will start both Kanata and the UDP monitor for complete testing."
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

# Check if running as root for Kanata
if [ "$EUID" -ne 0 ]; then
    print_status "WARN" "This script needs to run Kanata with sudo privileges"
    print_status "INFO" "Please run: sudo ./Tests/run_complete_test.sh"
    exit 1
fi

# Check if Kanata is already running
if pgrep -x "kanata" > /dev/null; then
    print_status "WARN" "Kanata is already running. Stopping it first..."
    pkill kanata
    sleep 2
fi

# Check dependencies
print_status "INFO" "Checking dependencies..."
if ! command -v swift >/dev/null 2>&1; then
    print_status "FAIL" "Swift not found - required for UDP monitor"
    exit 1
fi

if ! command -v kanata >/dev/null 2>&1; then
    print_status "FAIL" "Kanata not found - please install Kanata first"
    exit 1
fi

print_status "PASS" "All dependencies found"
echo ""

# Make Swift monitor executable
chmod +x Tests/UDPTestMonitor.swift

print_status "INFO" "Starting UDP monitor..."
# Start UDP monitor in background
./Tests/UDPTestMonitor.swift &
MONITOR_PID=$!
sleep 2

print_status "INFO" "Starting Kanata with test config..."
# Start Kanata in background
kanata --cfg Tests/test_harness_config.kbd &
KANATA_PID=$!
sleep 3

# Check if both processes started
if ! kill -0 $MONITOR_PID 2>/dev/null; then
    print_status "FAIL" "UDP monitor failed to start"
    exit 1
fi

if ! kill -0 $KANATA_PID 2>/dev/null; then
    print_status "FAIL" "Kanata failed to start"
    kill $MONITOR_PID 2>/dev/null
    exit 1
fi

print_status "PASS" "Both UDP monitor and Kanata are running"
echo ""

print_status "INFO" "Test Instructions:"
echo "  1. Quick tap 'a' → should see KEY_A message"
echo "  2. Hold 'a' for 1+ seconds → should see SHIFT_DOWN then SHIFT_UP"
echo "  3. Try multiple taps and holds to verify consistency"
echo ""

print_status "WARN" "Press 'a' key now to test (tap and hold)..."
print_status "INFO" "Press Enter when done testing to see results..."

# Wait for user input
read -r

print_status "INFO" "Stopping test processes..."

# Stop Kanata first
if kill -0 $KANATA_PID 2>/dev/null; then
    kill $KANATA_PID 2>/dev/null
    sleep 1
    # Force kill if still running
    kill -9 $KANATA_PID 2>/dev/null
fi

# Stop UDP monitor and get final report
if kill -0 $MONITOR_PID 2>/dev/null; then
    kill -INT $MONITOR_PID 2>/dev/null
    sleep 2
    # Force kill if still running
    kill -9 $MONITOR_PID 2>/dev/null
fi

echo ""
print_status "INFO" "Test completed!"
print_status "INFO" "Check the output above for test results"
echo ""
print_status "INFO" "Expected results:"
echo "  ✅ KEY_A messages for taps"
echo "  ✅ SHIFT_DOWN messages for holds"
echo "  ✅ SHIFT_UP messages for releases"
echo "  ✅ Perfect balance (downs = ups)"
echo ""
print_status "INFO" "If SHIFT_UP messages are missing, the issue is confirmed" 