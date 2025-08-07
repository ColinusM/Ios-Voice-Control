package com.voicecontrol.app.network.model

import kotlinx.serialization.Serializable

/**
 * RCP Command Model for Voice Control App
 * 
 * Direct port of iOS RCPCommand to Kotlin data class
 * Represents Yamaha Remote Control Protocol commands
 * 
 * Features:
 * - Yamaha RCP command string formatting
 * - Parameter validation and encoding
 * - Command categorization and metadata
 * - Serialization for logging and debugging
 * - Command builder pattern for common operations
 */
@Serializable
data class RCPCommand(
    /**
     * Raw RCP command string to send to mixer
     * Example: "set MIXER:Current/InCh/Fader/Level 00 750"
     */
    val commandString: String,
    
    /**
     * Command type for categorization
     */
    val type: CommandType = CommandType.UNKNOWN,
    
    /**
     * Optional description for logging/debugging
     */
    val description: String? = null,
    
    /**
     * Expected response type
     */
    val expectedResponse: ResponseType = ResponseType.ACKNOWLEDGMENT,
    
    /**
     * Command priority for execution ordering
     */
    val priority: Int = 50,
    
    /**
     * Timestamp when command was created
     */
    val timestamp: Long = System.currentTimeMillis()
) {
    
    /**
     * RCP Command Types
     * Equivalent to iOS CommandType enum
     */
    @Serializable
    enum class CommandType {
        GET,         // Query parameter value
        SET,         // Set parameter value
        INCREMENT,   // Increment parameter
        DECREMENT,   // Decrement parameter
        SUBSCRIBE,   // Subscribe to parameter changes
        UNSUBSCRIBE, // Unsubscribe from parameter changes
        UNKNOWN      // Unknown or custom command
    }
    
    /**
     * Expected response types from mixer
     * Equivalent to iOS ResponseType enum
     */
    @Serializable
    enum class ResponseType {
        ACKNOWLEDGMENT,  // Simple OK/ERROR response
        VALUE,          // Parameter value response
        NOTIFICATION,   // Async notification
        NONE            // No response expected
    }
    
    /**
     * Check if command is valid RCP format
     * Equivalent to iOS isValid computed property
     */
    val isValid: Boolean
        get() = commandString.isNotBlank() && 
                (commandString.startsWith("get ") || 
                 commandString.startsWith("set ") || 
                 commandString.startsWith("inc ") || 
                 commandString.startsWith("dec ") ||
                 commandString.startsWith("sub ") ||
                 commandString.startsWith("unsub "))
    
    /**
     * Extract command verb (get, set, etc.)
     * Equivalent to iOS verb computed property
     */
    val verb: String
        get() = commandString.split(" ").firstOrNull() ?: ""
    
    /**
     * Extract parameter path from command
     * Equivalent to iOS parameterPath computed property
     */
    val parameterPath: String
        get() = commandString.split(" ").drop(1).firstOrNull() ?: ""
    
    /**
     * Extract parameter arguments
     * Equivalent to iOS arguments computed property
     */
    val arguments: List<String>
        get() = commandString.split(" ").drop(2)
    
    /**
     * Get display name for UI
     * Equivalent to iOS displayName computed property
     */
    val displayName: String
        get() = description ?: when (type) {
            CommandType.GET -> "Query ${getParameterDisplayName()}"
            CommandType.SET -> "Set ${getParameterDisplayName()}"
            CommandType.INCREMENT -> "Increase ${getParameterDisplayName()}"
            CommandType.DECREMENT -> "Decrease ${getParameterDisplayName()}"
            CommandType.SUBSCRIBE -> "Monitor ${getParameterDisplayName()}"
            CommandType.UNSUBSCRIBE -> "Stop monitoring ${getParameterDisplayName()}"
            CommandType.UNKNOWN -> "Custom Command"
        }
    
    /**
     * Extract friendly parameter name from path
     */
    private fun getParameterDisplayName(): String {
        val path = parameterPath
        return when {
            path.contains("Fader/Level") -> "Fader Level"
            path.contains("Head Amp/Gain") -> "Input Gain"
            path.contains("ToMix/On") -> "Mute Status"
            path.contains("ToMix/Solo") -> "Solo Status"
            path.contains("+48V") -> "Phantom Power"
            path.contains("Scene/Recall") -> "Scene Recall"
            path.contains("Scene/Store") -> "Scene Store"
            path.contains("AllMute") -> "All Mute"
            else -> path.split("/").lastOrNull() ?: "Parameter"
        }
    }
    
    companion object {
        
        /**
         * Create RCP command with automatic type detection
         * Equivalent to iOS create static method
         */
        fun create(commandString: String, description: String? = null): RCPCommand {
            val type = when {
                commandString.startsWith("get ") -> CommandType.GET
                commandString.startsWith("set ") -> CommandType.SET
                commandString.startsWith("inc ") -> CommandType.INCREMENT
                commandString.startsWith("dec ") -> CommandType.DECREMENT
                commandString.startsWith("sub ") -> CommandType.SUBSCRIBE
                commandString.startsWith("unsub ") -> CommandType.UNSUBSCRIBE
                else -> CommandType.UNKNOWN
            }
            
            val priority = when (type) {
                CommandType.SET -> if (commandString.contains("AllMute") || 
                                       commandString.contains("ToMix/On")) 90 else 70
                CommandType.GET -> 50
                CommandType.INCREMENT, CommandType.DECREMENT -> 60
                CommandType.SUBSCRIBE, CommandType.UNSUBSCRIBE -> 40
                CommandType.UNKNOWN -> 30
            }
            
            val expectedResponse = when (type) {
                CommandType.GET -> ResponseType.VALUE
                CommandType.SET, CommandType.INCREMENT, CommandType.DECREMENT -> ResponseType.ACKNOWLEDGMENT
                CommandType.SUBSCRIBE -> ResponseType.NOTIFICATION
                CommandType.UNSUBSCRIBE -> ResponseType.ACKNOWLEDGMENT
                CommandType.UNKNOWN -> ResponseType.NONE
            }
            
            return RCPCommand(
                commandString = commandString.trim(),
                type = type,
                description = description,
                expectedResponse = expectedResponse,
                priority = priority
            )
        }
        
        /**
         * Create GET command for parameter
         * Equivalent to iOS get static method
         */
        fun get(parameterPath: String, index: String? = null): RCPCommand {
            val command = if (index != null) {
                "get $parameterPath $index"
            } else {
                "get $parameterPath"
            }
            return create(command, "Query $parameterPath")
        }
        
        /**
         * Create SET command for parameter
         * Equivalent to iOS set static method
         */
        fun set(parameterPath: String, value: String, index: String? = null): RCPCommand {
            val command = if (index != null) {
                "set $parameterPath $index $value"
            } else {
                "set $parameterPath $value"
            }
            return create(command, "Set $parameterPath to $value")
        }
        
        /**
         * Channel Commands - Common mixer operations
         */
        
        /**
         * Mute/unmute channel
         */
        fun muteChannel(channelNumber: Int, muted: Boolean): RCPCommand {
            val index = String.format("%02d", channelNumber - 1)
            val value = if (muted) "0" else "1" // RCP: 0=muted, 1=unmuted
            return set("MIXER:Current/InCh/ToMix/On", value, index)
        }
        
        /**
         * Solo/unsolo channel
         */
        fun soloChannel(channelNumber: Int, soloed: Boolean): RCPCommand {
            val index = String.format("%02d", channelNumber - 1)
            val value = if (soloed) "1" else "0"
            return set("MIXER:Current/InCh/ToMix/Solo", value, index)
        }
        
        /**
         * Set channel fader level
         * @param channelNumber Channel number (1-based)
         * @param levelDb Fader level in dB (-90 to +10)
         */
        fun setChannelFader(channelNumber: Int, levelDb: Float): RCPCommand {
            val index = String.format("%02d", channelNumber - 1)
            // Convert dB to RCP level (0-1000, where 1000 = +10dB, 0 = -90dB)
            val rcpLevel = ((levelDb + 90) / 100 * 1000).toInt().coerceIn(0, 1000)
            return set("MIXER:Current/InCh/Fader/Level", rcpLevel.toString(), index)
        }
        
        /**
         * Set channel input gain
         * @param channelNumber Channel number (1-based)
         * @param gainDb Gain level in dB (-20 to +60)
         */
        fun setChannelGain(channelNumber: Int, gainDb: Float): RCPCommand {
            val index = String.format("%02d", channelNumber - 1)
            // Convert dB to RCP gain (0-480, where 240 = 0dB)
            val rcpGain = ((gainDb + 20) / 80 * 480).toInt().coerceIn(0, 480)
            return set("MIXER:Current/InCh/Head Amp/Gain", rcpGain.toString(), index)
        }
        
        /**
         * Set phantom power on/off
         */
        fun setPhantomPower(channelNumber: Int, enabled: Boolean): RCPCommand {
            val index = String.format("%02d", channelNumber - 1)
            val value = if (enabled) "1" else "0"
            return set("MIXER:Current/InCh/Head Amp/+48V", value, index)
        }
        
        /**
         * Scene Commands
         */
        
        /**
         * Recall scene
         */
        fun recallScene(sceneNumber: Int): RCPCommand {
            val index = String.format("%03d", sceneNumber - 1)
            return set("MIXER:Current/Scene/Recall", index)
        }
        
        /**
         * Store current settings to scene
         */
        fun storeScene(sceneNumber: Int): RCPCommand {
            val index = String.format("%03d", sceneNumber - 1)
            return set("MIXER:Current/Scene/Store", index)
        }
        
        /**
         * Global Commands
         */
        
        /**
         * Master mute on/off
         */
        fun setMasterMute(muted: Boolean): RCPCommand {
            val value = if (muted) "0" else "1"
            return set("MIXER:Current/StCh/ToMix/On", value, "00")
        }
        
        /**
         * All channels mute on/off
         */
        fun setAllMute(muted: Boolean): RCPCommand {
            val value = if (muted) "On" else "Off"
            return set("MIXER:Current/AllMute", value)
        }
        
        /**
         * Clear all solo
         */
        fun clearAllSolo(): RCPCommand {
            return set("MIXER:Current/AllSoloClear", "1")
        }
        
        /**
         * Common Query Commands
         */
        
        /**
         * Get mixer model information
         */
        fun getMixerInfo(): RCPCommand {
            return get("Config/ModelName")
        }
        
        /**
         * Get current scene number
         */
        fun getCurrentScene(): RCPCommand {
            return get("MIXER:Current/Scene/Current")
        }
        
        /**
         * Get channel count
         */
        fun getChannelCount(): RCPCommand {
            return get("Config/InChNum")
        }
        
        /**
         * Validation helpers
         */
        
        /**
         * Validate channel number range
         */
        fun isValidChannelNumber(channelNumber: Int, maxChannels: Int = 64): Boolean {
            return channelNumber in 1..maxChannels
        }
        
        /**
         * Validate scene number range
         */
        fun isValidSceneNumber(sceneNumber: Int, maxScenes: Int = 300): Boolean {
            return sceneNumber in 1..maxScenes
        }
        
        /**
         * Validate fader level range
         */
        fun isValidFaderLevel(levelDb: Float): Boolean {
            return levelDb in -90f..10f
        }
        
        /**
         * Validate gain level range
         */
        fun isValidGainLevel(gainDb: Float): Boolean {
            return gainDb in -20f..60f
        }
    }
}