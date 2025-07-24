import Foundation

/// Test helper for simulating voice command input during development
/// Provides programmatic testing of voice command processing accuracy
class VoiceCommandTester {
    
    private let processor: VoiceCommandProcessor
    
    init(processor: VoiceCommandProcessor) {
        self.processor = processor
    }
    
    /// Test various professional audio commands
    func runBasicCommandTests() {
        let testCommands = [
            "set channel 1 to minus 6 dB",
            "mute channel 2", 
            "unmute channel 3",
            "recall scene 5",
            "channel 4 to unity",
            "set channel 8 to -12.5 dB"
        ]
        
        print("🎛️ Testing basic voice commands...")
        
        for command in testCommands {
            print("Processing: \"\(command)\"")
            processor.processTranscription(command)
            
            // Small delay between commands
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// Test advanced terminology (will show as warnings in Phase 1)
    func runAdvancedTerminologyTests() {
        let advancedCommands = [
            "mute the kick drum",
            "set bass guitar to minus 10 dB", 
            "bring up the vocal mic",
            "pull down the snare",
            "set channel 1 to minus 6 and mute channel 2"
        ]
        
        print("🎯 Testing advanced terminology...")
        
        for command in advancedCommands {
            print("Processing: \"\(command)\"")
            processor.processTranscription(command)
            
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// Test edge cases and error handling
    func runEdgeCaseTests() {
        let edgeCases = [
            "channel 99 to 0 dB", // Invalid channel
            "set channel 1 to +50 dB", // Out of range dB (should clamp)
            "", // Empty input
            "this is not a valid command", // Unrecognized input
            "set channel one to minus six dB" // Word numbers
        ]
        
        print("🔍 Testing edge cases...")
        
        for command in edgeCases {
            print("Processing: \"\(command)\"")
            processor.processTranscription(command)
            
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}