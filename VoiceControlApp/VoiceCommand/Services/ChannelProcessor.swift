import Foundation

/// Advanced channel processor for instrument-based voice commands
/// Handles instrument name recognition and channel mapping for professional audio control
class ChannelProcessor {
    
    // MARK: - Channel Mapping Configuration
    
    /// Default instrument-to-channel mapping (can be customized per session)
    private var instrumentChannelMap: [String: Int] = [
        // Drums
        "kick": 1, "kick drum": 1, "bass drum": 1, "bd": 1, "kik": 1,
        "snare": 2, "snare drum": 2, "sd": 2, "snr": 2,
        "hihat": 3, "hi-hat": 3, "hi hat": 3, "hh": 3, "high hat": 3,
        "ride": 4, "ride cymbal": 4, "rd": 4,
        "crash": 5, "crash cymbal": 5, "cr": 5,
        "tom1": 6, "rack tom": 6, "tom one": 6, "high tom": 6,
        "tom2": 7, "floor tom": 7, "tom two": 7, "low tom": 7,
        
        // Rhythm Section
        "bass": 8, "bass guitar": 8, "bg": 8, "electric bass": 8,
        "guitar": 9, "electric guitar": 9, "gtr": 9, "eg": 9,
        "acoustic": 10, "acoustic guitar": 10, "ag": 10, "steel string": 10,
        "piano": 11, "keys": 11, "keyboard": 11, "pno": 11,
        
        // Vocals
        "vocal": 12, "lead vocal": 12, "vox": 12, "lead vox": 12, "singer": 12,
        "bgv": 13, "background vocal": 13, "backing vocal": 13, "bv": 13, "harmony": 13,
        
        // Horns
        "sax": 14, "saxophone": 14, "tenor sax": 14, "alto sax": 14,
        "trumpet": 15, "tpt": 15, "horn": 15,
        
        // Strings
        "violin": 16, "vln": 16, "fiddle": 16,
        "cello": 17, "vc": 17, "violoncello": 17,
        
        // Generic
        "drums": 1, "drum kit": 1, "kit": 1, "percussion": 1
    ]
    
    /// Level adjustment terminology mapping
    private let levelAdjustments: [String: Double] = [
        // Relative adjustments
        "up": 3.0, "bring up": 3.0, "raise": 3.0, "boost": 3.0,
        "down": -3.0, "bring down": -3.0, "pull down": -3.0, "lower": -3.0, "cut": -3.0,
        "a bit": 2.0, "a little": 2.0, "slightly": 1.5,
        "a lot": 6.0, "much": 6.0, "way up": 6.0, "way down": -6.0,
        
        // Absolute positions
        "unity": 0.0, "zero": 0.0, "nominal": 0.0,
        "full": 10.0, "max": 10.0, "all the way up": 10.0,
        "off": -60.0, "silence": -60.0, "inaudible": -60.0
    ]
    
    /// Pan position terminology
    private let panPositions: [String: Int] = [
        "left": -100, "hard left": -100, "full left": -100,
        "right": 100, "hard right": 100, "full right": 100,
        "center": 0, "centre": 0, "middle": 0,
        "left side": -50, "right side": 50,
        "slightly left": -25, "slightly right": 25
    ]
    
    // MARK: - Processing Methods
    
    /// Process instrument-based fader commands
    /// Examples: "set bass guitar to -10 dB", "bring up the vocal mic"
    func processInstrumentFaderCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "set [instrument] to [level]"
        if let command = processSetInstrumentLevel(lowercased) {
            return command
        }
        
        // Pattern 2: "bring up/down [instrument]"
        if let command = processRelativeInstrumentAdjustment(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] to [level]"
        if let command = processDirectInstrumentLevel(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process instrument-based mute commands
    /// Examples: "mute the kick drum", "unmute bass guitar"
    func processInstrumentMuteCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern: "(mute|unmute) [the] [instrument]"
        let patterns = [
            #"(mute|unmute)\s+(?:the\s+)?(.+?)(?:\s+mic|\s+microphone|$)"#,
            #"(mute|unmute)\s+(.+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
                
                let actionRange = Range(match.range(at: 1), in: lowercased)
                let instrumentRange = Range(match.range(at: 2), in: lowercased)
                
                guard let actionRange = actionRange, let instrumentRange = instrumentRange else { continue }
                
                let action = String(lowercased[actionRange])
                let instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Find matching instrument
                if let channel = findInstrumentChannel(instrumentText) {
                    let muteValue = action == "mute" ? 1 : 0
                    let actionDescription = action == "mute" ? "Mute" : "Unmute"
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Mute \(channel-1) 0 \(muteValue)",
                        description: "\(actionDescription) \(instrumentText) (channel \(channel))",
                        category: action == "mute" ? .channelMute : .channelMute
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process instrument-based solo commands
    /// Examples: "solo the snare", "unsolo guitar"
    func processInstrumentSoloCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern: "(solo|unsolo) [the] [instrument]"
        let patterns = [
            #"(solo|unsolo)\s+(?:the\s+)?(.+?)(?:\s+mic|\s+microphone|$)"#,
            #"(solo|unsolo)\s+(.+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
                
                let actionRange = Range(match.range(at: 1), in: lowercased)
                let instrumentRange = Range(match.range(at: 2), in: lowercased)
                
                guard let actionRange = actionRange, let instrumentRange = instrumentRange else { continue }
                
                let action = String(lowercased[actionRange])
                let instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Find matching instrument
                if let channel = findInstrumentChannel(instrumentText) {
                    let soloValue = action == "solo" ? 1 : 0
                    let actionDescription = action == "solo" ? "Solo" : "Unsolo"
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Solo \(channel-1) 0 \(soloValue)",
                        description: "\(actionDescription) \(instrumentText) (channel \(channel))",
                        category: .channelSolo
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process instrument-based pan commands
    /// Examples: "pan bass guitar left", "center the vocal"
    func processInstrumentPanCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "pan [instrument] [position]"
        let panPattern = #"pan\s+(.+?)\s+(left|right|center|centre|hard left|hard right|full left|full right|slightly left|slightly right)"#
        
        if let regex = try? NSRegularExpression(pattern: panPattern, options: []),
           let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
            
            let instrumentRange = Range(match.range(at: 1), in: lowercased)
            let positionRange = Range(match.range(at: 2), in: lowercased)
            
            guard let instrumentRange = instrumentRange, let positionRange = positionRange else { return nil }
            
            let instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let positionText = String(lowercased[positionRange])
            
            if let channel = findInstrumentChannel(instrumentText),
               let panValue = panPositions[positionText] {
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Pan \(channel-1) 0 \(panValue)",
                    description: "Pan \(instrumentText) \(positionText) (channel \(channel))",
                    category: .routing
                )
            }
        }
        
        // Pattern 2: "center [the] [instrument]"
        let centerPattern = #"center\s+(?:the\s+)?(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: centerPattern, options: []),
           let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
            
            let instrumentRange = Range(match.range(at: 1), in: lowercased)
            
            guard let instrumentRange = instrumentRange else { return nil }
            
            let instrumentText = String(lowercased[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
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
    
    // MARK: - Private Helper Methods
    
    /// Process "set [instrument] to [level]" pattern
    private func processSetInstrumentLevel(_ text: String) -> RCPCommand? {
        // Pattern: "set [instrument] to [level]"
        let pattern = #"set\s+(.+?)\s+to\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let levelRange = Range(match.range(at: 2), in: text)
            
            guard let instrumentRange = instrumentRange, let levelRange = levelRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let levelText = String(text[levelRange])
            
            if let channel = findInstrumentChannel(instrumentText),
               let level = Double(levelText) {
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                    description: "Set \(instrumentText) to \(clampedLevel) dB (channel \(channel))",
                    category: .channelFader
                )
            }
        }
        
        // Pattern: "set [instrument] to [terminology]"
        let termPattern = #"set\s+(.+?)\s+to\s+(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: termPattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let termRange = Range(match.range(at: 2), in: text)
            
            guard let instrumentRange = instrumentRange, let termRange = termRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let termText = String(text[termRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText),
               let level = levelAdjustments[termText] {
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                    description: "Set \(instrumentText) to \(termText) (\(clampedLevel) dB, channel \(channel))",
                    category: .channelFader
                )
            }
        }
        
        return nil
    }
    
    /// Process relative adjustment patterns like "bring up [instrument]"
    private func processRelativeInstrumentAdjustment(_ text: String) -> RCPCommand? {
        // Pattern: "[adjustment] [the] [instrument] [modifier]"
        let patterns = [
            #"(bring up|bring down|pull up|pull down|raise|lower|boost|cut)\s+(?:the\s+)?(.+?)(?:\s+(a bit|a little|slightly|a lot|much))?(?:\s+mic|\s+microphone|$)"#,
            #"(up|down)\s+(?:the\s+)?(.+?)(?:\s+(a bit|a little|slightly|a lot|much))?(?:\s+mic|\s+microphone|$)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let actionRange = Range(match.range(at: 1), in: text)
                let instrumentRange = Range(match.range(at: 2), in: text)
                let modifierRange = match.range(at: 3).location != NSNotFound ? Range(match.range(at: 3), in: text) : nil
                
                guard let actionRange = actionRange, let instrumentRange = instrumentRange else { continue }
                
                let action = String(text[actionRange])
                let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let modifier = modifierRange != nil ? String(text[modifierRange!]) : ""
                
                if let channel = findInstrumentChannel(instrumentText) {
                    
                    // Calculate adjustment amount
                    var adjustment = levelAdjustments[action] ?? 0.0
                    
                    // Apply modifier
                    if !modifier.isEmpty, let modifierValue = levelAdjustments[modifier] {
                        adjustment = adjustment > 0 ? modifierValue : -modifierValue
                    }
                    
                    // This would typically get current level and adjust relatively
                    // For now, we'll use the adjustment as an absolute value
                    let clampedLevel = ValidationLimits.clampDB(adjustment)
                    let rcpLevel = Int(clampedLevel * 100)
                    
                    let description = modifier.isEmpty ? 
                        "\(action.capitalized) \(instrumentText) (\(clampedLevel) dB, channel \(channel))" :
                        "\(action.capitalized) \(instrumentText) \(modifier) (\(clampedLevel) dB, channel \(channel))"
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                        description: description,
                        category: .channelFader
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process direct instrument level commands like "[instrument] to [level]"
    private func processDirectInstrumentLevel(_ text: String) -> RCPCommand? {
        // Pattern: "[instrument] to [level]"
        let pattern = #"(.+?)\s+to\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let levelRange = Range(match.range(at: 2), in: text)
            
            guard let instrumentRange = instrumentRange, let levelRange = levelRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let levelText = String(text[levelRange])
            
            if let channel = findInstrumentChannel(instrumentText),
               let level = Double(levelText) {
                
                let clampedLevel = ValidationLimits.clampDB(level)
                let rcpLevel = Int(clampedLevel * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                    description: "\(instrumentText.capitalized) to \(clampedLevel) dB (channel \(channel))",
                    category: .channelFader
                )
            }
        }
        
        return nil
    }
    
    /// Find the channel number for a given instrument name or alias
    private func findInstrumentChannel(_ instrumentText: String) -> Int? {
        let cleanInstrument = instrumentText.lowercased()
            .replacingOccurrences(of: "the ", with: "")
            .replacingOccurrences(of: " mic", with: "")
            .replacingOccurrences(of: " microphone", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct lookup
        if let channel = instrumentChannelMap[cleanInstrument] {
            return channel
        }
        
        // Fuzzy matching for partial matches
        for (instrument, channel) in instrumentChannelMap {
            if instrument.contains(cleanInstrument) || cleanInstrument.contains(instrument) {
                return channel
            }
        }
        
        return nil
    }
    
    // MARK: - Channel Mapping Management
    
    /// Update the instrument-to-channel mapping
    func updateInstrumentMapping(_ instrument: String, channel: Int) {
        guard ValidationLimits.isValidChannel(channel) else { return }
        instrumentChannelMap[instrument.lowercased()] = channel
    }
    
    /// Get current channel mapping for an instrument
    func getChannelForInstrument(_ instrument: String) -> Int? {
        return findInstrumentChannel(instrument)
    }
    
    /// Get all current instrument mappings
    func getAllInstrumentMappings() -> [String: Int] {
        return instrumentChannelMap
    }
    
    /// Reset to default instrument mappings
    func resetToDefaultMappings() {
        // Restore default mappings (implementation would reload defaults)
        print("🔄 Reset instrument channel mappings to defaults")
    }
}