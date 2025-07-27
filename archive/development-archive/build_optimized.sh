#!/bin/bash

# Optimized Build Script for VoiceControlApp
# Works for both CLI builds and Xcode GUI builds

echo "🚀 Starting optimized build process..."

# Set environment variables for faster compilation
export CLANG_ENABLE_MODULES=1
export SWIFT_ENABLE_INCREMENTAL_COMPILATION=1

# Clear problematic caches
echo "🧹 Clearing build caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/VoiceControlApp*
rm -rf ~/Library/Caches/org.swift.swiftpm

# Clean the project
echo "🧽 Cleaning project..."
xcodebuild clean -project VoiceControlApp.xcodeproj -scheme VoiceControlApp

# Build with optimized settings
echo "⚡ Building with optimized settings..."
xcodebuild \
  -project VoiceControlApp.xcodeproj \
  -scheme VoiceControlApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' \
  -configuration Debug \
  -parallelizeTargets \
  -jobs $(sysctl -n hw.ncpu) \
  build

echo "✅ Optimized build complete!"