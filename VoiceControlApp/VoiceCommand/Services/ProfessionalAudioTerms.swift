import Foundation

/// Professional audio terminology database for voice command recognition
/// Ported from Python engine with comprehensive terminology mappings
class ProfessionalAudioTerms {
    
    // MARK: - Number Word Mappings
    
    /// Maps written numbers to integers
    static let numberWords: [String: Int] = [
        // Basic numbers
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
        
        // Tens
        "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90,
        
        // Common audio numbers
        "twenty-one": 21, "twenty-two": 22, "twenty-three": 23, "twenty-four": 24,
        "twenty-five": 25, "twenty-six": 26, "twenty-seven": 27, "twenty-eight": 28,
        "twenty-nine": 29, "thirty-one": 31, "thirty-two": 32
    ]
    
    // MARK: - Instrument Aliases
    
    /// Maps instrument names to their common aliases and variations
    static let instrumentAliases: [String: [String]] = [
        "kick": ["kick drum", "bass drum", "bd", "kick", "kik"],
        "snare": ["snare drum", "snare", "sd", "snr"],
        "hihat": ["hi-hat", "hi hat", "hh", "hihat", "high hat"],
        "ride": ["ride cymbal", "ride", "rd"],
        "crash": ["crash cymbal", "crash", "cr"],
        "tom1": ["rack tom", "tom 1", "tom one", "high tom"],
        "tom2": ["floor tom", "tom 2", "tom two", "low tom"],
        "bass": ["bass guitar", "bass", "bg", "electric bass"],
        "guitar": ["electric guitar", "guitar", "gtr", "eg"],
        "acoustic": ["acoustic guitar", "acoustic", "ag", "steel string"],
        "piano": ["piano", "keys", "keyboard", "pno"],
        "vocal": ["lead vocal", "vocal", "vox", "lead vox", "singer"],
        "bgv": ["background vocal", "backing vocal", "bgv", "bv", "harmony"],
        "sax": ["saxophone", "sax", "tenor sax", "alto sax"],
        "trumpet": ["trumpet", "tpt", "horn"],
        "violin": ["violin", "vln", "fiddle"],
        "cello": ["cello", "vc", "violoncello"],
        "drums": ["drum kit", "drums", "kit", "percussion"]
    ]
    
    // MARK: - Pan Position Mappings
    
    /// Maps pan terminology to pan values (center = 0, left = -63, right = +63)
    static let panPositions: [String: Int] = [
        // Center positions
        "center": 0, "centre": 0, "middle": 0, "centered": 0,
        
        // Left positions
        "left": -32, "hard left": -63, "full left": -63, "far left": -63,
        "slight left": -16, "little left": -16, "bit left": -16,
        
        // Right positions  
        "right": 32, "hard right": 63, "full right": 63, "far right": 63,
        "slight right": 16, "little right": 16, "bit right": 16,
        
        // Numeric references
        "ten left": -25, "ten right": 25,
        "twenty left": -40, "twenty right": 40,
        "thirty left": -50, "thirty right": 50
    ]
    
    // MARK: - dB Level Keywords
    
    /// Maps audio level terminology to dB values (in 100ths for RCP)
    static let dbKeywords: [String: Int] = [
        // Standard levels
        "unity": 0, "zero": 0, "nominal": 0,
        "hot": 300, "loud": 200, "up": 100,
        "down": -100, "low": -200, "quiet": -300,
        
        // Extreme levels
        "kill": -32768, "off": -32768, "mute": -32768,
        "max": 1000, "maximum": 1000, "full": 1000,
        
        // Professional references
        "line": 0, "mic": -2000, "instrument": -1000,
        "headroom": -600, "nominal": -1800,
        
        // Common adjustments
        "touch": 50, "bit": 100, "little": 100,
        "much": 300, "lot": 500, "way": 700
    ]
    
    // MARK: - Effects Terminology
    
    /// Maps effects types and parameters
    static let effectsTerms: [String: [String: Any]] = [
        "reverb": [
            "types": ["hall", "room", "plate", "spring", "chamber", "cathedral"],
            "parameters": ["wet": 50, "dry": 0, "size": 50, "decay": 50, "predelay": 20]
        ],
        "delay": [
            "types": ["echo", "delay", "slap", "doubling", "chorus"],
            "parameters": ["time": 250, "feedback": 30, "wet": 25, "tap": 120]
        ],
        "compression": [
            "types": ["compress", "limit", "gate", "expander"],
            "parameters": ["ratio": 4, "attack": 10, "release": 100, "threshold": -20]
        ],
        "eq": [
            "bands": ["low", "mid", "high", "bass", "treble", "presence"],
            "types": ["cut", "boost", "sweep", "shelving", "bell", "notch"]
        ]
    ]
    
    // MARK: - Professional Slang
    
    /// Maps professional audio slang to standard terminology
    static let professionalSlang: [String: String] = [
        // Level control slang
        "bring up": "increase", "bring down": "decrease", "push": "increase",
        "pull": "decrease", "lift": "increase", "drop": "decrease",
        "bump": "increase slightly", "notch": "decrease slightly",
        
        // Mute/Solo slang
        "kill": "mute", "cut": "mute", "solo": "solo", "pfl": "solo",
        "isolate": "solo", "alone": "solo",
        
        // Effects slang
        "verb": "reverb", "comp": "compression", "gate": "gate",
        "fx": "effects", "send": "auxiliary", "aux": "auxiliary",
        
        // EQ slang
        "bass": "low frequency", "treble": "high frequency",
        "mid": "midrange", "presence": "upper midrange",
        "air": "very high frequency", "mud": "low midrange",
        
        // Mixing slang
        "in the mix": "audible", "buried": "too quiet", "sitting": "well balanced",
        "fighting": "conflicting", "glue": "cohesion", "pocket": "timing"
    ]
    
    // MARK: - Frequency Bands
    
    /// Maps frequency terminology to Hz ranges
    static let frequencyBands: [String: (low: Int, high: Int)] = [
        "sub": (20, 60),
        "bass": (60, 250),
        "low": (60, 250),
        "low-mid": (250, 500),
        "mid": (500, 2000),
        "upper-mid": (2000, 4000),
        "presence": (4000, 8000),
        "high": (8000, 16000),
        "air": (16000, 20000),
        "treble": (8000, 20000)
    ]
    
    // MARK: - Monitor Terminology
    
    /// Maps monitor/wedge terminology for live sound
    static let monitorTerms: [String: String] = [
        "wedge": "monitor", "monitor": "monitor", "foldback": "monitor",
        "iem": "in-ear monitor", "ears": "in-ear monitor",
        "mix": "monitor mix", "send": "monitor send",
        "more me": "increase monitor level", "less me": "decrease monitor level",
        "can you give me": "increase", "take out": "decrease"
    ]
    
    // MARK: - Scene and Snapshot Terms
    
    /// Maps scene recall terminology
    static let sceneTerms: [String: String] = [
        "scene": "scene", "snapshot": "scene", "preset": "scene",
        "recall": "load", "load": "load", "call": "load",
        "store": "save", "save": "save", "capture": "save"
    ]
    
    // MARK: - Utility Methods
    
    /// Converts number words to integers
    /// - Parameter text: Text containing number words
    /// - Returns: Integer value or nil if not found
    static func parseNumber(from text: String) -> Int? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try direct number word lookup
        if let number = numberWords[lowercased] {
            return number
        }
        
        // Try parsing as digit
        if let number = Int(lowercased) {
            return number
        }
        
        // Try compound numbers (e.g., "twenty five")
        let words = lowercased.split(separator: " ")
        if words.count == 2 {
            let first = String(words[0])
            let second = String(words[1])
            
            if let tens = numberWords[first], let ones = numberWords[second] {
                return tens + ones
            }
        }
        
        return nil
    }
    
    /// Converts dB terminology to RCP format values
    /// - Parameter text: Text containing dB reference
    /// - Returns: RCP dB value (in 100ths) or nil if not found
    static func parseDBLevel(from text: String) -> Int? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct keyword lookup
        if let dbValue = dbKeywords[lowercased] {
            return dbValue
        }
        
        // Parse numeric dB values
        let dbPattern = #"([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#
        if let regex = try? NSRegularExpression(pattern: dbPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let numberRange = Range(match.range(at: 1), in: text)
            if let numberRange = numberRange,
               let dbValue = Double(String(text[numberRange])) {
                // Clamp to safe range and convert to RCP format
                let clampedDB = max(-60.0, min(10.0, dbValue))
                return Int(clampedDB * 100)
            }
        }
        
        return nil
    }
    
    /// Finds instrument aliases for a given instrument name
    /// - Parameter instrumentName: Name to search for
    /// - Returns: Array of matching aliases
    static func findInstrumentAliases(for instrumentName: String) -> [String] {
        let lowercased = instrumentName.lowercased()
        
        for (key, aliases) in instrumentAliases {
            if aliases.contains(where: { $0.lowercased() == lowercased }) {
                return aliases
            }
        }
        
        return [instrumentName] // Return original if no aliases found
    }
    
    /// Converts pan terminology to RCP pan value
    /// - Parameter text: Text containing pan reference
    /// - Returns: Pan value (-63 to +63) or nil if not found
    static func parsePanPosition(from text: String) -> Int? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct position lookup
        if let panValue = panPositions[lowercased] {
            return panValue
        }
        
        // Parse percentage-based pan (e.g., "50% left")
        let percentPattern = #"(\d+)%?\s*(left|right)"#
        if let regex = try? NSRegularExpression(pattern: percentPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let percentRange = Range(match.range(at: 1), in: text)
            let directionRange = Range(match.range(at: 2), in: text)
            
            if let percentRange = percentRange, let directionRange = directionRange,
               let percent = Int(String(text[percentRange])) {
                
                let direction = String(text[directionRange])
                let panValue = min(63, (percent * 63) / 100)
                return direction == "left" ? -panValue : panValue
            }
        }
        
        return nil
    }
    
    /// Expands professional slang to standard terminology
    /// - Parameter text: Text containing slang
    /// - Returns: Expanded text with standard terminology
    static func expandSlang(in text: String) -> String {
        var expandedText = text.lowercased()
        
        for (slang, standard) in professionalSlang {
            expandedText = expandedText.replacingOccurrences(of: slang, with: standard)
        }
        
        return expandedText
    }
    
    /// Validates if a frequency term is recognized
    /// - Parameter term: Frequency term to validate
    /// - Returns: True if recognized, false otherwise
    static func isValidFrequencyTerm(_ term: String) -> Bool {
        let lowercased = term.lowercased()
        return frequencyBands.keys.contains { $0.lowercased() == lowercased }
    }
    
    /// Gets frequency band range for a term
    /// - Parameter term: Frequency term
    /// - Returns: Frequency range tuple or nil if not found
    static func getFrequencyRange(for term: String) -> (low: Int, high: Int)? {
        let lowercased = term.lowercased()
        return frequencyBands[lowercased]
    }
}

// MARK: - Extensions for String Processing

extension String {
    /// Returns true if the string contains any professional audio terminology
    var containsAudioTerminology: Bool {
        let lowercased = self.lowercased()
        
        // Check for instrument names
        for aliases in ProfessionalAudioTerms.instrumentAliases.values {
            if aliases.contains(where: { lowercased.contains($0.lowercased()) }) {
                return true
            }
        }
        
        // Check for professional slang
        for slang in ProfessionalAudioTerms.professionalSlang.keys {
            if lowercased.contains(slang.lowercased()) {
                return true
            }
        }
        
        // Check for effects terms
        for effectType in ProfessionalAudioTerms.effectsTerms.keys {
            if lowercased.contains(effectType.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    /// Extracts all potential instrument names from the string
    var extractedInstruments: [String] {
        let lowercased = self.lowercased()
        var instruments: [String] = []
        
        for (instrument, aliases) in ProfessionalAudioTerms.instrumentAliases {
            for alias in aliases {
                if lowercased.contains(alias.lowercased()) {
                    instruments.append(instrument)
                    break
                }
            }
        }
        
        return instruments
    }
}