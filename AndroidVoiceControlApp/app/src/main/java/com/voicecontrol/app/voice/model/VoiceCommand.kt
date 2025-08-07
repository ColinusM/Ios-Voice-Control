package com.voicecontrol.app.voice.model

import kotlinx.serialization.Serializable

/**
 * Voice Command Model for Voice Control App
 * 
 * Direct port of iOS VoiceCommand to Kotlin sealed class
 * Represents parsed voice commands for audio mixer control
 * 
 * Features:
 * - Type-safe command representation with sealed classes
 * - Channel-specific audio commands (mute, solo, fader, etc.)
 * - Scene and preset management commands
 * - System-level mixer commands
 * - Parameter validation and normalization
 * - Command execution status tracking
 */
@Serializable
sealed class VoiceCommand {
    
    /**
     * Unique identifier for command tracking
     */
    abstract val id: String
    
    /**
     * Original transcribed text that generated this command
     */
    abstract val originalText: String
    
    /**
     * Confidence score from speech recognition (0.0 to 1.0)
     */
    abstract val confidence: Double
    
    /**
     * Timestamp when command was created (milliseconds since epoch)
     */
    abstract val timestamp: Long
    
    /**
     * Whether this command has valid parameters
     */
    abstract val isValid: Boolean
    
    /**
     * Channel Commands - Control individual audio channels
     * Equivalent to iOS ChannelCommand cases
     */
    @Serializable
    data class ChannelCommand(
        override val id: String = generateId(),
        override val originalText: String,
        override val confidence: Double,
        override val timestamp: Long = System.currentTimeMillis(),
        
        /**
         * Channel number (1-based, e.g., "Channel 1" = channelNumber: 1)
         */
        val channelNumber: Int,
        
        /**
         * Type of channel operation
         */
        val operation: ChannelOperation,
        
        /**
         * Optional parameter value (for fader levels, gain, etc.)
         * Range depends on operation type
         */
        val parameterValue: Float? = null,
        
        /**
         * Optional parameter unit (dB, %, etc.)
         */
        val parameterUnit: String? = null
        
    ) : VoiceCommand() {
        
        /**
         * Channel operation types
         * Equivalent to iOS ChannelOperation enum
         */
        @Serializable
        enum class ChannelOperation {
            MUTE_ON,           // "Channel 1 mute on"
            MUTE_OFF,          // "Channel 1 mute off" / "Channel 1 unmute"
            SOLO_ON,           // "Channel 1 solo on"
            SOLO_OFF,          // "Channel 1 solo off" / "Channel 1 unsolo"
            FADER_SET,         // "Channel 1 fader to 75" / "Set channel 1 fader to -10 dB"
            FADER_INCREASE,    // "Channel 1 fader up" / "Increase channel 1"
            FADER_DECREASE,    // "Channel 1 fader down" / "Decrease channel 1"
            GAIN_SET,          // "Channel 1 gain to +12 dB"
            GAIN_INCREASE,     // "Channel 1 gain up"
            GAIN_DECREASE,     // "Channel 1 gain down"
            PAN_SET,           // "Channel 1 pan center" / "Pan channel 1 left"
            PAN_LEFT,          // "Pan channel 1 left"
            PAN_RIGHT,         // "Pan channel 1 right"
            PAN_CENTER,        // "Pan channel 1 center"
            PHANTOM_ON,        // "Channel 1 phantom on"
            PHANTOM_OFF,       // "Channel 1 phantom off"
            EQ_BYPASS,         // "Channel 1 EQ bypass"
            COMP_BYPASS        // "Channel 1 compressor bypass"
        }
        
        /**
         * Get display text for the command
         */
        val displayText: String
            get() = buildString {
                append("Channel $channelNumber ")
                append(when (operation) {
                    ChannelOperation.MUTE_ON -> "Mute On"
                    ChannelOperation.MUTE_OFF -> "Mute Off"
                    ChannelOperation.SOLO_ON -> "Solo On"
                    ChannelOperation.SOLO_OFF -> "Solo Off"
                    ChannelOperation.FADER_SET -> "Fader ${parameterValue?.let { "$it${parameterUnit ?: ""}" } ?: "Set"}"
                    ChannelOperation.FADER_INCREASE -> "Fader Up"
                    ChannelOperation.FADER_DECREASE -> "Fader Down"
                    ChannelOperation.GAIN_SET -> "Gain ${parameterValue?.let { "$it${parameterUnit ?: ""}" } ?: "Set"}"
                    ChannelOperation.GAIN_INCREASE -> "Gain Up"
                    ChannelOperation.GAIN_DECREASE -> "Gain Down"
                    ChannelOperation.PAN_SET -> "Pan ${parameterValue?.let { "$it${parameterUnit ?: ""}" } ?: "Set"}"
                    ChannelOperation.PAN_LEFT -> "Pan Left"
                    ChannelOperation.PAN_RIGHT -> "Pan Right"
                    ChannelOperation.PAN_CENTER -> "Pan Center"
                    ChannelOperation.PHANTOM_ON -> "Phantom On"
                    ChannelOperation.PHANTOM_OFF -> "Phantom Off"
                    ChannelOperation.EQ_BYPASS -> "EQ Bypass"
                    ChannelOperation.COMP_BYPASS -> "Compressor Bypass"
                })
            }
        
        /**
         * Validate channel number and parameters
         */
        override val isValid: Boolean
            get() = channelNumber in 1..64 && // Typical mixer channel range
                    confidence > 0.3 &&
                    validateParameterValue()
        
        private fun validateParameterValue(): Boolean {
            return when (operation) {
                ChannelOperation.FADER_SET -> parameterValue?.let { it in -90f..10f } ?: true
                ChannelOperation.GAIN_SET -> parameterValue?.let { it in -20f..60f } ?: true
                ChannelOperation.PAN_SET -> parameterValue?.let { it in -100f..100f } ?: true
                else -> true // No parameter validation needed
            }
        }
    }
    
    /**
     * Scene Commands - Recall and store mixer scenes
     * Equivalent to iOS SceneCommand cases
     */
    @Serializable
    data class SceneCommand(
        override val id: String = generateId(),
        override val originalText: String,
        override val confidence: Double,
        override val timestamp: Long = System.currentTimeMillis(),
        
        /**
         * Scene number (typically 1-999)
         */
        val sceneNumber: Int,
        
        /**
         * Scene operation type
         */
        val operation: SceneOperation
        
    ) : VoiceCommand() {
        
        /**
         * Scene operation types
         * Equivalent to iOS SceneOperation enum
         */
        @Serializable
        enum class SceneOperation {
            RECALL,    // "Recall scene 5"
            STORE      // "Store scene 5"
        }
        
        val displayText: String
            get() = when (operation) {
                SceneOperation.RECALL -> "Recall Scene $sceneNumber"
                SceneOperation.STORE -> "Store Scene $sceneNumber"
            }
        
        override val isValid: Boolean
            get() = sceneNumber in 1..999 && confidence > 0.4 // Higher confidence for scene operations
    }
    
    /**
     * Global Commands - System-wide mixer operations
     * Equivalent to iOS GlobalCommand cases
     */
    @Serializable
    data class GlobalCommand(
        override val id: String = generateId(),
        override val originalText: String,
        override val confidence: Double,
        override val timestamp: Long = System.currentTimeMillis(),
        
        /**
         * Global operation type
         */
        val operation: GlobalOperation,
        
        /**
         * Optional parameter for operations that need values
         */
        val parameter: String? = null
        
    ) : VoiceCommand() {
        
        /**
         * Global operation types
         * Equivalent to iOS GlobalOperation enum
         */
        @Serializable
        enum class GlobalOperation {
            MASTER_MUTE_ON,      // "Master mute on"
            MASTER_MUTE_OFF,     // "Master mute off"
            ALL_MUTE_ON,         // "All mute on"
            ALL_MUTE_OFF,        // "All mute off"
            ALL_SOLO_CLEAR,      // "Clear all solo"
            TALKBACK_ON,         // "Talkback on"
            TALKBACK_OFF,        // "Talkback off"
            OSCILLATOR_ON,       // "Oscillator on"
            OSCILLATOR_OFF,      // "Oscillator off"
            RECORD_START,        // "Start recording"
            RECORD_STOP,         // "Stop recording"
            PLAYBACK_START,      // "Start playback"
            PLAYBACK_STOP        // "Stop playback"
        }
        
        val displayText: String
            get() = when (operation) {
                GlobalOperation.MASTER_MUTE_ON -> "Master Mute On"
                GlobalOperation.MASTER_MUTE_OFF -> "Master Mute Off"
                GlobalOperation.ALL_MUTE_ON -> "All Mute On"
                GlobalOperation.ALL_MUTE_OFF -> "All Mute Off"
                GlobalOperation.ALL_SOLO_CLEAR -> "Clear All Solo"
                GlobalOperation.TALKBACK_ON -> "Talkback On"
                GlobalOperation.TALKBACK_OFF -> "Talkback Off"
                GlobalOperation.OSCILLATOR_ON -> "Oscillator On"
                GlobalOperation.OSCILLATOR_OFF -> "Oscillator Off"
                GlobalOperation.RECORD_START -> "Start Recording"
                GlobalOperation.RECORD_STOP -> "Stop Recording"
                GlobalOperation.PLAYBACK_START -> "Start Playback"
                GlobalOperation.PLAYBACK_STOP -> "Stop Playback"
            }
        
        override val isValid: Boolean
            get() = confidence > 0.5 // Higher confidence for global operations
    }
    
    /**
     * Unknown Commands - Unparseable or unsupported commands
     * Equivalent to iOS UnknownCommand case
     */
    @Serializable
    data class UnknownCommand(
        override val id: String = generateId(),
        override val originalText: String,
        override val confidence: Double,
        override val timestamp: Long = System.currentTimeMillis(),
        
        /**
         * Reason why command couldn't be parsed
         */
        val reason: String = "Unrecognized command"
        
    ) : VoiceCommand() {
        
        val displayText: String
            get() = "Unknown: \"$originalText\""
        
        override val isValid: Boolean
            get() = false // Unknown commands are inherently invalid
    }
    
    /**
     * Get command priority for execution ordering
     * Higher values = higher priority
     */
    val priority: Int
        get() = when (this) {
            is GlobalCommand -> when (operation) {
                GlobalCommand.GlobalOperation.ALL_MUTE_OFF,
                GlobalCommand.GlobalOperation.ALL_SOLO_CLEAR -> 100 // Emergency commands
                else -> 80
            }
            is SceneCommand -> 70
            is ChannelCommand -> when (operation) {
                ChannelCommand.ChannelOperation.MUTE_OFF,
                ChannelCommand.ChannelOperation.SOLO_OFF -> 90 // Safety commands
                else -> 60
            }
            is UnknownCommand -> 0
        }
    
    /**
     * Check if command should be executed immediately
     */
    val isImmediate: Boolean
        get() = when (this) {
            is GlobalCommand -> operation in listOf(
                GlobalCommand.GlobalOperation.ALL_MUTE_OFF,
                GlobalCommand.GlobalOperation.ALL_SOLO_CLEAR,
                GlobalCommand.GlobalOperation.MASTER_MUTE_OFF
            )
            is ChannelCommand -> operation in listOf(
                ChannelCommand.ChannelOperation.MUTE_OFF,
                ChannelCommand.ChannelOperation.SOLO_OFF
            )
            else -> false
        }
    
    /**
     * Get estimated execution time in milliseconds
     */
    val estimatedExecutionTimeMs: Long
        get() = when (this) {
            is GlobalCommand -> 200L
            is SceneCommand -> 1000L // Scenes take longer
            is ChannelCommand -> 100L
            is UnknownCommand -> 0L
        }
    
    companion object {
        
        /**
         * Generate unique ID for commands
         */
        fun generateId(): String {
            return "cmd_${System.currentTimeMillis()}_${(Math.random() * 1000).toInt()}"
        }
        
        /**
         * Command confidence thresholds
         */
        const val MIN_CONFIDENCE_THRESHOLD = 0.3
        const val GOOD_CONFIDENCE_THRESHOLD = 0.6
        const val EXCELLENT_CONFIDENCE_THRESHOLD = 0.8
        
        /**
         * Channel number limits for validation
         */
        const val MIN_CHANNEL_NUMBER = 1
        const val MAX_CHANNEL_NUMBER = 64
        
        /**
         * Scene number limits for validation
         */
        const val MIN_SCENE_NUMBER = 1
        const val MAX_SCENE_NUMBER = 999
        
        /**
         * Parameter value ranges
         */
        const val MIN_FADER_VALUE = -90f
        const val MAX_FADER_VALUE = 10f
        const val MIN_GAIN_VALUE = -20f
        const val MAX_GAIN_VALUE = 60f
        const val MIN_PAN_VALUE = -100f
        const val MAX_PAN_VALUE = 100f
    }
}