#!/bin/bash

echo "🧪 Comprehensive UDP Functional Testing (Log-Based)"
echo "=================================================="

# Configuration
UDP_PORT=6789
LOG_FILE="$HOME/Documents/LearnKeysUDP.log"
TEST_TIMEOUT=30
SLEEP_BETWEEN_TESTS=0.5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}✅ PASS${NC}: $message" ;;
        "FAIL") echo -e "${RED}❌ FAIL${NC}: $message" ;;
        "INFO") echo -e "${BLUE}ℹ️  INFO${NC}: $message" ;;
        "WARN") echo -e "${YELLOW}⚠️  WARN${NC}: $message" ;;
    esac
}

# Function to wait for application startup
wait_for_udp_port() {
    local max_attempts=30
    local attempt=0
    
    print_status "INFO" "Waiting for UDP port $UDP_PORT to be available..."
    
    while [ $attempt -lt $max_attempts ]; do
        if lsof -i :$UDP_PORT >/dev/null 2>&1; then
            print_status "PASS" "UDP port $UDP_PORT is listening"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 1
        echo -n "."
    done
    
    echo ""
    print_status "FAIL" "UDP port $UDP_PORT not available after $max_attempts seconds"
    return 1
}

# Function to send UDP message and verify log entry
test_udp_message() {
    local message="$1"
    local expected_log_pattern="$2"
    local test_description="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Clear relevant log entries (get current log size)
    local log_size_before=0
    if [ -f "$LOG_FILE" ]; then
        log_size_before=$(wc -l < "$LOG_FILE")
    fi
    
    # Send UDP message
    echo "$message" | nc -u -w 1 127.0.0.1 $UDP_PORT
    sleep $SLEEP_BETWEEN_TESTS
    
    # Check for expected log entry
    if [ -f "$LOG_FILE" ]; then
        local log_size_after=$(wc -l < "$LOG_FILE")
        local new_lines=$((log_size_after - log_size_before))
        
        if [ $new_lines -gt 0 ]; then
            # Get new log entries
            local new_logs=$(tail -n $new_lines "$LOG_FILE")
            
            if echo "$new_logs" | grep -q "$expected_log_pattern"; then
                print_status "PASS" "$test_description"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                print_status "FAIL" "$test_description - Expected pattern '$expected_log_pattern' not found"
                echo "    New log entries: $new_logs"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
        else
            print_status "FAIL" "$test_description - No new log entries found"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        print_status "FAIL" "$test_description - Log file not found: $LOG_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to run all functional tests
run_functional_tests() {
    echo ""
    print_status "INFO" "Starting UDP functional tests..."
    echo ""
    
    # Test 1: Basic Key Press Events
    echo "📝 Testing Key Press Events"
    echo "============================="
    test_udp_message "keypress:a" "Animating key press: a" "Key press 'a'"
    test_udp_message "keypress:s" "Animating key press: s" "Key press 's'"
    test_udp_message "keypress:space" "Animating key press: space" "Key press 'space'"
    
    echo ""
    
    # Test 2: Navigation Key Events  
    echo "🧭 Testing Navigation Key Events"
    echo "================================="
    test_udp_message "navkey:h" "Animating navigation: h" "Navigation key 'h'"
    test_udp_message "navkey:j" "Animating navigation: j" "Navigation key 'j'"
    test_udp_message "navkey:k" "Animating navigation: k" "Navigation key 'k'"
    test_udp_message "navkey:l" "Animating navigation: l" "Navigation key 'l'"
    
    echo ""
    
    # Test 3: Modifier State Changes
    echo "🎛️ Testing Modifier State Changes"
    echo "=================================="
    test_udp_message "modifier:shift:down" "Updating modifier shift: active" "Shift modifier down"
    test_udp_message "modifier:shift:up" "Updating modifier shift: inactive" "Shift modifier up"
    test_udp_message "modifier:control:down" "Updating modifier control: active" "Control modifier down"
    test_udp_message "modifier:control:up" "Updating modifier control: inactive" "Control modifier up"
    test_udp_message "modifier:option:down" "Updating modifier option: active" "Option modifier down"
    test_udp_message "modifier:option:up" "Updating modifier option: inactive" "Option modifier up"
    test_udp_message "modifier:command:down" "Updating modifier command: active" "Command modifier down"
    test_udp_message "modifier:command:up" "Updating modifier command: inactive" "Command modifier up"
    
    echo ""
    
    # Test 4: Layer Transitions
    echo "🗂️ Testing Layer Transitions"
    echo "============================="
    test_udp_message "layer:base" "Transitioning to layer: base" "Layer change to base"
    test_udp_message "layer:f-nav" "Transitioning to layer: f-nav" "Layer change to f-nav"
    test_udp_message "layer:navfast" "Transitioning to layer: navfast" "Layer change to navfast"
    test_udp_message "layer:base" "Transitioning to layer: base" "Layer change back to base"
    
    echo ""
    
    # Test 5: Error Handling
    echo "⚠️ Testing Error Handling"
    echo "=========================="
    test_udp_message "invalid:message" "Unknown UDP message type" "Invalid message type"
    test_udp_message "keypress:" "Invalid keypress message format" "Invalid keypress format"
    test_udp_message "" "Received empty UDP message" "Empty message"
    
    echo ""
    
    # Test 6: UDP Message Reception
    echo "📡 Testing UDP Message Reception"
    echo "================================="
    test_udp_message "keypress:test" "UDP received: 'keypress:test'" "UDP message reception"
    
    echo ""
}

# Function to check dependencies
check_dependencies() {
    print_status "INFO" "Checking dependencies..."
    
    local all_deps_ok=true
    
    if ! command -v nc >/dev/null 2>&1; then
        print_status "FAIL" "netcat (nc) not found - required for UDP testing"
        all_deps_ok=false
    fi
    
    if ! command -v lsof >/dev/null 2>&1; then
        print_status "FAIL" "lsof not found - required for port checking"
        all_deps_ok=false
    fi
    
    if [ "$all_deps_ok" = true ]; then
        print_status "PASS" "All dependencies found"
        return 0
    else
        return 1
    fi
}

# Function to build application
build_application() {
    print_status "INFO" "Building LearnKeysUDP..."
    
    if [ ! -f "Package.swift" ]; then
        print_status "FAIL" "Package.swift not found - not in correct directory"
        return 1
    fi
    
    swift build
    if [ $? -eq 0 ]; then
        print_status "PASS" "Build successful"
        return 0
    else
        print_status "FAIL" "Build failed"
        return 1
    fi
}

# Function to start application for testing
start_application() {
    print_status "INFO" "Starting LearnKeysUDP for testing..."
    
    # Start application in background
    .build/arm64-apple-macosx/debug/LearnKeysUDP &
    APP_PID=$!
    
    # Wait for UDP port to be available
    if wait_for_udp_port; then
        sleep 2  # Give it a moment to fully initialize
        print_status "PASS" "Application started successfully (PID: $APP_PID)"
        return 0
    else
        print_status "FAIL" "Failed to start application"
        kill $APP_PID 2>/dev/null
        return 1
    fi
}

# Function to cleanup
cleanup() {
    if [ ! -z "$APP_PID" ]; then
        print_status "INFO" "Stopping application (PID: $APP_PID)"
        kill $APP_PID 2>/dev/null
        wait $APP_PID 2>/dev/null
    fi
}

# Function to print test summary
print_summary() {
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_status "PASS" "All tests passed! 🎉"
        return 0
    else
        print_status "FAIL" "$TESTS_FAILED out of $TESTS_RUN tests failed"
        return 1
    fi
}

# Main execution
main() {
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    echo ""
    
    # Build application
    if ! build_application; then
        exit 1
    fi
    
    echo ""
    
    # Start application
    if ! start_application; then
        exit 1
    fi
    
    echo ""
    
    # Run functional tests
    run_functional_tests
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

# Check if running directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi 