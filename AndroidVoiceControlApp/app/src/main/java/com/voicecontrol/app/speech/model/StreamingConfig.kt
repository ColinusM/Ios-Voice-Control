package com.voicecontrol.app.speech.model

import kotlinx.serialization.Serializable

/**
 * Streaming Configuration Model for Voice Control App
 * 
 * Direct port of iOS StreamingConfig to Kotlin data class
 * Configures AssemblyAI real-time streaming parameters
 * 
 * Features:
 * - Language and locale settings
 * - Audio format configuration
 * - Transcription enhancement options
 * - Professional audio vocabulary boosting
 * - Serialization for settings persistence
 */
@Serializable
data class StreamingConfig(
    /**
     * Language code for transcription (ISO 639-1 format)
     * Default: "en" (English)
     * Equivalent to iOS languageCode property
     */
    val languageCode: String = "en",
    
    /**
     * Audio sample rate in Hz
     * AssemblyAI supports: 8000, 16000, 22050, 44100, 48000
     * Default: 16000 (recommended for voice)
     * Equivalent to iOS sampleRate property
     */
    val sampleRate: Int = 16000,
    
    /**
     * Enable automatic punctuation insertion
     * Default: true
     * Equivalent to iOS enablePunctuation property
     */
    val enablePunctuation: Boolean = true,
    
    /**
     * Enable text formatting (capitalization, etc.)
     * Default: true
     * Equivalent to iOS formatText property
     */
    val formatText: Boolean = true,
    
    /**
     * Enable profanity filtering
     * Default: false (for professional audio environment)
     * Equivalent to iOS filterProfanity property
     */
    val filterProfanity: Boolean = false,
    
    /**
     * Enable speaker diarization (identify different speakers)
     * Default: false (single user voice control)
     * Equivalent to iOS enableDiarization property
     */
    val enableDiarization: Boolean = false,
    
    /**
     * Dual channel audio support
     * Default: false (mono audio)
     * Equivalent to iOS dualChannel property
     */
    val dualChannel: Boolean = false,
    
    /**
     * Audio encoding format
     * Default: "pcm_s16le" (16-bit PCM)
     * Equivalent to iOS encoding property
     */
    val encoding: String = "pcm_s16le",
    
    /**
     * Word boost for professional audio terminology
     * Improves recognition of audio mixing terms
     * Equivalent to iOS wordBoost property
     */
    val wordBoost: List<String> = listOf(
        // Audio mixing terms
        "channel", "mute", "unmute", "solo", "unsolo",
        "fader", "gain", "EQ", "equalizer", "reverb", "delay",
        "compressor", "gate", "limiter", "monitor", "aux",
        "send", "return", "input", "output", "phantom",
        "preamp", "microphone", "mic", "speaker", "headphone",
        
        // Yamaha-specific terms
        "Yamaha", "console", "mixer", "CL5", "QL5", "TF5",
        "scene", "recall", "store", "DCA", "matrix", "bus",
        
        // Common voice control terms
        "set", "adjust", "increase", "decrease", "on", "off",
        "up", "down", "left", "right", "record", "play", "stop"
    ),
    
    /**
     * Confidence threshold for accepting transcription results
     * Range: 0.0 to 1.0
     * Default: 0.3 (moderate threshold)
     * Equivalent to iOS confidenceThreshold property
     */
    val confidenceThreshold: Double = 0.3,
    
    /**
     * Enable extra session information
     * Provides additional metadata and timing
     * Default: true
     * Equivalent to iOS enableExtraInfo property
     */
    val enableExtraInfo: Boolean = true,
    
    /**
     * Speech detection timeout in milliseconds
     * How long to wait for speech before timing out
     * Default: 5000ms (5 seconds)
     * Equivalent to iOS speechTimeoutMs property
     */
    val speechTimeoutMs: Long = 5000L,
    
    /**
     * Silence detection timeout in milliseconds
     * How long of silence before ending transcription
     * Default: 2000ms (2 seconds)
     * Equivalent to iOS silenceTimeoutMs property
     */
    val silenceTimeoutMs: Long = 2000L
) {
    
    /**
     * Validate configuration parameters
     * Equivalent to iOS isValid computed property
     */
    val isValid: Boolean
        get() = languageCode.isNotBlank() &&
                sampleRate in listOf(8000, 16000, 22050, 44100, 48000) &&
                confidenceThreshold in 0.0..1.0 &&
                speechTimeoutMs > 0 &&
                silenceTimeoutMs > 0
    
    /**
     * Get display name for language code
     * Equivalent to iOS languageDisplayName computed property
     */
    val languageDisplayName: String
        get() = when (languageCode) {
            "en" -> "English"
            "es" -> "Spanish"
            "fr" -> "French"
            "de" -> "German"
            "it" -> "Italian"
            "pt" -> "Portuguese"
            "ru" -> "Russian"
            "ja" -> "Japanese"
            "ko" -> "Korean"
            "zh" -> "Chinese"
            else -> languageCode.uppercase()
        }
    
    /**
     * Get formatted sample rate string
     * Equivalent to iOS sampleRateDisplayString computed property
     */
    val sampleRateDisplayString: String
        get() = "${sampleRate / 1000}kHz"
    
    /**
     * Create configuration optimized for voice commands
     * Fast recognition with audio terminology boost
     * Equivalent to iOS voiceCommand static method
     */
    fun forVoiceCommands(): StreamingConfig {
        return copy(
            enablePunctuation = true,
            formatText = true,
            confidenceThreshold = 0.2, // Lower threshold for quick commands
            speechTimeoutMs = 3000L,    // Shorter timeout for commands
            silenceTimeoutMs = 1000L    // Quick silence detection
        )
    }
    
    /**
     * Create configuration optimized for dictation
     * Better accuracy with longer timeout
     * Equivalent to iOS dictation static method
     */
    fun forDictation(): StreamingConfig {
        return copy(
            enablePunctuation = true,
            formatText = true,
            confidenceThreshold = 0.5,  // Higher threshold for accuracy
            speechTimeoutMs = 8000L,     // Longer timeout for speech
            silenceTimeoutMs = 3000L     // Longer silence tolerance
        )
    }
    
    /**
     * Create configuration for noisy environments
     * Higher confidence thresholds and shorter timeouts
     * Equivalent to iOS noisyEnvironment static method
     */
    fun forNoisyEnvironment(): StreamingConfig {
        return copy(
            confidenceThreshold = 0.6,  // Much higher threshold
            speechTimeoutMs = 4000L,     // Medium timeout
            silenceTimeoutMs = 1500L     // Quick silence detection
        )
    }
    
    companion object {
        
        /**
         * Default configuration for general voice control
         * Equivalent to iOS default static method
         */
        fun default(): StreamingConfig {
            return StreamingConfig()
        }
        
        /**
         * Configuration optimized for professional audio mixing
         * Enhanced with audio terminology and appropriate settings
         * Equivalent to iOS professionalAudio static method
         */
        fun professionalAudio(): StreamingConfig {
            return StreamingConfig(
                enablePunctuation = true,
                formatText = true,
                confidenceThreshold = 0.4,
                speechTimeoutMs = 4000L,
                silenceTimeoutMs = 1500L
            )
        }
        
        /**
         * Configuration for development and testing
         * More permissive settings with extra logging
         * Equivalent to iOS development static method
         */
        fun development(): StreamingConfig {
            return StreamingConfig(
                enablePunctuation = true,
                formatText = true,
                confidenceThreshold = 0.1,  // Very low threshold for testing
                speechTimeoutMs = 10000L,    // Long timeout for debugging
                silenceTimeoutMs = 3000L,
                enableExtraInfo = true
            )
        }
        
        /**
         * Supported language codes for AssemblyAI
         * Equivalent to iOS supportedLanguages static property
         */
        val supportedLanguages = listOf(
            "en", // English
            "es", // Spanish  
            "fr", // French
            "de", // German
            "it", // Italian
            "pt", // Portuguese
            "ru", // Russian
            "ja", // Japanese
            "ko", // Korean
            "zh"  // Chinese
        )
        
        /**
         * Supported sample rates for AssemblyAI
         * Equivalent to iOS supportedSampleRates static property
         */
        val supportedSampleRates = listOf(8000, 16000, 22050, 44100, 48000)
        
        /**
         * Professional audio vocabulary terms
         * Equivalent to iOS professionalAudioTerms static property
         */
        val professionalAudioTerms = listOf(
            "channel", "mute", "unmute", "solo", "unsolo", "fader", "gain",
            "EQ", "equalizer", "reverb", "delay", "compressor", "gate",
            "limiter", "monitor", "aux", "send", "return", "input", "output",
            "phantom", "preamp", "microphone", "mic", "speaker", "headphone",
            "Yamaha", "console", "mixer", "scene", "recall", "store",
            "DCA", "matrix", "bus", "set", "adjust", "increase", "decrease",
            "on", "off", "up", "down"
        )
    }
}