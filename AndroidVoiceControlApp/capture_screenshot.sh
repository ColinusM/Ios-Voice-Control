#!/bin/bash

# 📸 Quick Screenshot Capture
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p screenshots
adb exec-out screencap -p > "screenshots/screenshot_${TIMESTAMP}.png"
echo "📸 Screenshot saved: screenshots/screenshot_${TIMESTAMP}.png"