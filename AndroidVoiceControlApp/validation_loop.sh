#!/bin/bash

# 🔥 Tight Validation Loop for Android Voice Control App
# Similar to Xcode's build-run-test-log workflow

set -e

echo "🚀 Starting Validation Loop..."

# 1. Set Java 17
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# 2. Build and Install
echo "📦 Building and installing app..."
./gradlew installDebug

# 3. Launch app
echo "🎯 Launching app..."
adb shell am start -n com.voicecontrol.app/.MainActivity

# 4. Take screenshot
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "📸 Taking screenshot..."
adb exec-out screencap -p > "screenshots/screenshot_${TIMESTAMP}.png"
echo "   📸 Screenshot saved: screenshots/screenshot_${TIMESTAMP}.png"

# 5. Start real-time logging (app-specific with key components)
echo "📱 Starting real-time logs (Press Ctrl+C to stop)..."
echo "   🔍 Filtering: VoiceControl, Auth, Storage, RecordButton, Network"
echo "   ⏱️  Logs will show timestamp and tag"
echo ""

# Create screenshots directory if it doesn't exist
mkdir -p screenshots

# Start filtered real-time logging
adb logcat --pid=$(adb shell pidof -s com.voicecontrol.app) -v time | grep -E "(VoiceControl|Authentication|SecureStorage|RecordButton|Network|ERROR|CRASH)" --line-buffered