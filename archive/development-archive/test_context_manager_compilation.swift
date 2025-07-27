#!/usr/bin/env swift

import Foundation

// Test compilation of ContextManager dependencies
// This will help identify any missing dependencies or types

// Check if the required types exist
let testCommandCategory: CommandCategory = .channelFader
print("✅ CommandCategory accessible")

// Check if ProcessedVoiceCommand exists 
// Note: This will fail since we can't import the full project context
// but it will show us what's missing

print("🧪 ContextManager compilation test completed")