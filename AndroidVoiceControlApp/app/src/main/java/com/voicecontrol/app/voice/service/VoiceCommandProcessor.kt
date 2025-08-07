package com.voicecontrol.app.voice.service

import com.voicecontrol.app.utils.VLogger
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.voice.model.VoiceCommand
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.regex.Pattern
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Voice Command Processor for Voice Control App
 * 
 * Direct port of iOS VoiceCommandProcessor to Android with Kotlin
 * Parses natural language transcriptions into structured voice commands
 * 
 * Features:
 * - Natural language processing for audio mixing commands
 * - Channel-specific command parsing (mute, solo, fader, gain, etc.)
 * - Scene and preset management commands
 * - Global mixer operation commands
 * - Parameter extraction with units (dB, %, etc.)
 * - Command validation and confidence scoring
 * - Extensible pattern matching system
 */
@Singleton
class VoiceCommandProcessor @Inject constructor() {
    
    companion object {
        private const val TAG = "VoiceCommandProcessor"
        
        // Base confidence threshold for accepting commands
        private const val MIN_BASE_CONFIDENCE = 0.3
        
        // Confidence boost for exact pattern matches
        private const val EXACT_MATCH_BOOST = 0.2
        
        // Confidence penalty for ambiguous matches
        private const val AMBIGUOUS_PENALTY = 0.1
    }
    
    // Processing statistics
    private val _processedCommandsCount = MutableStateFlow(0)
    val processedCommandsCount: StateFlow<Int> = _processedCommandsCount.asStateFlow()
    
    private val _successfulCommandsCount = MutableStateFlow(0)
    val successfulCommandsCount: StateFlow<Int> = _successfulCommandsCount.asStateFlow()
    
    // Regex patterns for command parsing
    private val channelPatterns = ChannelPatterns()
    private val scenePatterns = ScenePatterns()
    private val globalPatterns = GlobalPatterns()
    
    init {
        VLogger.d(TAG, "🎙️ VoiceCommandProcessor initialized")
    }
    
    /**
     * Process transcribed text into voice command
     * Equivalent to iOS processTranscription method
     */
    fun processTranscription(
        text: String, 
        confidence: Double,
        originalConfidence: Double = confidence
    ): VoiceCommand {
        
        _processedCommandsCount.value += 1
        
        VLogger.d(TAG, "🎯 Processing: \"$text\" (confidence: ${"%.3f".format(confidence)})", 
            mapOf("text" to text, "confidence" to "%.3f".format(confidence)))
        
        // Normalize input text
        val normalizedText = normalizeText(text)
        
        // Try parsing different command types in priority order
        val command = tryParseChannelCommand(normalizedText, confidence, text) ?:
                     tryParseSceneCommand(normalizedText, confidence, text) ?:
                     tryParseGlobalCommand(normalizedText, confidence, text) ?:
                     VoiceCommand.UnknownCommand(
                         originalText = text,
                         confidence = confidence,
                         reason = "No matching command pattern found"
                     )
        
        // Update success statistics
        if (command.isValid) {
            _successfulCommandsCount.value += 1
        }
        
        VLogger.d(TAG, "✅ Parsed: ${command.javaClass.simpleName} - ${getCommandSummary(command)}", 
            mapOf("commandType" to command.javaClass.simpleName, "summary" to getCommandSummary(command)))
        
        return command
    }
    
    /**
     * Normalize text for consistent parsing
     * Equivalent to iOS normalizeText method
     */
    private fun normalizeText(text: String): String {
        return text.lowercase()
            .replace(Regex("\\s+"), " ")  // Multiple spaces to single space
            .replace("channel", "ch")     // Normalize channel references
            .replace("unmute", "mute off")
            .replace("unsolo", "solo off")
            .replace("turn on", "on")
            .replace("turn off", "off")
            .replace("set to", "to")
            .replace("increase", "up")
            .replace("decrease", "down")
            .replace("raise", "up")
            .replace("lower", "down")
            .trim()
    }
    
    /**
     * Try parsing as channel command
     * Equivalent to iOS tryParseChannelCommand method
     */
    private fun tryParseChannelCommand(
        normalizedText: String, 
        confidence: Double, 
        originalText: String
    ): VoiceCommand.ChannelCommand? {
        
        for (pattern in channelPatterns.getAllPatterns()) {
            val matcher = pattern.regex.matcher(normalizedText)
            if (matcher.find()) {
                
                try {
                    val channelNumber = extractChannelNumber(matcher, pattern)
                    val operation = pattern.operation
                    val (parameterValue, parameterUnit) = extractParameter(matcher, pattern)
                    
                    // Calculate adjusted confidence
                    val adjustedConfidence = calculateAdjustedConfidence(
                        baseConfidence = confidence,
                        patternType = pattern.type,
                        hasParameter = parameterValue != null
                    )
                    
                    val command = VoiceCommand.ChannelCommand(
                        originalText = originalText,
                        confidence = adjustedConfidence,
                        channelNumber = channelNumber,
                        operation = operation,
                        parameterValue = parameterValue,
                        parameterUnit = parameterUnit
                    )
                    
                    if (command.isValid) {
                        VLogger.d(TAG, "📻 Channel command: Ch$channelNumber ${operation.name} ${parameterValue ?: ""}", 
                            mapOf("channelNumber" to channelNumber.toString(), "operation" to operation.name, "parameterValue" to (parameterValue?.toString() ?: "")))
                        return command
                    }
                    
                } catch (e: Exception) {
                    VLogger.w(TAG, "⚠️ Error parsing channel command: ${e.message}", 
                        mapOf("error" to (e.message ?: "Unknown error")))
                }
            }
        }
        
        return null
    }
    
    /**
     * Try parsing as scene command
     * Equivalent to iOS tryParseSceneCommand method
     */
    private fun tryParseSceneCommand(
        normalizedText: String, 
        confidence: Double, 
        originalText: String
    ): VoiceCommand.SceneCommand? {
        
        for (pattern in scenePatterns.getAllPatterns()) {
            val matcher = pattern.regex.matcher(normalizedText)
            if (matcher.find()) {
                
                try {
                    val sceneNumber = extractSceneNumber(matcher)
                    val operation = pattern.operation
                    
                    val adjustedConfidence = calculateAdjustedConfidence(
                        baseConfidence = confidence,
                        patternType = PatternType.EXACT,
                        hasParameter = false
                    )
                    
                    val command = VoiceCommand.SceneCommand(
                        originalText = originalText,
                        confidence = adjustedConfidence,
                        sceneNumber = sceneNumber,
                        operation = operation
                    )
                    
                    if (command.isValid) {
                        VLogger.d(TAG, "🎬 Scene command: ${operation.name} Scene $sceneNumber", 
                            mapOf("operation" to operation.name, "sceneNumber" to sceneNumber.toString()))
                        return command
                    }
                    
                } catch (e: Exception) {
                    VLogger.w(TAG, "⚠️ Error parsing scene command: ${e.message}", 
                        mapOf("error" to (e.message ?: "Unknown error")))
                }
            }
        }
        
        return null
    }
    
    /**
     * Try parsing as global command
     * Equivalent to iOS tryParseGlobalCommand method
     */
    private fun tryParseGlobalCommand(
        normalizedText: String, 
        confidence: Double, 
        originalText: String
    ): VoiceCommand.GlobalCommand? {
        
        for (pattern in globalPatterns.getAllPatterns()) {
            val matcher = pattern.regex.matcher(normalizedText)
            if (matcher.find()) {
                
                val operation = pattern.operation
                val parameter = if (matcher.groupCount() > 0) matcher.group(1) else null
                
                val adjustedConfidence = calculateAdjustedConfidence(
                    baseConfidence = confidence,
                    patternType = PatternType.EXACT,
                    hasParameter = parameter != null
                )
                
                val command = VoiceCommand.GlobalCommand(
                    originalText = originalText,
                    confidence = adjustedConfidence,
                    operation = operation,
                    parameter = parameter
                )
                
                if (command.isValid) {
                    VLogger.d(TAG, "🌍 Global command: ${operation.name} ${parameter ?: ""}", 
                        mapOf("operation" to operation.name, "parameter" to (parameter ?: "")))
                    return command
                }
            }
        }
        
        return null
    }
    
    /**
     * Extract channel number from regex match
     */
    private fun extractChannelNumber(matcher: java.util.regex.Matcher, pattern: ChannelPatterns.ChannelPattern): Int {
        val channelGroup = when (pattern.channelGroupIndex) {
            1 -> matcher.group(1)
            2 -> matcher.group(2)
            else -> matcher.group(1)
        }
        
        return channelGroup?.let { 
            convertNumberWordToDigit(it) ?: it.toIntOrNull() 
        } ?: 1
    }
    
    /**
     * Extract scene number from regex match
     */
    private fun extractSceneNumber(matcher: java.util.regex.Matcher): Int {
        val sceneGroup = matcher.group(1)
        return sceneGroup?.let { 
            convertNumberWordToDigit(it) ?: it.toIntOrNull() 
        } ?: 1
    }
    
    /**
     * Extract parameter value and unit from regex match
     */
    private fun extractParameter(matcher: java.util.regex.Matcher, pattern: ChannelPatterns.ChannelPattern): Pair<Float?, String?> {
        if (pattern.parameterGroupIndex == null || pattern.parameterGroupIndex > matcher.groupCount()) {
            return Pair(null, null)
        }
        
        val parameterGroup = matcher.group(pattern.parameterGroupIndex)
        if (parameterGroup.isNullOrBlank()) {
            return Pair(null, null)
        }
        
        // Extract numeric value and unit
        val parameterRegex = Pattern.compile("([+-]?\\d+(?:\\.\\d+)?)\\s*(db|%|percent)?", Pattern.CASE_INSENSITIVE)
        val paramMatcher = parameterRegex.matcher(parameterGroup)
        
        return if (paramMatcher.find()) {
            val value = paramMatcher.group(1)?.toFloatOrNull()
            val unit = paramMatcher.group(2)?.let { 
                when (it.lowercase()) {
                    "db" -> "dB"
                    "percent", "%" -> "%"
                    else -> it
                }
            }
            Pair(value, unit)
        } else {
            Pair(null, null)
        }
    }
    
    /**
     * Convert number words to digits
     * Equivalent to iOS convertNumberWordToDigit method
     */
    private fun convertNumberWordToDigit(word: String): Int? {
        return when (word.lowercase()) {
            "one" -> 1
            "two" -> 2
            "three" -> 3
            "four" -> 4
            "five" -> 5
            "six" -> 6
            "seven" -> 7
            "eight" -> 8
            "nine" -> 9
            "ten" -> 10
            "eleven" -> 11
            "twelve" -> 12
            "thirteen" -> 13
            "fourteen" -> 14
            "fifteen" -> 15
            "sixteen" -> 16
            "seventeen" -> 17
            "eighteen" -> 18
            "nineteen" -> 19
            "twenty" -> 20
            else -> null
        }
    }
    
    /**
     * Calculate adjusted confidence based on pattern matching
     * Equivalent to iOS calculateAdjustedConfidence method
     */
    private fun calculateAdjustedConfidence(
        baseConfidence: Double,
        patternType: PatternType,
        hasParameter: Boolean
    ): Double {
        var adjustedConfidence = baseConfidence
        
        // Boost confidence for exact matches
        when (patternType) {
            PatternType.EXACT -> adjustedConfidence += EXACT_MATCH_BOOST
            PatternType.FUZZY -> adjustedConfidence -= AMBIGUOUS_PENALTY
            PatternType.PARTIAL -> adjustedConfidence -= (AMBIGUOUS_PENALTY / 2)
        }
        
        // Slight penalty for commands with parameters (more complex parsing)
        if (hasParameter) {
            adjustedConfidence -= 0.05
        }
        
        return adjustedConfidence.coerceIn(0.0, 1.0)
    }
    
    /**
     * Get command summary for logging
     */
    private fun getCommandSummary(command: VoiceCommand): String {
        return when (command) {
            is VoiceCommand.ChannelCommand -> "Ch${command.channelNumber} ${command.operation.name}"
            is VoiceCommand.SceneCommand -> "${command.operation.name} Scene ${command.sceneNumber}"
            is VoiceCommand.GlobalCommand -> command.operation.name
            is VoiceCommand.UnknownCommand -> "Unknown: ${command.reason}"
        }
    }
    
    /**
     * Get processing statistics
     */
    fun getProcessingStats(): Map<String, Any> {
        val successRate = if (_processedCommandsCount.value > 0) {
            _successfulCommandsCount.value.toDouble() / _processedCommandsCount.value.toDouble()
        } else {
            0.0
        }
        
        return mapOf(
            "totalProcessed" to _processedCommandsCount.value,
            "successfulCommands" to _successfulCommandsCount.value,
            "successRate" to successRate,
            "failedCommands" to (_processedCommandsCount.value - _successfulCommandsCount.value)
        )
    }
    
    /**
     * Reset processing statistics
     */
    fun resetStats() {
        _processedCommandsCount.value = 0
        _successfulCommandsCount.value = 0
        
        VLogger.d(TAG, "📊 Processing statistics reset")
    }
}

/**
 * Pattern types for confidence adjustment
 */
enum class PatternType {
    EXACT,    // Exact phrase match
    FUZZY,    // Fuzzy/partial match
    PARTIAL   // Partial phrase match
}

/**
 * Channel command patterns
 */
private class ChannelPatterns {
    
    data class ChannelPattern(
        val regex: Pattern,
        val operation: VoiceCommand.ChannelCommand.ChannelOperation,
        val type: PatternType,
        val channelGroupIndex: Int = 1,
        val parameterGroupIndex: Int? = null
    )
    
    fun getAllPatterns(): List<ChannelPattern> = listOf(
        // Mute commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+mute\\s+on"),
            VoiceCommand.ChannelCommand.ChannelOperation.MUTE_ON,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+mute\\s+off"),
            VoiceCommand.ChannelCommand.ChannelOperation.MUTE_OFF,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("mute\\s+(?:ch|channel)\\s+(\\d+)"),
            VoiceCommand.ChannelCommand.ChannelOperation.MUTE_ON,
            PatternType.PARTIAL
        ),
        
        // Solo commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+solo\\s+on"),
            VoiceCommand.ChannelCommand.ChannelOperation.SOLO_ON,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+solo\\s+off"),
            VoiceCommand.ChannelCommand.ChannelOperation.SOLO_OFF,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("solo\\s+(?:ch|channel)\\s+(\\d+)"),
            VoiceCommand.ChannelCommand.ChannelOperation.SOLO_ON,
            PatternType.PARTIAL
        ),
        
        // Fader commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+fader\\s+to\\s+([+-]?\\d+(?:\\.\\d+)?(?:\\s*db|%|percent)?)"),
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_SET,
            PatternType.EXACT,
            channelGroupIndex = 1,
            parameterGroupIndex = 2
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+(?:fader\\s+)?up"),
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_INCREASE,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+(?:fader\\s+)?down"),
            VoiceCommand.ChannelCommand.ChannelOperation.FADER_DECREASE,
            PatternType.EXACT
        ),
        
        // Gain commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+gain\\s+to\\s+([+-]?\\d+(?:\\.\\d+)?(?:\\s*db|%|percent)?)"),
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_SET,
            PatternType.EXACT,
            channelGroupIndex = 1,
            parameterGroupIndex = 2
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+gain\\s+up"),
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_INCREASE,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+gain\\s+down"),
            VoiceCommand.ChannelCommand.ChannelOperation.GAIN_DECREASE,
            PatternType.EXACT
        ),
        
        // Pan commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+pan\\s+center"),
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_CENTER,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+pan\\s+left"),
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_LEFT,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+pan\\s+right"),
            VoiceCommand.ChannelCommand.ChannelOperation.PAN_RIGHT,
            PatternType.EXACT
        ),
        
        // Phantom power commands
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+phantom\\s+on"),
            VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_ON,
            PatternType.EXACT
        ),
        ChannelPattern(
            Pattern.compile("(?:ch|channel)\\s+(\\d+)\\s+phantom\\s+off"),
            VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_OFF,
            PatternType.EXACT
        )
    )
}

/**
 * Scene command patterns
 */
private class ScenePatterns {
    
    data class ScenePattern(
        val regex: Pattern,
        val operation: VoiceCommand.SceneCommand.SceneOperation,
        val type: PatternType
    )
    
    fun getAllPatterns(): List<ScenePattern> = listOf(
        ScenePattern(
            Pattern.compile("recall\\s+scene\\s+(\\d+)"),
            VoiceCommand.SceneCommand.SceneOperation.RECALL,
            PatternType.EXACT
        ),
        ScenePattern(
            Pattern.compile("store\\s+scene\\s+(\\d+)"),
            VoiceCommand.SceneCommand.SceneOperation.STORE,
            PatternType.EXACT
        ),
        ScenePattern(
            Pattern.compile("scene\\s+(\\d+)\\s+recall"),
            VoiceCommand.SceneCommand.SceneOperation.RECALL,
            PatternType.PARTIAL
        ),
        ScenePattern(
            Pattern.compile("scene\\s+(\\d+)\\s+store"),
            VoiceCommand.SceneCommand.SceneOperation.STORE,
            PatternType.PARTIAL
        )
    )
}

/**
 * Global command patterns
 */
private class GlobalPatterns {
    
    data class GlobalPattern(
        val regex: Pattern,
        val operation: VoiceCommand.GlobalCommand.GlobalOperation,
        val type: PatternType
    )
    
    fun getAllPatterns(): List<GlobalPattern> = listOf(
        // Master mute
        GlobalPattern(
            Pattern.compile("master\\s+mute\\s+on"),
            VoiceCommand.GlobalCommand.GlobalOperation.MASTER_MUTE_ON,
            PatternType.EXACT
        ),
        GlobalPattern(
            Pattern.compile("master\\s+mute\\s+off"),
            VoiceCommand.GlobalCommand.GlobalOperation.MASTER_MUTE_OFF,
            PatternType.EXACT
        ),
        
        // All mute
        GlobalPattern(
            Pattern.compile("all\\s+mute\\s+on"),
            VoiceCommand.GlobalCommand.GlobalOperation.ALL_MUTE_ON,
            PatternType.EXACT
        ),
        GlobalPattern(
            Pattern.compile("all\\s+mute\\s+off"),
            VoiceCommand.GlobalCommand.GlobalOperation.ALL_MUTE_OFF,
            PatternType.EXACT
        ),
        
        // Solo clear
        GlobalPattern(
            Pattern.compile("(?:clear\\s+all\\s+solo|all\\s+solo\\s+clear)"),
            VoiceCommand.GlobalCommand.GlobalOperation.ALL_SOLO_CLEAR,
            PatternType.EXACT
        ),
        
        // Talkback
        GlobalPattern(
            Pattern.compile("talkback\\s+on"),
            VoiceCommand.GlobalCommand.GlobalOperation.TALKBACK_ON,
            PatternType.EXACT
        ),
        GlobalPattern(
            Pattern.compile("talkback\\s+off"),
            VoiceCommand.GlobalCommand.GlobalOperation.TALKBACK_OFF,
            PatternType.EXACT
        )
    )
}