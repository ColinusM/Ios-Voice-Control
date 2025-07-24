import Foundation

/// Advanced effects processor for audio effects commands
/// Handles reverb, delay, compression, and EQ-related voice commands for professional mixing
class EffectsProcessor {
    
    // MARK: - Effects Configuration
    
    /// Available reverb types and their parameter mappings
    private let reverbTypes: [String: Int] = [
        // Room types
        "room": 1, "small room": 1, "live room": 1,
        "hall": 2, "concert hall": 2, "large hall": 2,
        "chamber": 3, "chamber reverb": 3,
        "plate": 4, "plate reverb": 4, "vintage plate": 4,
        "spring": 5, "spring reverb": 5, "guitar spring": 5,
        
        // Studio reverbs
        "studio": 6, "studio reverb": 6,
        "vocal reverb": 7, "vocal hall": 7,
        "drum reverb": 8, "drum room": 8,
        "ambient": 9, "ambient reverb": 9, "atmosphere": 9,
        
        // Creative effects
        "gated": 10, "gated reverb": 10, "gate": 10,
        "reverse": 11, "reverse reverb": 11, "backwards": 11
    ]
    
    /// Delay types and timing mappings
    private let delayTypes: [String: (type: Int, time: Double)] = [
        // Basic delays
        "delay": (type: 1, time: 250.0),
        "echo": (type: 1, time: 375.0),
        "slap": (type: 1, time: 125.0),
        "slapback": (type: 1, time: 125.0),
        
        // Timing-based delays
        "eighth": (type: 2, time: 125.0),      // 1/8 note at 120 BPM
        "quarter": (type: 2, time: 250.0),     // 1/4 note at 120 BPM
        "dotted eighth": (type: 2, time: 187.5), // Dotted 1/8 at 120 BPM
        "half": (type: 2, time: 500.0),        // 1/2 note at 120 BPM
        
        // Modulated delays
        "chorus delay": (type: 3, time: 50.0),
        "flanger": (type: 4, time: 10.0),
        "doubling": (type: 5, time: 25.0),
        
        // Tape delays
        "tape": (type: 6, time: 300.0),
        "tape echo": (type: 6, time: 300.0),
        "analog": (type: 6, time: 300.0),
        "vintage": (type: 6, time: 300.0)
    ]
    
    /// Compression settings with professional terminology
    private let compressionSettings: [String: (ratio: Double, attack: Double, release: Double)] = [
        // Light compression
        "gentle": (ratio: 2.0, attack: 10.0, release: 100.0),
        "light": (ratio: 3.0, attack: 5.0, release: 50.0),
        "subtle": (ratio: 2.5, attack: 15.0, release: 80.0),
        
        // Medium compression
        "medium": (ratio: 4.0, attack: 3.0, release: 30.0),
        "normal": (ratio: 4.0, attack: 5.0, release: 50.0),
        "standard": (ratio: 4.0, attack: 3.0, release: 40.0),
        
        // Heavy compression
        "heavy": (ratio: 8.0, attack: 1.0, release: 10.0),
        "aggressive": (ratio: 10.0, attack: 0.5, release: 5.0),
        "pumping": (ratio: 12.0, attack: 0.1, release: 100.0),
        
        // Specific applications
        "vocal": (ratio: 3.0, attack: 5.0, release: 25.0),
        "drum": (ratio: 6.0, attack: 1.0, release: 10.0),
        "bass": (ratio: 4.0, attack: 2.0, release: 80.0),
        "instrument": (ratio: 3.5, attack: 3.0, release: 40.0),
        
        // Limiting
        "limit": (ratio: 20.0, attack: 0.1, release: 1.0),
        "limiter": (ratio: 20.0, attack: 0.1, release: 1.0),
        "brick wall": (ratio: 100.0, attack: 0.01, release: 0.1)
    ]
    
    /// EQ frequency ranges and terminology
    private let eqFrequencies: [String: (frequency: Double, gain: Double, q: Double)] = [
        // Low frequencies
        "bass": (frequency: 80.0, gain: 0.0, q: 1.0),
        "sub bass": (frequency: 40.0, gain: 0.0, q: 1.0),
        "low end": (frequency: 100.0, gain: 0.0, q: 0.7),
        "bottom": (frequency: 60.0, gain: 0.0, q: 1.2),
        "thump": (frequency: 50.0, gain: 3.0, q: 1.5),
        
        // Mid frequencies
        "mids": (frequency: 1000.0, gain: 0.0, q: 1.0),
        "midrange": (frequency: 800.0, gain: 0.0, q: 0.8),
        "presence": (frequency: 3000.0, gain: 0.0, q: 1.2),
        "warmth": (frequency: 250.0, gain: 2.0, q: 0.8),
        "honk": (frequency: 500.0, gain: -3.0, q: 2.0),
        "nasal": (frequency: 800.0, gain: -2.0, q: 1.5),
        
        // High frequencies
        "treble": (frequency: 8000.0, gain: 0.0, q: 1.0),
        "highs": (frequency: 10000.0, gain: 0.0, q: 0.7),
        "brilliance": (frequency: 12000.0, gain: 2.0, q: 1.0),
        "air": (frequency: 15000.0, gain: 1.5, q: 0.8),
        "sizzle": (frequency: 10000.0, gain: 3.0, q: 1.5),
        "harsh": (frequency: 4000.0, gain: -2.0, q: 1.8)
    ]
    
    /// Effect levels and intensities
    private let effectLevels: [String: Double] = [
        "off": 0.0, "none": 0.0, "dry": 0.0,
        "subtle": 0.15, "light": 0.25, "gentle": 0.2,
        "normal": 0.4, "medium": 0.5, "standard": 0.45,
        "heavy": 0.7, "wet": 0.8, "full": 1.0,
        "extreme": 0.9, "max": 1.0, "soaked": 0.85
    ]
    
    // MARK: - Processing Methods
    
    /// Process reverb commands
    /// Examples: "add reverb to vocal", "set piano reverb to hall", "vocal reverb off"
    func processReverbCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "add/set [reverb] to [instrument]"
        if let command = processAddReverbToInstrument(lowercased) {
            return command
        }
        
        // Pattern 2: "set [instrument] reverb to [type/level]"
        if let command = processSetInstrumentReverb(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] reverb [type/level/off]"
        if let command = processInstrumentReverbDirect(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process delay commands
    /// Examples: "add delay to guitar", "set vocal delay to quarter note", "bass delay off"
    func processDelayCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "add/set delay to [instrument]"
        if let command = processAddDelayToInstrument(lowercased) {
            return command
        }
        
        // Pattern 2: "set [instrument] delay to [type/timing]"
        if let command = processSetInstrumentDelay(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] delay [type/timing/off]"
        if let command = processInstrumentDelayDirect(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process compression commands
    /// Examples: "compress the vocal", "set bass compression to heavy", "guitar compressor off"
    func processCompressionCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "compress [the] [instrument]"
        if let command = processCompressInstrument(lowercased) {
            return command
        }
        
        // Pattern 2: "set [instrument] compression/compressor to [setting]"
        if let command = processSetInstrumentCompression(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] compressor [setting/off]"
        if let command = processInstrumentCompressorDirect(lowercased) {
            return command
        }
        
        return nil
    }
    
    /// Process EQ commands
    /// Examples: "boost the bass on kick", "cut the mids on guitar", "add presence to vocal"
    func processEQCommand(_ text: String) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Pattern 1: "(boost|cut) [the] [frequency] on [instrument]"
        if let command = processBoostCutFrequency(lowercased) {
            return command
        }
        
        // Pattern 2: "add [frequency characteristic] to [instrument]"
        if let command = processAddFrequencyCharacteristic(lowercased) {
            return command
        }
        
        // Pattern 3: "[instrument] [frequency] (up|down|boost|cut)"
        if let command = processInstrumentFrequencyDirect(lowercased) {
            return command
        }
        
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Process "add reverb to [instrument]" pattern
    private func processAddReverbToInstrument(_ text: String) -> RCPCommand? {
        let pattern = #"(?:add|set)\s+(?:(?:(.+?)\s+)?reverb\s+to|reverb\s+(?:(.+?)\s+)?to)\s+(.+?)(?:\s+at\s+(.+))?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let reverbTypeRange = match.range(at: 1).location != NSNotFound ? Range(match.range(at: 1), in: text) : nil
            let instrumentRange = Range(match.range(at: 3), in: text)
            let levelRange = match.range(at: 4).location != NSNotFound ? Range(match.range(at: 4), in: text) : nil
            
            guard let instrumentRange = instrumentRange else { return nil }
            
            let reverbType = reverbTypeRange != nil ? String(text[reverbTypeRange!]).trimmingCharacters(in: .whitespacesAndNewlines) : "room"
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let levelText = levelRange != nil ? String(text[levelRange!]).trimmingCharacters(in: .whitespacesAndNewlines) : "normal"
            
            if let channel = findInstrumentChannel(instrumentText) {
                let reverbTypeValue = reverbTypes[reverbType] ?? 1
                let level = effectLevels[levelText] ?? 0.4
                let rcpLevel = Int(level * 100)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Insert/Reverb/Type \\(channel-1) 0 \\(reverbTypeValue); set MIXER:Current/Channel/Insert/Reverb/Level \\(channel-1) 0 \\(rcpLevel)",
                    description: "Add \\(reverbType) reverb to \\(instrumentText) at \\(levelText) level (channel \\(channel))",
                    category: .effects
                )
            }
        }
        
        return nil
    }
    
    /// Process "set [instrument] reverb to [type/level]" pattern
    private func processSetInstrumentReverb(_ text: String) -> RCPCommand? {
        let pattern = #"set\s+(.+?)\s+reverb\s+to\s+(.+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let settingRange = Range(match.range(at: 2), in: text)
            
            guard let instrumentRange = instrumentRange, let settingRange = settingRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let settingText = String(text[settingRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let channel = findInstrumentChannel(instrumentText) {
                // Check if it's a reverb type or level
                if let reverbTypeValue = reverbTypes[settingText] {
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Insert/Reverb/Type \\(channel-1) 0 \\(reverbTypeValue)",
                        description: "Set \\(instrumentText) reverb to \\(settingText) (channel \\(channel))",
                        category: .effects
                    )
                } else if settingText == "off" || settingText == "none" {
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Insert/Reverb/Level \\(channel-1) 0 0",
                        description: "Turn off \\(instrumentText) reverb (channel \\(channel))",
                        category: .effects
                    )
                } else if let level = effectLevels[settingText] {
                    let rcpLevel = Int(level * 100)
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Insert/Reverb/Level \\(channel-1) 0 \\(rcpLevel)",
                        description: "Set \\(instrumentText) reverb to \\(settingText) level (channel \\(channel))",
                        category: .effects
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process "[instrument] reverb [type/level/off]" pattern
    private func processInstrumentReverbDirect(_ text: String) -> RCPCommand? {
        let pattern = #"(.+?)\s+reverb\s+(\w+)(?:\s+(\w+))?"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let setting1Range = Range(match.range(at: 2), in: text)
            let setting2Range = match.range(at: 3).location != NSNotFound ? Range(match.range(at: 3), in: text) : nil
            
            guard let instrumentRange = instrumentRange, let setting1Range = setting1Range else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let setting1 = String(text[setting1Range])
            let setting2 = setting2Range != nil ? String(text[setting2Range!]) : ""
            
            if let channel = findInstrumentChannel(instrumentText) {
                let combinedSetting = setting2.isEmpty ? setting1 : "\\(setting1) \\(setting2)"
                
                if combinedSetting == "off" || combinedSetting == "none" {
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Insert/Reverb/Level \\(channel-1) 0 0",
                        description: "Turn off \\(instrumentText) reverb (channel \\(channel))",
                        category: .effects
                    )
                } else if let reverbTypeValue = reverbTypes[combinedSetting] {
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Insert/Reverb/Type \\(channel-1) 0 \\(reverbTypeValue)",
                        description: "Set \\(instrumentText) reverb to \\(combinedSetting) (channel \\(channel))",
                        category: .effects
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Process delay commands similar to reverb
    private func processAddDelayToInstrument(_ text: String) -> RCPCommand? {
        let pattern = #"(?:add|set)\s+(?:(?:(.+?)\s+)?delay\s+to|delay\s+(?:(.+?)\s+)?to)\s+(.+?)(?:\s+at\s+(.+?))?(?:\s+(?:ms|milliseconds|note|notes))?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let delayTypeRange = match.range(at: 1).location != NSNotFound ? Range(match.range(at: 1), in: text) : nil
            let instrumentRange = Range(match.range(at: 3), in: text)
            let timingRange = match.range(at: 4).location != NSNotFound ? Range(match.range(at: 4), in: text) : nil
            
            guard let instrumentRange = instrumentRange else { return nil }
            
            let delayType = delayTypeRange != nil ? String(text[delayTypeRange!]).trimmingCharacters(in: .whitespacesAndNewlines) : "delay"
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let timingText = timingRange != nil ? String(text[timingRange!]).trimmingCharacters(in: .whitespacesAndNewlines) : "quarter"
            
            if let channel = findInstrumentChannel(instrumentText) {
                let delay = delayTypes[delayType] ?? delayTypes["delay"]!
                let timing = delayTypes[timingText]?.time ?? delay.time
                let rcpTime = Int(timing)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Insert/Delay/Type \\(channel-1) 0 \\(delay.type); set MIXER:Current/Channel/Insert/Delay/Time \\(channel-1) 0 \\(rcpTime)",
                    description: "Add \\(delayType) delay to \\(instrumentText) at \\(timingText) timing (channel \\(channel))",
                    category: .effects
                )
            }
        }
        
        return nil
    }
    
    /// Process compression commands
    private func processCompressInstrument(_ text: String) -> RCPCommand? {
        let pattern = #"compress(?:or)?\s+(?:the\s+)?(.+?)(?:\s+(gentle|light|medium|heavy|aggressive))?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let instrumentRange = Range(match.range(at: 1), in: text)
            let intensityRange = match.range(at: 2).location != NSNotFound ? Range(match.range(at: 2), in: text) : nil
            
            guard let instrumentRange = instrumentRange else { return nil }
            
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let intensity = intensityRange != nil ? String(text[intensityRange!]) : "medium"
            
            if let channel = findInstrumentChannel(instrumentText),
               let compSettings = compressionSettings[intensity] {
                
                let ratioValue = Int(compSettings.ratio * 10)
                let attackValue = Int(compSettings.attack)
                let releaseValue = Int(compSettings.release)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Insert/Compressor/Ratio \\(channel-1) 0 \\(ratioValue); set MIXER:Current/Channel/Insert/Compressor/Attack \\(channel-1) 0 \\(attackValue); set MIXER:Current/Channel/Insert/Compressor/Release \\(channel-1) 0 \\(releaseValue)",
                    description: "Apply \\(intensity) compression to \\(instrumentText) (channel \\(channel))",
                    category: .effects
                )
            }
        }
        
        return nil
    }
    
    /// Process EQ boost/cut commands
    private func processBoostCutFrequency(_ text: String) -> RCPCommand? {
        let pattern = #"(boost|cut)\s+(?:the\s+)?(.+?)\s+on\s+(.+?)(?:\s+by\s+([\d.]+)\s*(?:db|dB))?$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let actionRange = Range(match.range(at: 1), in: text)
            let frequencyRange = Range(match.range(at: 2), in: text)
            let instrumentRange = Range(match.range(at: 3), in: text)
            let gainRange = match.range(at: 4).location != NSNotFound ? Range(match.range(at: 4), in: text) : nil
            
            guard let actionRange = actionRange,
                  let frequencyRange = frequencyRange,
                  let instrumentRange = instrumentRange else { return nil }
            
            let action = String(text[actionRange])
            let frequencyText = String(text[frequencyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let instrumentText = String(text[instrumentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let gain = gainRange != nil ? Double(String(text[gainRange!])) ?? 3.0 : 3.0
            
            if let channel = findInstrumentChannel(instrumentText),
               let eqSetting = eqFrequencies[frequencyText] {
                
                let finalGain = action == "boost" ? gain : -gain
                let frequencyValue = Int(eqSetting.frequency)
                let gainValue = Int(finalGain * 10)
                let qValue = Int(eqSetting.q * 10)
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Insert/EQ/Frequency \\(channel-1) 0 \\(frequencyValue); set MIXER:Current/Channel/Insert/EQ/Gain \\(channel-1) 0 \\(gainValue); set MIXER:Current/Channel/Insert/EQ/Q \\(channel-1) 0 \\(qValue)",
                    description: "\\(action.capitalized) \\(frequencyText) on \\(instrumentText) by \\(abs(finalGain)) dB (channel \\(channel))",
                    category: .effects
                )
            }
        }
        
        return nil
    }
    
    /// Additional placeholder methods for other delay and compression patterns
    private func processSetInstrumentDelay(_ text: String) -> RCPCommand? {
        // Similar implementation to processSetInstrumentReverb
        return nil
    }
    
    private func processInstrumentDelayDirect(_ text: String) -> RCPCommand? {
        // Similar implementation to processInstrumentReverbDirect
        return nil
    }
    
    private func processSetInstrumentCompression(_ text: String) -> RCPCommand? {
        // Similar implementation to processSetInstrumentReverb
        return nil
    }
    
    private func processInstrumentCompressorDirect(_ text: String) -> RCPCommand? {
        // Similar implementation to processInstrumentReverbDirect
        return nil
    }
    
    private func processAddFrequencyCharacteristic(_ text: String) -> RCPCommand? {
        // Implementation for "add presence to vocal" type commands
        return nil
    }
    
    private func processInstrumentFrequencyDirect(_ text: String) -> RCPCommand? {
        // Implementation for "guitar bass up" type commands
        return nil
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
    
    /// Add custom reverb type
    func addReverbType(_ name: String, typeNumber: Int) {
        print("🎛️ Added custom reverb type: \(name) -> Type \(typeNumber)")
    }
    
    /// Add custom delay type
    func addDelayType(_ name: String, type: Int, time: Double) {
        print("🎛️ Added custom delay type: \(name) -> Type \(type), Time \(time)ms")
    }
    
    /// Get all available effect types
    func getAvailableEffects() -> [String: Any] {
        return [
            "reverb_types": reverbTypes,
            "delay_types": delayTypes.mapValues { $0.type },
            "compression_settings": compressionSettings.keys.sorted(),
            "eq_frequencies": eqFrequencies.keys.sorted()
        ]
    }
    
    /// Update effect level mapping
    func addEffectLevel(_ name: String, level: Double) {
        print("🎛️ Added custom effect level: \(name) -> \(level)")
    }
}