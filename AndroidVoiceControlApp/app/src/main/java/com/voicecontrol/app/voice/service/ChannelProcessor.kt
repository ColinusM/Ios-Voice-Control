package com.voicecontrol.app.voice.service

import android.util.Log
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.voice.model.VoiceCommand
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Channel Processor for Voice Control App
 * 
 * Direct port of iOS ChannelProcessor to Android with Kotlin
 * Handles execution of channel-specific audio mixer commands
 * 
 * Features:
 * - Channel state management (mute, solo, fader, gain, etc.)
 * - Parameter validation and conversion
 * - Command execution tracking and history
 * - Channel group operations
 * - Safety limits and validation
 * - Real-time state updates via StateFlow
 */
@Singleton
class ChannelProcessor @Inject constructor() {
    
    companion object {
        private const val TAG = "ChannelProcessor"
        
        // Channel limits
        private const val MAX_CHANNELS = 64
        private const val MIN_CHANNEL = 1
        
        // Parameter limits (in dB and percentages)
        private const val MIN_FADER_DB = -90f
        private const val MAX_FADER_DB = 10f
        private const val MIN_GAIN_DB = -20f
        private const val MAX_GAIN_DB = 60f
        private const val MIN_PAN_PERCENT = -100f
        private const val MAX_PAN_PERCENT = 100f
        
        // Default step sizes for increment/decrement operations
        private const val DEFAULT_FADER_STEP_DB = 3f
        private const val DEFAULT_GAIN_STEP_DB = 2f
        private const val DEFAULT_PAN_STEP_PERCENT = 10f
    }
    
    // Channel states storage
    private val _channelStates = MutableStateFlow<Map<Int, ChannelState>>(emptyMap())
    val channelStates: StateFlow<Map<Int, ChannelState>> = _channelStates.asStateFlow()
    
    // Execution statistics
    private val _executedCommandsCount = MutableStateFlow(0)
    val executedCommandsCount: StateFlow<Int> = _executedCommandsCount.asStateFlow()
    
    private val _failedCommandsCount = MutableStateFlow(0)
    val failedCommandsCount: StateFlow<Int> = _failedCommandsCount.asStateFlow()
    
    // Command execution results
    private val _lastExecutionResult = MutableStateFlow<ChannelExecutionResult?>(null)
    val lastExecutionResult: StateFlow<ChannelExecutionResult?> = _lastExecutionResult.asStateFlow()
    
    init {
        // Initialize default channel states
        initializeChannelStates()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎛️ ChannelProcessor initialized with $MAX_CHANNELS channels")
        }
    }
    
    /**
     * Channel State Model
     * Represents the current state of a single audio channel
     */
    @Serializable
    data class ChannelState(
        val channelNumber: Int,
        val isMuted: Boolean = false,
        val isSoloed: Boolean = false,
        val faderLevel: Float = 0f,    // dB value
        val gainLevel: Float = 0f,     // dB value  
        val panPosition: Float = 0f,   // -100 to +100 (left to right)
        val isPhantomPowerOn: Boolean = false,
        val isEqBypassed: Boolean = false,
        val isCompressorBypassed: Boolean = false,
        val lastUpdated: Long = System.currentTimeMillis()
    ) {
        
        /**
         * Get fader level as percentage (0-100%)
         * Converts from dB to percentage for UI display
         */
        val faderLevelPercent: Float
            get() = ((faderLevel - MIN_FADER_DB) / (MAX_FADER_DB - MIN_FADER_DB) * 100f).coerceIn(0f, 100f)
        
        /**
         * Get gain level with unit suffix
         */
        val gainLevelDisplay: String
            get() = "${if (gainLevel >= 0) "+" else ""}${String.format("%.1f", gainLevel)} dB"
        
        /**
         * Get fader level with unit suffix
         */
        val faderLevelDisplay: String
            get() = if (faderLevel <= -90f) "-∞ dB" else "${String.format("%.1f", faderLevel)} dB"
        
        /**
         * Get pan position display
         */
        val panPositionDisplay: String
            get() = when {
                panPosition < -5f -> "L${String.format("%.0f", kotlin.math.abs(panPosition))}"
                panPosition > 5f -> "R${String.format("%.0f", panPosition)}"
                else -> "C"
            }
        
        /**
         * Check if channel is in a "safe" state (unmuted, unsoloed)
         */
        val isSafe: Boolean
            get() = !isMuted && !isSoloed
        
        /**
         * Create updated copy of channel state
         */
        fun updated(): ChannelState = copy(lastUpdated = System.currentTimeMillis())
    }
    
    /**
     * Channel Execution Result
     * Represents the result of executing a channel command
     */
    @Serializable
    data class ChannelExecutionResult(
        val command: VoiceCommand.ChannelCommand,
        val success: Boolean,
        val previousState: ChannelState?,
        val newState: ChannelState?,
        val message: String,
        val executionTimeMs: Long,
        val timestamp: Long = System.currentTimeMillis()
    ) {
        
        val isStateChange: Boolean
            get() = previousState != newState
        
        val changeDescription: String
            get() = when {
                !success -> "Failed: $message"
                !isStateChange -> "No change: $message"
                else -> "Changed: ${previousState?.let { prev -> 
                    newState?.let { new -> 
                        describeStateChange(prev, new)
                    }
                } ?: message}"
            }
        
        private fun describeStateChange(prev: ChannelState, new: ChannelState): String {
            val changes = mutableListOf<String>()
            
            if (prev.isMuted != new.isMuted) {
                changes.add("Mute ${if (new.isMuted) "ON" else "OFF"}")
            }
            if (prev.isSoloed != new.isSoloed) {
                changes.add("Solo ${if (new.isSoloed) "ON" else "OFF"}")
            }
            if (prev.faderLevel != new.faderLevel) {
                changes.add("Fader ${prev.faderLevelDisplay} → ${new.faderLevelDisplay}")
            }
            if (prev.gainLevel != new.gainLevel) {
                changes.add("Gain ${prev.gainLevelDisplay} → ${new.gainLevelDisplay}")
            }
            if (prev.panPosition != new.panPosition) {
                changes.add("Pan ${prev.panPositionDisplay} → ${new.panPositionDisplay}")
            }
            if (prev.isPhantomPowerOn != new.isPhantomPowerOn) {
                changes.add("Phantom ${if (new.isPhantomPowerOn) "ON" else "OFF"}")
            }
            
            return changes.joinToString(", ").ifEmpty { "State updated" }
        }
    }
    
    /**
     * Execute a channel command
     * Equivalent to iOS executeChannelCommand method
     */
    suspend fun executeCommand(command: VoiceCommand.ChannelCommand): ChannelExecutionResult {
        val startTime = System.currentTimeMillis()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎯 Executing: Ch${command.channelNumber} ${command.operation.name}")
        }
        
        // Validate channel number
        if (command.channelNumber !in MIN_CHANNEL..MAX_CHANNELS) {
            val result = ChannelExecutionResult(
                command = command,
                success = false,
                previousState = null,
                newState = null,
                message = "Invalid channel number: ${command.channelNumber}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            _failedCommandsCount.value += 1
            _lastExecutionResult.value = result
            return result
        }
        
        // Get current channel state
        val currentStates = _channelStates.value
        val currentState = currentStates[command.channelNumber] ?: ChannelState(command.channelNumber)
        
        // Execute the specific operation
        val newState = try {
            executeChannelOperation(currentState, command)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error executing command: ${e.message}", e)
            }
            
            val result = ChannelExecutionResult(
                command = command,
                success = false,
                previousState = currentState,
                newState = null,
                message = "Execution error: ${e.message}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            _failedCommandsCount.value += 1
            _lastExecutionResult.value = result
            return result
        }
        
        // Update channel states
        val updatedStates = currentStates.toMutableMap()
        updatedStates[command.channelNumber] = newState
        _channelStates.value = updatedStates
        
        val result = ChannelExecutionResult(
            command = command,
            success = true,
            previousState = currentState,
            newState = newState,
            message = "Command executed successfully",
            executionTimeMs = System.currentTimeMillis() - startTime
        )
        
        _executedCommandsCount.value += 1
        _lastExecutionResult.value = result
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "✅ Ch${command.channelNumber}: ${result.changeDescription}")
        }
        
        return result
    }
    
    /**
     * Execute specific channel operation
     * Equivalent to iOS executeChannelOperation method
     */
    private fun executeChannelOperation(
        currentState: ChannelState,
        command: VoiceCommand.ChannelCommand
    ): ChannelState {
        
        return when (command.operation) {
            VoiceCommand.ChannelCommand.ChannelOperation.MUTE_ON -> {
                currentState.copy(isMuted = true).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.MUTE_OFF -> {
                currentState.copy(isMuted = false).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.SOLO_ON -> {
                currentState.copy(isSoloed = true).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.SOLO_OFF -> {
                currentState.copy(isSoloed = false).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_SET -> {
                val targetLevel = command.parameterValue?.coerceIn(MIN_FADER_DB, MAX_FADER_DB) ?: currentState.faderLevel
                currentState.copy(faderLevel = targetLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_INCREASE -> {
                val newLevel = (currentState.faderLevel + DEFAULT_FADER_STEP_DB).coerceIn(MIN_FADER_DB, MAX_FADER_DB)
                currentState.copy(faderLevel = newLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_DECREASE -> {
                val newLevel = (currentState.faderLevel - DEFAULT_FADER_STEP_DB).coerceIn(MIN_FADER_DB, MAX_FADER_DB)
                currentState.copy(faderLevel = newLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_SET -> {
                val targetLevel = command.parameterValue?.coerceIn(MIN_GAIN_DB, MAX_GAIN_DB) ?: currentState.gainLevel
                currentState.copy(gainLevel = targetLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_INCREASE -> {
                val newLevel = (currentState.gainLevel + DEFAULT_GAIN_STEP_DB).coerceIn(MIN_GAIN_DB, MAX_GAIN_DB)
                currentState.copy(gainLevel = newLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_DECREASE -> {
                val newLevel = (currentState.gainLevel - DEFAULT_GAIN_STEP_DB).coerceIn(MIN_GAIN_DB, MAX_GAIN_DB)
                currentState.copy(gainLevel = newLevel).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_SET -> {
                val targetPosition = command.parameterValue?.coerceIn(MIN_PAN_PERCENT, MAX_PAN_PERCENT) ?: currentState.panPosition
                currentState.copy(panPosition = targetPosition).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_LEFT -> {
                val newPosition = (currentState.panPosition - DEFAULT_PAN_STEP_PERCENT).coerceIn(MIN_PAN_PERCENT, MAX_PAN_PERCENT)
                currentState.copy(panPosition = newPosition).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_RIGHT -> {
                val newPosition = (currentState.panPosition + DEFAULT_PAN_STEP_PERCENT).coerceIn(MIN_PAN_PERCENT, MAX_PAN_PERCENT)
                currentState.copy(panPosition = newPosition).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_CENTER -> {
                currentState.copy(panPosition = 0f).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_ON -> {
                currentState.copy(isPhantomPowerOn = true).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_OFF -> {
                currentState.copy(isPhantomPowerOn = false).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.EQ_BYPASS -> {
                currentState.copy(isEqBypassed = !currentState.isEqBypassed).updated()
            }
            
            VoiceCommand.ChannelCommand.ChannelOperation.COMP_BYPASS -> {
                currentState.copy(isCompressorBypassed = !currentState.isCompressorBypassed).updated()
            }
        }
    }
    
    /**
     * Get channel state by number
     * Equivalent to iOS getChannelState method
     */
    fun getChannelState(channelNumber: Int): ChannelState? {
        return _channelStates.value[channelNumber]
    }
    
    /**
     * Get all channel states as a list
     * Equivalent to iOS getAllChannelStates method
     */
    fun getAllChannelStates(): List<ChannelState> {
        return _channelStates.value.values.sortedBy { it.channelNumber }
    }
    
    /**
     * Get channels by state (muted, soloed, etc.)
     */
    fun getChannelsByState(
        isMuted: Boolean? = null,
        isSoloed: Boolean? = null,
        isPhantomOn: Boolean? = null
    ): List<ChannelState> {
        return _channelStates.value.values.filter { channel ->
            (isMuted == null || channel.isMuted == isMuted) &&
            (isSoloed == null || channel.isSoloed == isSoloed) &&
            (isPhantomOn == null || channel.isPhantomPowerOn == isPhantomOn)
        }.sortedBy { it.channelNumber }
    }
    
    /**
     * Reset channel to default state
     * Equivalent to iOS resetChannel method
     */
    suspend fun resetChannel(channelNumber: Int): ChannelExecutionResult? {
        if (channelNumber !in MIN_CHANNEL..MAX_CHANNELS) return null
        
        val defaultState = ChannelState(channelNumber).updated()
        val currentStates = _channelStates.value.toMutableMap()
        val previousState = currentStates[channelNumber]
        
        currentStates[channelNumber] = defaultState
        _channelStates.value = currentStates
        
        val result = ChannelExecutionResult(
            command = VoiceCommand.ChannelCommand(
                originalText = "Reset channel $channelNumber",
                confidence = 1.0,
                channelNumber = channelNumber,
                operation = VoiceCommand.ChannelCommand.ChannelOperation.MUTE_OFF
            ),
            success = true,
            previousState = previousState,
            newState = defaultState,
            message = "Channel reset to defaults",
            executionTimeMs = 0
        )
        
        _lastExecutionResult.value = result
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Ch${channelNumber} reset to defaults")
        }
        
        return result
    }
    
    /**
     * Reset all channels to default state
     * Equivalent to iOS resetAllChannels method
     */
    suspend fun resetAllChannels(): Int {
        var resetCount = 0
        val newStates = mutableMapOf<Int, ChannelState>()
        
        for (channelNumber in MIN_CHANNEL..MAX_CHANNELS) {
            newStates[channelNumber] = ChannelState(channelNumber).updated()
            resetCount++
        }
        
        _channelStates.value = newStates
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 All $resetCount channels reset to defaults")
        }
        
        return resetCount
    }
    
    /**
     * Initialize default channel states
     */
    private fun initializeChannelStates() {
        val initialStates = mutableMapOf<Int, ChannelState>()
        
        for (channelNumber in MIN_CHANNEL..MAX_CHANNELS) {
            initialStates[channelNumber] = ChannelState(channelNumber)
        }
        
        _channelStates.value = initialStates
    }
    
    /**
     * Get processing statistics
     * Equivalent to iOS getProcessingStats method
     */
    fun getProcessingStats(): Map<String, Any> {
        val totalCommands = _executedCommandsCount.value + _failedCommandsCount.value
        val successRate = if (totalCommands > 0) {
            _executedCommandsCount.value.toDouble() / totalCommands.toDouble()
        } else {
            0.0
        }
        
        val mutedChannels = getChannelsByState(isMuted = true).size
        val soloedChannels = getChannelsByState(isSoloed = true).size
        val phantomChannels = getChannelsByState(isPhantomOn = true).size
        
        return mapOf(
            "totalChannels" to MAX_CHANNELS,
            "executedCommands" to _executedCommandsCount.value,
            "failedCommands" to _failedCommandsCount.value,
            "successRate" to successRate,
            "mutedChannels" to mutedChannels,
            "soloedChannels" to soloedChannels,
            "phantomChannels" to phantomChannels,
            "lastExecution" to (_lastExecutionResult.value?.timestamp ?: 0L)
        )
    }
    
    /**
     * Reset processing statistics
     */
    fun resetStats() {
        _executedCommandsCount.value = 0
        _failedCommandsCount.value = 0
        _lastExecutionResult.value = null
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📊 Processing statistics reset")
        }
    }
}