#!/bin/bash

# 🎯 Smart Android Testing Loop for Voice Control App
# Usage: ./android_test_loop.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# App package name
APP_PACKAGE="com.voicecontrol.app"
APP_ACTIVITY="com.voicecontrol.app.MainActivity"

# Test results storage
RESULTS_DIR="test_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Clear logs and inject marker
prepare_test() {
    local test_name=$1
    print_status "Preparing test: $test_name"
    
    # Clear logcat buffer
    adb logcat -c
    
    # Inject timestamp marker
    local marker="TEST_${test_name}_$(date +%s)"
    echo "$marker" | adb shell log -t TestMarker -p i
    
    echo "$marker"
}

# Capture logs with multiple filters
capture_logs() {
    local marker=$1
    local duration=${2:-2}
    
    print_status "Capturing logs for ${duration} seconds..."
    
    # Start parallel log captures
    (
        adb logcat -d -t 500 > "$RESULTS_DIR/${marker}_full.log" 2>/dev/null &
        adb logcat -d -t 500 | grep -E "$APP_PACKAGE" > "$RESULTS_DIR/${marker}_app.log" 2>/dev/null &
        adb logcat -d -t 500 | grep -E "TouchEvent|MotionEvent|onClick" > "$RESULTS_DIR/${marker}_input.log" 2>/dev/null &
        adb logcat -d -t 500 | grep -E "Activity|Fragment|Navigation" > "$RESULTS_DIR/${marker}_nav.log" 2>/dev/null &
        adb logcat -d -t 500 | grep -E "ERROR|FATAL|Exception" > "$RESULTS_DIR/${marker}_errors.log" 2>/dev/null &
        wait
    )
    
    sleep "$duration"
}

# Analyze captured logs
analyze_logs() {
    local marker=$1
    local expected_pattern=$2
    local found=false
    
    print_status "Analyzing logs for pattern: $expected_pattern"
    
    # Check for expected pattern
    if grep -q "$expected_pattern" "$RESULTS_DIR/${marker}_"*.log 2>/dev/null; then
        print_success "Found expected pattern: $expected_pattern"
        found=true
        
        # Show matching lines
        echo -e "${GREEN}Matching lines:${NC}"
        grep "$expected_pattern" "$RESULTS_DIR/${marker}_"*.log 2>/dev/null | head -5
    else
        print_error "Pattern not found: $expected_pattern"
    fi
    
    # Check for errors
    if [ -s "$RESULTS_DIR/${marker}_errors.log" ]; then
        print_warning "Errors detected:"
        head -10 "$RESULTS_DIR/${marker}_errors.log"
    fi
    
    $found
}

# Test: Tap Network Button
test_network_button() {
    local marker=$(prepare_test "network_button")
    
    print_status "Tapping Network button..."
    adb shell input tap 257 1990
    
    capture_logs "$marker" 3
    
    if analyze_logs "$marker" "NetworkSettings\|Navigation\|nav_network"; then
        print_success "Network button test PASSED"
        return 0
    else
        print_error "Network button test FAILED"
        return 1
    fi
}

# Test: Tap Microphone Button
test_microphone_button() {
    local marker=$(prepare_test "microphone_button")
    
    print_status "Tapping Microphone button..."
    adb shell input tap 498 2172
    
    capture_logs "$marker" 3
    
    if analyze_logs "$marker" "Microphone\|Audio\|Recording\|RECORD_AUDIO"; then
        print_success "Microphone button test PASSED"
        return 0
    else
        print_error "Microphone button test FAILED"
        return 1
    fi
}

# Test: Back Navigation
test_back_navigation() {
    local marker=$(prepare_test "back_nav")
    
    print_status "Pressing BACK button..."
    adb shell input keyevent KEYCODE_BACK
    
    capture_logs "$marker" 2
    
    if analyze_logs "$marker" "onBackPressed\|WindowDispatcher\|CoreBackPreview"; then
        print_success "Back navigation test PASSED"
        return 0
    else
        print_error "Back navigation test FAILED"
        return 1
    fi
}

# Test: App Launch
test_app_launch() {
    local marker=$(prepare_test "app_launch")
    
    print_status "Launching Voice Control app..."
    adb shell am start -n "$APP_PACKAGE/$APP_ACTIVITY"
    
    capture_logs "$marker" 3
    
    if analyze_logs "$marker" "MainActivity\|onCreate\|VoiceControlApp"; then
        print_success "App launch test PASSED"
        return 0
    else
        print_error "App launch test FAILED"
        return 1
    fi
}

# Custom test with coordinates
test_custom_tap() {
    local x=$1
    local y=$2
    local expected=$3
    local test_name=${4:-"custom_tap"}
    
    local marker=$(prepare_test "$test_name")
    
    print_status "Tapping at ($x, $y)..."
    adb shell input tap "$x" "$y"
    
    capture_logs "$marker" 3
    
    if analyze_logs "$marker" "$expected"; then
        print_success "Custom tap test PASSED"
        return 0
    else
        print_error "Custom tap test FAILED"
        return 1
    fi
}

# Live monitoring mode
live_monitor() {
    print_status "Starting live monitoring mode..."
    print_warning "Press Ctrl+C to stop"
    
    adb logcat -c
    adb logcat | grep -E "$APP_PACKAGE|ERROR|TouchEvent|Navigation" --line-buffered | while IFS= read -r line; do
        if echo "$line" | grep -q "ERROR\|FATAL"; then
            echo -e "${RED}$line${NC}"
        elif echo "$line" | grep -q "$APP_PACKAGE"; then
            echo -e "${GREEN}$line${NC}"
        elif echo "$line" | grep -q "TouchEvent\|onClick"; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Main test suite
run_test_suite() {
    print_status "Starting Voice Control App Test Suite"
    echo "Results will be saved to: $RESULTS_DIR"
    echo ""
    
    local passed=0
    local failed=0
    
    # Run tests
    tests=(
        "test_app_launch"
        "test_network_button"
        "test_back_navigation"
        "test_microphone_button"
    )
    
    for test in "${tests[@]}"; do
        echo "----------------------------------------"
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
        sleep 2
    done
    
    # Summary
    echo "========================================"
    print_status "Test Suite Complete"
    print_success "Passed: $passed"
    print_error "Failed: $failed"
    echo "Results saved to: $RESULTS_DIR"
}

# Interactive menu
show_menu() {
    echo ""
    echo "🎯 Android Voice Control Test Loop"
    echo "========================================"
    echo "1) Run Full Test Suite"
    echo "2) Test Network Button"
    echo "3) Test Microphone Button"
    echo "4) Test Back Navigation"
    echo "5) Test App Launch"
    echo "6) Custom Tap Test"
    echo "7) Live Monitor Mode"
    echo "8) Clear Logs"
    echo "9) Show Device Info"
    echo "0) Exit"
    echo "========================================"
    read -p "Select option: " choice
    
    case $choice in
        1) run_test_suite ;;
        2) test_network_button ;;
        3) test_microphone_button ;;
        4) test_back_navigation ;;
        5) test_app_launch ;;
        6) 
            read -p "Enter X coordinate: " x
            read -p "Enter Y coordinate: " y
            read -p "Enter expected pattern: " pattern
            test_custom_tap "$x" "$y" "$pattern"
            ;;
        7) live_monitor ;;
        8) 
            adb logcat -c
            print_success "Logs cleared"
            ;;
        9)
            echo "Device: $(adb shell getprop ro.product.model)"
            echo "Android: $(adb shell getprop ro.build.version.release)"
            echo "App installed: $(adb shell pm list packages | grep -c $APP_PACKAGE)"
            ;;
        0) exit 0 ;;
        *) print_error "Invalid option" ;;
    esac
}

# Main loop
main() {
    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        print_error "adb not found. Please install Android SDK."
        exit 1
    fi
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        print_error "No Android device connected."
        echo "Connect a device or start an emulator."
        exit 1
    fi
    
    # Run in interactive mode or test suite
    if [ "$1" == "--suite" ]; then
        run_test_suite
    elif [ "$1" == "--live" ]; then
        live_monitor
    else
        while true; do
            show_menu
            echo ""
            read -p "Press Enter to continue..."
        done
    fi
}

# Run main
main "$@"