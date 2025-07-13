#!/bin/bash
# deploy_to_iphone.sh - Level 5 PRP Validation Script  
# This script provides fast injection validation on iPhone X as the final step of every PRP

set -e

echo "📱 Starting Level 5 PRP Validation - iPhone X Fast Injection..."

PROJECT_DIR="$(dirname "$0")/.."
SCHEME_NAME="IosVoiceControl"
DEVICE_NAME="iPhone X"

# Build for device
echo "🔨 Building for iPhone X..."
xcodebuild -scheme "$SCHEME_NAME" \
  -destination "platform=iOS,name=$DEVICE_NAME" \
  -configuration Debug \
  CODE_SIGN_IDENTITY="iPhone Developer" \
  build install | tee "$PROJECT_DIR/logs/build_iphone.log"

# Capture device logs for hot reload validation
echo "📊 Starting iPhone X log capture for hot reload validation..."
mkdir -p "$PROJECT_DIR/logs"

# Check if device is connected
DEVICE_ID=$(idevice_id -l | head -1)
if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iPhone X device found. Please connect via cable or enable wireless debugging."
    exit 1
fi

echo "📱 Connected to device: $DEVICE_ID"

# Capture logs specific to voice control and hot reload
idevicesyslog -u "$DEVICE_ID" | \
  grep -E "(VoiceControl|Firebase|Auth|Inject)" | \
  tee "$PROJECT_DIR/logs/hot_reload_iphone.log" &

DEVICE_LOG_PID=$!

# Monitor performance for iPhone X (3GB RAM constraints)
echo "📈 Starting performance monitoring for iPhone X constraints..."
instruments -t "Time Profiler" \
  -D "$PROJECT_DIR/logs/trace_results_$(date +%Y%m%d_%H%M%S).trace" \
  -w "$DEVICE_NAME" \
  com.voicecontrol.app &

INSTRUMENTS_PID=$!

echo "✅ Level 5 validation setup complete on iPhone X"
echo "🔥 Hot reload enabled for real device testing"  
echo "📊 Device logs: logs/hot_reload_iphone.log (PID: $DEVICE_LOG_PID)"
echo "📈 Performance trace: logs/trace_results_*.trace (PID: $INSTRUMENTS_PID)"
echo "⚠️  Monitor for thermal throttling and 3GB RAM constraints"

# Cleanup on exit
trap "kill $DEVICE_LOG_PID $INSTRUMENTS_PID 2>/dev/null || true" EXIT

# Wait for user input to stop
read -p "Press Enter to stop iPhone X validation monitoring..."