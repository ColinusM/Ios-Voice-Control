#!/bin/bash
# auto_build_simulator.sh - Level 4 PRP Validation Script
# This script provides fast injection validation on simulator as the final step of every PRP

set -e

echo "🚀 Starting Level 4 PRP Validation - Simulator Fast Injection..."

PROJECT_DIR="$(dirname "$0")/.."
SCHEME_NAME="IosVoiceControl"
SIMULATOR_NAME="iPhone 15"

# Clean and build for simulator
echo "📦 Building for simulator..."
xcodebuild clean -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" > /dev/null 2>&1

xcodebuild -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  build | tee "$PROJECT_DIR/logs/build_simulator.log"

# Launch app and capture logs
echo "📱 Launching app on simulator..."
xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
xcrun simctl install booted "$PROJECT_DIR/build/Release-iphonesimulator/IosVoiceControl.app" 2>/dev/null || true
xcrun simctl launch booted com.voicecontrol.app

# Stream logs for hot reload validation
echo "📊 Capturing logs for hot reload validation..."
mkdir -p "$PROJECT_DIR/logs"
xcrun simctl spawn booted log stream \
  --predicate 'subsystem contains "com.voicecontrol.app" OR subsystem contains "Inject"' \
  --style compact | tee "$PROJECT_DIR/logs/hot_reload_simulator.log" &

LOG_PID=$!
echo "✅ Level 4 validation setup complete. Hot reload logs streaming to logs/hot_reload_simulator.log (PID: $LOG_PID)"
echo "🔥 InjectionIII should now enable sub-second iteration cycles"
echo "Press Ctrl+C to stop log capture"

# Cleanup on exit
trap "kill $LOG_PID 2>/dev/null || true" EXIT
wait