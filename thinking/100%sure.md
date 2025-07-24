# 🎛️ Speech-to-RCP Rule-Based System: Complete Beginner Guide

*Understanding how to convert "set channel 1 volume to 75" into Yamaha mixer commands*

---

## 🎯 What We're Actually Building

You got it totally wrong before - this isn't about cleaning up speech text. This is about **translating human speech into mixer control commands**.

**The Real Pipeline:**
```
Speech: "set channel 1 volume to 75"
       ↓
AssemblyAI: "set channel 1 volume to 75" 
       ↓
YOUR RULE SYSTEM: Parse and convert
       ↓  
RCP Command: "set MIXER:Current/InCh/Fader/Level 0 0 750"
       ↓
Yamaha Mixer: Actually moves the fader to 75%
```

---

## 📚 Part 1: Understanding Yamaha RCP Commands

### 🎛️ What is RCP?

**RCP = Remote Control Protocol** - Yamaha's way of controlling mixers via text commands over TCP.

### 🔧 RCP Command Structure

Every RCP command follows this pattern:
```
COMMAND MIXER:PATH/TO/FUNCTION channel_index mix_index value
```

**Examples from your docs:**
```bash
# Get channel 1 fader level
get MIXER:Current/InCh/Fader/Level 0 0

# Set channel 1 fader to 75% (750 in RCP units)  
set MIXER:Current/InCh/Fader/Level 0 0 750

# Turn channel 1 on/off
set MIXER:Current/InCh/Fader/On 0 0 1

# Set channel 16 name
set MIXER:Current/InCh/Label/Name 15 0 "Vocals"
```

### 🧮 RCP Data Types

**Decibels (Volume levels):**
- Real dB × 100 = RCP value
- 75% = 750 in RCP
- 0 dB = 0 in RCP  
- -∞ (mute) = -32768 in RCP

**Channel Numbers:**
- Human: "channel 1" → RCP: index 0
- Human: "channel 16" → RCP: index 15
- Always subtract 1!

**Boolean (On/Off):**
- "on" = 1
- "off" = 0

---

## 🧠 Part 2: Rule-Based System Concepts

### 🎯 What is a Rule-Based System?

A rule-based system uses **IF-THEN rules** to convert natural language into structured commands.

**Basic Rule Structure:**
```
IF speech contains "channel X volume to Y"
THEN generate "set MIXER:Current/InCh/Fader/Level (X-1) 0 (Y*10)"
```

### 🔀 Rule Types You Need

**1. Intent Detection Rules**
```swift
// Detect what the user wants to do
if speech.contains("set") || speech.contains("change") {
    intent = .setParameter
} else if speech.contains("mute") {
    intent = .muteChannel  
} else if speech.contains("get") || speech.contains("what is") {
    intent = .getParameter
}
```

**2. Entity Extraction Rules**
```swift
// Extract specific values from speech
let channelRegex = #"channel\s+(\d+)"#
let volumeRegex = #"volume\s+to\s+(\d+)"#
let onOffRegex = #"(on|off)"#
```

**3. Command Generation Rules**
```swift
// Convert intent + entities → RCP command
if intent == .setParameter && entity == .volume {
    return "set MIXER:Current/InCh/Fader/Level \(channelIndex) 0 \(volumeValue)"
}
```

---

## 🛠️ Part 3: Basic Implementation

### 🚪 Step 1: Intent Detection

```swift
enum MixerIntent {
    case setVolume
    case muteChannel
    case unmuteChannel
    case getVolume
    case setChannelName
    case unknown
}

func detectIntent(from speech: String) -> MixerIntent {
    let lowercased = speech.lowercased()
    
    // Volume control
    if lowercased.contains("set") && lowercased.contains("volume") {
        return .setVolume
    }
    
    if lowercased.contains("mute") && !lowercased.contains("unmute") {
        return .muteChannel
    }
    
    if lowercased.contains("unmute") || (lowercased.contains("turn") && lowercased.contains("on")) {
        return .unmuteChannel
    }
    
    if lowercased.contains("what") && lowercased.contains("volume") {
        return .getVolume
    }
    
    return .unknown
}
```

### 🎯 Step 2: Entity Extraction

```swift
struct MixerCommand {
    let channel: Int?
    let volume: Int?
    let isOn: Bool?
    let channelName: String?
}

func extractEntities(from speech: String) -> MixerCommand {
    var command = MixerCommand()
    
    // Extract channel number
    let channelPattern = #"(?:channel|ch)\s+(\d+)"#
    if let channelMatch = speech.range(of: channelPattern, options: .regularExpression) {
        let channelStr = String(speech[channelMatch]).components(separatedBy: .whitespaces).last
        command.channel = Int(channelStr ?? "")
    }
    
    // Extract volume level
    let volumePattern = #"(?:volume|level|fader)\s+(?:to\s+)?(\d+)"#
    if let volumeMatch = speech.range(of: volumePattern, options: .regularExpression) {
        let volumeStr = String(speech[volumeMatch]).components(separatedBy: .whitespaces).last
        command.volume = Int(volumeStr ?? "")
    }
    
    // Extract on/off state
    if speech.lowercased().contains("on") {
        command.isOn = true
    } else if speech.lowercased().contains("off") {
        command.isOn = false
    }
    
    return command
}
```

### ⚙️ Step 3: RCP Command Generation

```swift
func generateRCPCommand(intent: MixerIntent, entities: MixerCommand) -> String? {
    guard let channel = entities.channel else { return nil }
    let channelIndex = channel - 1  // Convert to 0-based index
    
    switch intent {
    case .setVolume:
        guard let volume = entities.volume else { return nil }
        let rcpVolume = volume * 10  // Convert percentage to RCP units
        return "set MIXER:Current/InCh/Fader/Level \(channelIndex) 0 \(rcpVolume)"
        
    case .muteChannel:
        return "set MIXER:Current/InCh/Fader/On \(channelIndex) 0 0"
        
    case .unmuteChannel:
        return "set MIXER:Current/InCh/Fader/On \(channelIndex) 0 1"
        
    case .getVolume:
        return "get MIXER:Current/InCh/Fader/Level \(channelIndex) 0"
        
    default:
        return nil
    }
}
```

### 🔗 Step 4: Complete Processing Function

```swift
func processVoiceCommand(_ speech: String) -> String? {
    // 1. Detect what user wants to do
    let intent = detectIntent(from: speech)
    
    // 2. Extract specific values  
    let entities = extractEntities(from: speech)
    
    // 3. Generate RCP command
    let rcpCommand = generateRCPCommand(intent: intent, entities: entities)
    
    // 4. Log for debugging
    print("🎤 Speech: '\(speech)'")
    print("🧠 Intent: \(intent)")
    print("📊 Entities: \(entities)")
    print("🎛️ RCP: \(rcpCommand ?? "FAILED")")
    
    return rcpCommand
}
```

---

## 🧪 Part 4: Testing Your Rules

### 🎤 Test Cases

```swift
// Test your rule system with these examples:

processVoiceCommand("set channel 1 volume to 75")
// Expected: "set MIXER:Current/InCh/Fader/Level 0 0 750"

processVoiceCommand("mute channel 3") 
// Expected: "set MIXER:Current/InCh/Fader/On 2 0 0"

processVoiceCommand("turn on channel 5")
// Expected: "set MIXER:Current/InCh/Fader/On 4 0 1"

processVoiceCommand("what is channel 2 volume")
// Expected: "get MIXER:Current/InCh/Fader/Level 1 0"
```

### 🐛 Debug Your Rules

Add logging to see what's happening:

```swift
func debugRuleProcessing(_ speech: String) {
    print("=== RULE PROCESSING DEBUG ===")
    print("Input: '\(speech)'")
    
    // Test intent detection
    let intent = detectIntent(from: speech)
    print("Detected Intent: \(intent)")
    
    // Test entity extraction
    let entities = extractEntities(from: speech)
    print("Extracted Entities:")
    print("  - Channel: \(entities.channel ?? -1)")
    print("  - Volume: \(entities.volume ?? -1)")
    print("  - IsOn: \(entities.isOn?.description ?? "nil")")
    
    // Test command generation
    let command = generateRCPCommand(intent: intent, entities: entities)
    print("Generated RCP: \(command ?? "FAILED")")
    print("============================")
}
```

---

## 🚀 Part 5: Advanced Rule Patterns

### 🎯 Complex Pattern Matching

```swift
func detectComplexIntents(_ speech: String) -> MixerIntent {
    let patterns: [(String, MixerIntent)] = [
        (#"(?:set|change|adjust)\s+(?:channel|ch)\s+\d+\s+(?:volume|level|fader)"#, .setVolume),
        (#"(?:mute|silence)\s+(?:channel|ch)\s+\d+"#, .muteChannel),
        (#"(?:unmute|turn\s+on)\s+(?:channel|ch)\s+\d+"#, .unmuteChannel),
        (#"(?:what|get|show)\s+(?:is\s+)?(?:channel|ch)\s+\d+\s+(?:volume|level)"#, .getVolume)
    ]
    
    for (pattern, intent) in patterns {
        if speech.range(of: pattern, options: .regularExpression) != nil {
            return intent
        }
    }
    
    return .unknown
}
```

### 🔄 Context-Aware Rules

```swift
class VoiceCommandProcessor {
    private var lastChannel: Int?
    private var lastVolume: Int?
    
    func processWithContext(_ speech: String) -> String? {
        var entities = extractEntities(from: speech)
        
        // Fill in missing context
        if entities.channel == nil && speech.contains("that channel") {
            entities.channel = lastChannel
        }
        
        if entities.volume == nil && speech.contains("same level") {
            entities.volume = lastVolume
        }
        
        // Remember for next time
        lastChannel = entities.channel
        lastVolume = entities.volume
        
        let intent = detectIntent(from: speech)
        return generateRCPCommand(intent: intent, entities: entities)
    }
}
```

### 🎛️ Multiple Channel Commands

```swift
func handleMultipleChannels(_ speech: String) -> [String] {
    var commands: [String] = []
    
    // Handle "channels 1 through 4"
    let rangePattern = #"channels?\s+(\d+)\s+(?:through|to|thru)\s+(\d+)"#
    if let match = speech.range(of: rangePattern, options: .regularExpression) {
        // Extract start and end channels
        // Generate commands for each channel in range
    }
    
    // Handle "channels 1, 3, and 5"
    let listPattern = #"channels?\s+([\d,\s]+)"#
    if let match = speech.range(of: listPattern, options: .regularExpression) {
        // Parse comma-separated list
        // Generate command for each channel
    }
    
    return commands
}
```

---

## 🎪 Part 6: Integration with Your iOS App

### 🔌 Where to Add This

In your `AssemblyAIStreamer.swift`, modify the message handling:

```swift
// Around line 267, in handleIncomingMessage
if turn.end_of_turn == true {
    let finalText = // ... existing code
    
    // NEW: Convert speech to RCP commands
    if let rcpCommand = processVoiceCommand(finalText) {
        // Send to Yamaha mixer
        sendRCPCommand(rcpCommand)
        
        // Update UI to show command was sent
        Task { @MainActor in
            transcriptionText = finalText + " → \(rcpCommand)"
        }
    } else {
        // Just show the speech if no command recognized
        Task { @MainActor in
            transcriptionText = finalText
        }
    }
}
```

### 🌐 RCP Network Communication

```swift
class YamahaRCPClient {
    private var socket: TCPSocket?
    
    func connect(to host: String, port: Int = 49280) {
        // Establish TCP connection to Yamaha mixer
    }
    
    func sendCommand(_ command: String) {
        guard let socket = socket else { return }
        
        let commandWithNewline = command + "\n"
        socket.send(data: commandWithNewline.data(using: .utf8)!)
        
        print("📡 Sent to mixer: \(command)")
    }
    
    func receiveResponse() -> String? {
        // Read response from mixer (OK, ERROR, etc.)
    }
}
```

---

## 🎯 Part 7: Real-World Examples

### 🎤 Common Voice Commands → RCP

```swift
// Volume control
"set channel 1 volume to 75"
→ "set MIXER:Current/InCh/Fader/Level 0 0 750"

"turn down channel 3 to 50"  
→ "set MIXER:Current/InCh/Fader/Level 2 0 500"

// Muting
"mute channel 2"
→ "set MIXER:Current/InCh/Fader/On 1 0 0"

"unmute channel 5"
→ "set MIXER:Current/InCh/Fader/On 4 0 1"

// Status queries
"what is channel 4 volume"
→ "get MIXER:Current/InCh/Fader/Level 3 0"

// Channel naming
"name channel 1 vocals"
→ "set MIXER:Current/InCh/Label/Name 0 0 \"Vocals\""

// Multiple channels
"mute channels 1 through 4"
→ ["set MIXER:Current/InCh/Fader/On 0 0 0",
   "set MIXER:Current/InCh/Fader/On 1 0 0", 
   "set MIXER:Current/InCh/Fader/On 2 0 0",
   "set MIXER:Current/InCh/Fader/On 3 0 0"]
```

### 🔧 Edge Cases to Handle

```swift
// Ambiguous commands
"turn it up" → Need context: which channel?

// Out of range values
"set channel 1 volume to 150" → Clamp to 100

// Invalid channels  
"set channel 99 volume to 50" → Error handling

// Typos in speech recognition
"set channel won volume to seventy five" → Number conversion
```

---

## 🚨 Part 8: Common Problems & Solutions

### ⚠️ Problem: Regex Not Matching

```swift
// BAD - Too strict
#"set channel (\d+) volume to (\d+)"#

// GOOD - Flexible matching
#"(?:set|change|adjust)\s+(?:channel|ch)\s+(\d+)\s+(?:volume|level)\s+(?:to\s+)?(\d+)"#
```

### ⚠️ Problem: Speech Recognition Errors

```swift
// Handle common speech-to-text errors
func normalizeAudioInput(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "channel won", with: "channel 1")
        .replacingOccurrences(of: "channel to", with: "channel 2") 
        .replacingOccurrences(of: "seventy five", with: "75")
        .replacingOccurrences(of: "volume two", with: "volume to")
}
```

### ⚠️ Problem: No Response from Mixer

```swift
func sendRCPCommandWithRetry(_ command: String, maxRetries: Int = 3) {
    for attempt in 1...maxRetries {
        sendCommand(command)
        
        if let response = receiveResponse(timeout: 2.0) {
            if response.starts(with: "OK") {
                print("✅ Command successful: \(command)")
                return
            } else {
                print("❌ Command failed: \(response)")
            }
        }
        
        if attempt < maxRetries {
            print("🔄 Retrying command (\(attempt)/\(maxRetries))")
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
}
```

---

## 🎊 Part 9: Action Plan

### 📝 Step 1: Create Basic Rule System (30 minutes)

1. Create `VoiceCommandProcessor.swift`
2. Implement basic intent detection
3. Add entity extraction for channels and volumes
4. Test with simple commands

### 📝 Step 2: Integrate with Speech Processing (15 minutes)

1. Modify `AssemblyAIStreamer.swift` line 267
2. Add call to `processVoiceCommand()`
3. Test speech-to-RCP conversion

### 📝 Step 3: Add Network Communication (45 minutes)

1. Create `YamahaRCPClient.swift`
2. Implement TCP socket connection
3. Add command sending and response handling
4. Test with actual Yamaha mixer

### 📝 Step 4: Expand Rule Coverage (Ongoing)

1. Add more command types (pan, EQ, effects)
2. Handle multiple channels
3. Add context awareness
4. Improve error handling

---

## 🤔 Quick Q&A

**Q: How do I know if my rules are working?**
A: Add debug logging and test with known phrases. Check that entities are extracted correctly.

**Q: What if the mixer doesn't respond?**
A: Check network connection, verify RCP command syntax, ensure mixer's RCP is enabled.

**Q: How do I handle speech recognition errors?**
A: Add normalization step before rule processing to fix common speech-to-text mistakes.

**Q: Should I use regex or string matching?**
A: Start with simple string matching, upgrade to regex for complex patterns.

---

## 🎉 You Now Understand!

**Rule-based systems convert natural speech into structured commands using:**
- ✅ **Intent Detection** - What does the user want?
- ✅ **Entity Extraction** - What are the specific values? 
- ✅ **Command Generation** - How to format the RCP command?
- ✅ **Error Handling** - What if something goes wrong?

**This is way more useful than just cleaning up text - you're building a voice-controlled mixer! 🎛️🚀**

---

*Now go build some sick voice control rules and make that mixer dance to your commands! 🎵*