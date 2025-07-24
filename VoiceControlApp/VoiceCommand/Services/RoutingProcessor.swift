import Foundation

/// Advanced routing processor for send-to-mix, aux sends, and pan commands
/// Handles routing-related voice commands for professional audio mixing
class RoutingProcessor {
    
    // MARK: - Routing Configuration
    
    /// Available mix destinations (aux sends, reverb sends, etc.)
    private let mixDestinations: [String: Int] = [
        // Aux sends
        "aux 1": 1, "aux one": 1, "aux1": 1, "send 1": 1, "send one": 1,
        "aux 2": 2, "aux two": 2, "aux2": 2, "send 2": 2, "send two": 2,
        "aux 3": 3, "aux three": 3, "aux3": 3, "send 3": 3, "send three": 3,
        "aux 4": 4, "aux four": 4, "aux4": 4, "send 4": 4, "send four": 4,
        
        // Named sends (common studio configurations)
        "reverb": 1, "reverb send": 1, "verb": 1,
        "delay": 2, "delay send": 2, "echo": 2,
        "chorus": 3, "chorus send": 3, "modulation": 3,
        "monitor": 4, "monitor send": 4, "headphones": 4, "cue": 4,
        
        // Effect sends
        "effects": 5, "fx": 5, "effect send": 5, "fx send": 5,
        "compressor send": 6, "comp send": 6,
        "eq send": 7, "equalizer send": 7
    ]
    
    /// Pan position mappings with fine control
    private let panPositions: [String: Int] = [
        // Hard positions
        "hard left": -100, "full left": -100, "extreme left": -100,
        "hard right": 100, "full right": 100, "extreme right": 100,
        
        // Standard positions
        "left": -75, "right": 75,
        "center": 0, "centre": 0, "middle": 0,
        
        // Fine positions
        "slightly left": -25, "a bit left": -25, "little left": -25,
        "slightly right": 25, "a bit right": 25, "little right": 25,
        "left side": -50, "right side": 50,
        "more left": -60, "more right": 60,
        "way left": -85, "way right": 85,
        
        // Numeric positions (common mixing points)
        "10 left": -10, "20 left": -20, "30 left": -30,
        "10 right": 10, "20 right": 20, "30 right": 30,
        "45 left": -45, "45 right": 45
    ]
    
    /// Send level terminology
    private let sendLevels: [String: Double] = [
        // Relative levels
        "off": -60.0, "none": -60.0, "zero": -60.0,
        "low": -20.0, "little": -15.0, "small": -18.0,
        "medium": -10.0, "normal": -10.0, "standard": -10.0,
        "high": -3.0, "loud": -3.0, "strong": -3.0,
        "full": 0.0, "max": 0.0, "unity": 0.0,
        
        // Specific percentages
        "quarter": -12.0, "half": -6.0, "three quarters": -2.5,
        "10 percent": -20.0, "25 percent": -12.0, "50 percent": -6.0,
        "75 percent": -2.5, "100 percent": 0.0
    ]
    
    // MARK: - Processing Methods
    
    /// Process send-to-mix commands
    /// Examples: "send kick drum to reverb", "aux 1 from bass guitar at -10 dB"
    func processSendCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "send [instrument] to [destination]"
        if let command = processSendToDestination(lowercased) {
            return command
        }
        
        // Pattern 2: "[destination] from [instrument] at [level]"
        if let command = processDestinationFromSource(lowercased) {
            return command
        }
        
        // Pattern 3: "set [instrument] [destination] send to [level]"
        if let command = processSetSendLevel(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process pan commands with fine control
    /// Examples: "pan guitar slightly left", "center the vocal", "guitar 30 degrees right"
    func processPanCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "pan [instrument] [position]"
        if let command = processPanInstrumentToPosition(lowercased) {
            return command
        }
        
        // Pattern 2: "center [instrument]" or "centre [instrument]"
        if let command = processCenterCommand(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] [degrees] [left/right]"
        if let command = processNumericPanCommand(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process routing matrix commands
    /// Examples: "route channel 1 to main mix", "disconnect bass from aux 2"
    func processRoutingCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "route [source] to [destination]"
        if let command = processRouteToDestination(lowercased) {
            return command
        }
        
        // Pattern 2: "disconnect [source] from [destination]"
        if let command = processDisconnectCommand(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process stereo width/imaging commands
    /// Examples: "widen the piano", "narrow the drums", "make vocal mono"
    func processStereoCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern: "(widen|narrow|mono|stereo) [the] [instrument]"
        let patterns = [
            #"(widen|narrow|mono|stereo)\s+(?:the\s+)?(.+)"#,
            #"make\s+(.+?)\s+(wider|narrower|mono|stereo)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
                
                var action: String
                var instrumentText: String
                
                if pattern.starts(with: "(widen|narrow") {
                    // First pattern: action comes first
                    let actionRange = Range(match.range(at: 1), in: lowercased)
                    let instrumentRange = Range(match.range(at: 2), in: lowercased)
                    
                    guard let actionRange = actionRange, let instrumentRange = instrumentRange else { continue }
                    
                    action = String(lowercased[actionRange])
                    instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    // Second pattern: "make [instrument] [action]"
                    let instrumentRange = Range(match.range(at: 1), in: lowercased)
                    let actionRange = Range(match.range(at: 2), in: lowercased)
                    
                    guard let instrumentRange = instrumentRange, let actionRange = actionRange else { continue }
                    
                    instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    action = String(lowercased[actionRange])
                }
                
                // Find channel for instrument
                if let channel = findInstrumentChannel(instrumentText) {
                    let stereoValue = getStereoWidthValue(for: action)
                    let description = getActionDescription(action, instrument: instrumentText, channel: channel)
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/StereoWidth \(channel-1) 0 \(stereoValue)",
                        description: description,
                        category: .routing
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Process "send [instrument] to [destination]" pattern
    private func processSendToDestination(_ text: String) -> RCPCommand? {
        let pattern = #"send\s+(.+?)\s+to\s+(.+?)(?:\s+at\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?)?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let destinationRange = Range(match.range(at: 2), in: text)
            let levelRange = match.range(at: 3).location != NSNotFound ? Range(match.range(at: 3), in: text) : nil
            
            guard let instrumentRange = instrumentRange, let destinationRange = destinationRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let destinationText = String(text[destinationRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText),
               let auxSend = mixDestinations[destinationText] {
                
                let level: Double
                if let levelRange = levelRange {
                    level = Double(String(text[levelRange])) ?? -10.0
                } else {
                    level = -10.0 // Default send level
                }
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Send/Level \(channel-1) \(auxSend-1) \(rcpLevel)",
                    description: "Send \(instrumentText) to \(destinationText) at \(clampedLevel) dB (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process "[destination] from [instrument] at [level]" pattern
    private func processDestinationFromSource(_ text: String) -> RCPCommand? {
        let pattern = #"(.+?)\s+from\s+(.+?)\s+at\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let destinationRange = Range(match.range(at: 1), in: text)
            let instrumentRange = Range(match.range(at: 2), in: text)
            let levelRange = Range(match.range(at: 3), in: text)
            
            guard let destinationRange = destinationRange,
                  let instrumentRange = instrumentRange,
                  let levelRange = levelRange else { return nil }
            
            let destinationText = String(text[destinationRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let levelText = String(text[levelRange])
            
            if let channel = findInstrumentChannel(instrumentText),
               let auxSend = mixDestinations[destinationText],
               let level = Double(levelText) {
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Send/Level \(channel-1) \(auxSend-1) \(rcpLevel)",
                    description: "\(destinationText.capitalized) from \(instrumentText) at \(clampedLevel) dB (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process "set [instrument] [destination] send to [level]" pattern
    private func processSetSendLevel(_ text: String) -> RCPCommand? {
        let pattern = #"set\s+(.+?)\s+(.+?)\s+send\s+to\s+(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let destinationRange = Range(match.range(at: 2), in: text)
            let levelRange = Range(match.range(at: 3), in: text)
            
            guard let instrumentRange = instrumentRange,
                  let destinationRange = destinationRange,
                  let levelRange = levelRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let destinationText = String(text[destinationRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let levelText = String(text[levelRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText),
               let auxSend = mixDestinations[destinationText] {
                
                let level: Double
                if let numericLevel = Double(levelText) {
                    level = numericLevel
                } else if let termLevel = sendLevels[levelText] {
                    level = termLevel
                } else {
                    return nil
                }
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Send/Level \(channel-1) \(auxSend-1) \(rcpLevel)",
                    description: "Set \(instrumentText) \(destinationText) send to \(levelText) (\(clampedLevel) dB, channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process "pan [instrument] [position]" pattern
    private func processPanInstrumentToPosition(_ text: String) -> RCPCommand? {
        let pattern = #"pan\s+(.+?)\s+([\w\s]+?)(?:\s+(?:degrees?|percent))?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let positionRange = Range(match.range(at: 2), in: text)
            
            guard let instrumentRange = instrumentRange, let positionRange = positionRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let positionText = String(text[positionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText),
               let panValue = panPositions[positionText] {
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Pan \(channel-1) 0 \(panValue)",
                    description: "Pan \(instrumentText) \(positionText) (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process "center [instrument]" pattern
    private func processCenterCommand(_ text: String) -> RCPCommand? {
        let pattern = #"(?:center|centre)\s+(?:the\s+)?(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            
            guard let instrumentRange = instrumentRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText) {
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Pan \(channel-1) 0 0",
                    description: "Center \(instrumentText) (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process numeric pan commands like "[instrument] 30 degrees right"
    private func processNumericPanCommand(_ text: String) -> RCPCommand? {
        let pattern = #"(.+?)\s+(\d+)\s*(?:degrees?|percent)?\s+(left|right)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let numberRange = Range(match.range(at: 2), in: text)
            let directionRange = Range(match.range(at: 3), in: text)
            
            guard let instrumentRange = instrumentRange,
                  let numberRange = numberRange,
                  let directionRange = directionRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let numberText = String(text[numberRange])
            let direction = String(text[directionRange])
            
            if let channel = findInstrumentChannel(instrumentText),
               let degrees = Int(numberText) {
                
                let panValue = direction == "left" ? -min(degrees, 100) : min(degrees, 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Pan \(channel-1) 0 \(panValue)",
                    description: "Pan \(instrumentText) \(degrees)° \(direction) (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Process routing commands
    private func processRouteToDestination(_ text: String) -> RCPCommand? {
        let pattern = #"route\s+(.+?)\s+to\s+(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let sourceRange = Range(match.range(at: 1), in: text)
            let destinationRange = Range(match.range(at: 2), in: text)
            
            guard let sourceRange = sourceRange, let destinationRange = destinationRange else { return nil }
            
            let sourceText = String(text[sourceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let destinationText = String(text[destinationRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(sourceText) {
                // For main mix routing
                if destinationText.contains("main") {
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/MainAssign \(channel-1) 0 1",
                        description: "Route \(sourceText) to main mix (channel \(channel))",
                        category: .routing
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process disconnect commands
    private func processDisconnectCommand(_ text: String) -> RCPCommand? {
        let pattern = #"disconnect\s+(.+?)\s+from\s+(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let sourceRange = Range(match.range(at: 1), in: text)
            let destinationRange = Range(match.range(at: 2), in: text)
            
            guard let sourceRange = sourceRange, let destinationRange = destinationRange else { return nil }
            
            let sourceText = String(text[sourceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let destinationText = String(text[destinationRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(sourceText),
               let auxSend = mixDestinations[destinationText] {
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Send/Level \(channel-1) \(auxSend-1) -6000",
                    description: "Disconnect \(sourceText) from \(destinationText) (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        return nil
    }
    
    /// Get stereo width value for action
    private func getStereoWidthValue(for action: String) -> Int {
        switch action {
        case "mono": return 0
        case "narrow", "narrower": return 25
        case "widen", "wider": return 150
        case "stereo": return 100
        default: return 100
        }
    }
    
    /// Get action description for stereo commands
    private func getActionDescription(_ action: String, instrument: String, channel: Int) -> String {
        switch action {
        case "mono": return "Make \(instrument) mono (channel \(channel))"
        case "narrow", "narrower": return "Narrow \(instrument) stereo image (channel \(channel))"
        case "widen", "wider": return "Widen \(instrument) stereo image (channel \(channel))"
        case "stereo": return "Make \(instrument) full stereo (channel \(channel))"
        default: return "Adjust \(instrument) stereo width (channel \(channel))"
        }
    }
    
    /// Find instrument channel using the same logic as ChannelProcessor
    private func findInstrumentChannel(_ instrumentText: String) -> Int? {
        // This would typically reference the ChannelProcessor's instrument mapping
        // For now, using a simplified lookup
        let instrumentChannelMap: [String: Int] = [
            "kick": 1, "kick drum": 1, "bass drum": 1, "bd": 1,
            "snare": 2, "snare drum": 2, "sd": 2,
            "hihat": 3, "hi-hat": 3, "hi hat": 3, "hh": 3,
            "bass": 8, "bass guitar": 8, "bg": 8,
            "guitar": 9, "electric guitar": 9, "gtr": 9,
            "vocal": 12, "lead vocal": 12, "vox": 12, "singer": 12,
            "piano": 11, "keys": 11, "keyboard": 11
        ]
        
        let cleanInstrument = instrumentText.lowercased()
            .replacingOccurrences(of: "the ", with: "")
            .replacingOccurrences(of: " mic", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return instrumentChannelMap[cleanInstrument]
    }
    
    // MARK: - Configuration Methods
    
    /// Add custom mix destination
    func addMixDestination(_ name: String, auxNumber: Int) {
        // This would update the mixDestinations dictionary
        print("🎛️ Added custom mix destination: \(name) -> Aux \(auxNumber)")
    }
    
    /// Get all available destinations
    func getAvailableDestinations() -> [String: Int] {
        return mixDestinations
    }
    
    /// Update pan position mapping
    func addPanPosition(_ name: String, value: Int) {
        // This would update the panPositions dictionary
        print("🎛️ Added custom pan position: \(name) -> \(value)")
    }
}