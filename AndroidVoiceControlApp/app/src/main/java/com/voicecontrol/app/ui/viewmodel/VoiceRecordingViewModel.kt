package com.voicecontrol.app.ui.viewmodel

import android.Manifest
import android.app.Application
import android.content.pm.PackageManager
import com.voicecontrol.app.utils.VLogger
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.speech.model.StreamingConfig
import com.voicecontrol.app.speech.model.TranscriptionResult
import com.voicecontrol.app.speech.service.SpeechRecognitionService
import com.voicecontrol.app.voice.service.VoiceCommandProcessor
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Voice Recording ViewModel for Voice Control App
 * 
 * MVVM coordination layer for voice recording and speech recognition
 * Connects SpeechRecognitionService with UI components via StateFlow
 * Direct port of iOS VoiceRecordingViewModel to Android
 * 
 * Features:
 * - StateFlow reactive state management for UI updates
 * - Permission handling for RECORD_AUDIO
 * - Voice command processing and transcription
 * - Error handling and recovery logic
 * - Audio level monitoring for UI feedback
 * - Complete recording lifecycle management
 */
@HiltViewModel
class VoiceRecordingViewModel @Inject constructor(
    private val speechRecognitionService: SpeechRecognitionService,
    private val voiceCommandProcessor: VoiceCommandProcessor,
    private val application: Application
) : ViewModel() {

    companion object {
        private const val TAG = "VoiceRecordingViewModel"
        
        // Retry configuration constants
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val INITIAL_RETRY_DELAY_MS = 1000L
        private const val MAX_RETRY_DELAY_MS = 5000L
        private const val RETRY_BACKOFF_MULTIPLIER = 2.0
    }

    /**
     * UI State data class combining all recording-related state
     * Equivalent to iOS VoiceRecordingState
     */
    data class RecordingUiState(
        val isRecording: Boolean = false,
        val audioLevel: Float = 0f,
        val recognitionState: SpeechRecognitionService.RecognitionState = SpeechRecognitionService.RecognitionState.Stopped,
        val lastTranscription: String? = null,
        val lastCommand: String? = null,
        val error: String? = null,
        val hasPermission: Boolean = false,
        val isProcessingCommand: Boolean = false,
        val isRetrying: Boolean = false,
        val retryAttempt: Int = 0,
        val maxRetryAttempts: Int = MAX_RETRY_ATTEMPTS
    )

    // Internal state for permission requests
    private val _permissionRequested = MutableStateFlow(false)
    
    // Internal state for error handling
    private val _error = MutableStateFlow<String?>(null)
    
    // Internal state for processed commands
    private val _lastCommand = MutableStateFlow<String?>(null)
    
    // Internal state for transcription processing
    private val _isProcessingCommand = MutableStateFlow(false)
    
    // Internal state for retry logic
    private val _isRetrying = MutableStateFlow(false)
    private val _retryAttempt = MutableStateFlow(0)
    private var retryJob: kotlinx.coroutines.Job? = null

    /**
     * Combined UI state from multiple service flows
     * Reactive state management for Compose UI updates
     */
    val uiState: StateFlow<RecordingUiState> = combine(
        combine(
            speechRecognitionService.isRecognizing,
            speechRecognitionService.audioLevel,
            speechRecognitionService.recognitionState,
            speechRecognitionService.hasAudioPermission,
            _error
        ) { isRecording, audioLevel, recognitionState, hasPermission, error ->
            RecordingUiStateBasic(isRecording, audioLevel, recognitionState, hasPermission, error)
        },
        combine(
            _lastCommand,
            _isProcessingCommand,
            _isRetrying,
            _retryAttempt
        ) { lastCommand, isProcessing, isRetrying, retryAttempt ->
            RecordingUiStateExtended(lastCommand, isProcessing, isRetrying, retryAttempt)
        }
    ) { basic, extended ->
        RecordingUiState(
            isRecording = basic.isRecording,
            audioLevel = basic.audioLevel,
            recognitionState = basic.recognitionState,
            hasPermission = basic.hasPermission,
            error = basic.error,
            lastCommand = extended.lastCommand,
            isProcessingCommand = extended.isProcessingCommand,
            isRetrying = extended.isRetrying,
            retryAttempt = extended.retryAttempt
        )
    }.stateIn(
        viewModelScope, 
        SharingStarted.Lazily, 
        RecordingUiState()
    )

    init {
        VLogger.d(TAG, "🎙️ VoiceRecordingViewModel initialized")

        // Check initial permission state
        checkAudioPermission()

        // Observe transcription results for command processing
        viewModelScope.launch {
            speechRecognitionService.transcriptionFlow.collect { result ->
                handleTranscriptionResult(result)
            }
        }

        // Log state changes for debugging
        viewModelScope.launch {
            uiState.collect { state ->
                VLogger.v(TAG, "📊 UI State: recording=${state.isRecording}, state=${state.recognitionState}, audioLevel=${"%.3f".format(state.audioLevel)}, hasPermission=${state.hasPermission}",
                    mapOf(
                        "isRecording" to state.isRecording.toString(),
                        "recognitionState" to state.recognitionState.toString(),
                        "audioLevel" to "%.3f".format(state.audioLevel),
                        "hasPermission" to state.hasPermission.toString()
                    )
                )
            }
        }
    }

    /**
     * Start voice recording and speech recognition
     * Equivalent to iOS startRecording method
     */
    fun startRecording() {
        VLogger.d(TAG, "🚀 Start recording requested")

        // Clear any previous errors
        _error.value = null
        _lastCommand.value = null

        // Check permission before starting
        if (!hasAudioPermission()) {
            VLogger.w(TAG, "⚠️ Audio permission not granted")
            _error.value = "Microphone permission required"
            return
        }

        viewModelScope.launch {
            try {
                // Use the new retry logic for more robust recording start
                VLogger.time("start_recording", "Voice Recording Start") {
                    startRecordingWithRetry()
                }
                
            } catch (e: Exception) {
                _error.value = "Error starting recording: ${e.message}"
                VLogger.e(TAG, "❌ Exception starting recording", 
                    mapOf("error" to (e.message ?: "Unknown error")), e)
            }
        }
    }

    /**
     * Stop voice recording and speech recognition
     * Equivalent to iOS stopRecording method
     */
    fun stopRecording() {
        VLogger.d(TAG, "🛑 Stop recording requested")

        viewModelScope.launch {
            try {
                speechRecognitionService.stopRecognition()
                _isProcessingCommand.value = false
                
            } catch (e: Exception) {
                _error.value = "Error stopping recording: ${e.message}"
                VLogger.e(TAG, "❌ Exception stopping recording", 
                    mapOf("error" to (e.message ?: "Unknown error")), e)
            }
        }
    }

    /**
     * Toggle recording state (start if stopped, stop if recording)
     * Convenient method for UI button click handlers
     */
    fun toggleRecording() {
        val currentState = uiState.value
        if (currentState.isRecording) {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /**
     * Check microphone permission status
     * Updates internal permission state
     */
    private fun checkAudioPermission() {
        val hasPermission = ContextCompat.checkSelfPermission(
            application,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        speechRecognitionService.updateAudioPermission(hasPermission)

        VLogger.d(TAG, "🔐 Audio permission check: $hasPermission", 
            mapOf("hasPermission" to hasPermission.toString()))
    }

    /**
     * Check if audio permission is currently granted
     * Equivalent to iOS AVAudioSession.recordPermission check
     */
    private fun hasAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            application,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Update permission status after permission request result
     * Should be called from Activity/Fragment after permission request
     */
    fun updatePermissionResult(granted: Boolean) {
        speechRecognitionService.updateAudioPermission(granted)
        
        if (!granted) {
            _error.value = "Microphone permission is required for voice control"
        } else {
            _error.value = null
        }

        VLogger.d(TAG, "🔐 Permission result updated: $granted", 
            mapOf("granted" to granted.toString()))
    }

    /**
     * Handle transcription results from speech recognition
     * Process voice commands and update UI state
     */
    private suspend fun handleTranscriptionResult(result: TranscriptionResult) {
        VLogger.d(TAG, "📝 Transcription: \"${result.text}\" (final: ${result.isFinal}, confidence: ${result.confidence})", 
            mapOf(
                "text" to result.text,
                "isFinal" to result.isFinal.toString(),
                "confidence" to result.confidence.toString()
            )
        )

        // Only process final transcriptions with reasonable confidence
        if (result.isFinal && result.confidence > 0.5 && result.text.isNotBlank()) {
            _isProcessingCommand.value = true
            
            try {
                // Process voice command through voice command processor
                val processedCommand = VLogger.time("process_command", "Voice Command Processing") {
                    voiceCommandProcessor.processTranscription(result.text, result.confidence)
                }
                
                if (processedCommand.isValid) {
                    _lastCommand.value = processedCommand.toString()
                    
                    VLogger.d(TAG, "✅ Voice command processed: $processedCommand",
                        mapOf("command" to processedCommand.toString()))
                } else {
                    VLogger.w(TAG, "⚠️ Voice command not recognized: ${result.text} - ${processedCommand.toString()}",
                        mapOf(
                            "originalText" to result.text,
                            "processedResult" to processedCommand.toString()
                        ))
                }
                
            } catch (e: Exception) {
                _error.value = "Error processing command: ${e.message}"
                VLogger.e(TAG, "❌ Error processing voice command", 
                    mapOf("error" to (e.message ?: "Unknown error")), e)
            } finally {
                _isProcessingCommand.value = false
            }
        }
    }

    /**
     * Clear error state
     * Allows user to retry after error
     */
    fun clearError() {
        _error.value = null
        speechRecognitionService.clearError()
        
        VLogger.d(TAG, "🔄 Error state cleared")
    }

    /**
     * Clear last command
     * Resets command display in UI
     */
    fun clearLastCommand() {
        _lastCommand.value = null
        
        VLogger.d(TAG, "🧹 Last command cleared")
    }

    /**
     * Start recording with automatic retry logic
     * Enhanced version with exponential backoff retry
     */
    private suspend fun startRecordingWithRetry() {
        val maxAttempts = MAX_RETRY_ATTEMPTS
        var attempt = 0
        var delayMs = INITIAL_RETRY_DELAY_MS

        while (attempt < maxAttempts) {
            attempt++
            _retryAttempt.value = attempt

            VLogger.d(TAG, "🔄 Recording attempt $attempt/$maxAttempts", 
                mapOf("attempt" to attempt.toString(), "maxAttempts" to maxAttempts.toString()))

            try {
                val config = com.voicecontrol.app.speech.model.StreamingConfig.professionalAudio()
                val success = speechRecognitionService.startRecognition(config)
                
                if (success) {
                    _isRetrying.value = false
                    _retryAttempt.value = 0
                    _error.value = null
                    
                    VLogger.d(TAG, "✅ Recording started successfully on attempt $attempt", 
                        mapOf("successAttempt" to attempt.toString()))
                    return
                }
                
            } catch (e: Exception) {
                VLogger.w(TAG, "⚠️ Recording attempt $attempt failed: ${e.message}",
                    mapOf("attempt" to attempt.toString(), "error" to (e.message ?: "Unknown error")))
            }

            // If not the last attempt, wait before retrying
            if (attempt < maxAttempts) {
                _isRetrying.value = true
                
                VLogger.d(TAG, "⏳ Retrying in ${delayMs}ms...", 
                    mapOf("delayMs" to delayMs.toString()))
                
                kotlinx.coroutines.delay(delayMs)
                
                // Exponential backoff with cap
                delayMs = (delayMs * RETRY_BACKOFF_MULTIPLIER).toLong().coerceAtMost(MAX_RETRY_DELAY_MS)
            }
        }

        // All retry attempts failed
        _isRetrying.value = false
        _retryAttempt.value = 0
        _error.value = "Failed to start recording after $maxAttempts attempts. Please check your connection and permissions."
        
        VLogger.e(TAG, "❌ All retry attempts failed", 
            mapOf("maxAttempts" to maxAttempts.toString()))
    }

    /**
     * Retry failed operation
     * Allows manual retry from UI
     */
    fun retryOperation() {
        VLogger.d(TAG, "🔄 Manual retry requested")

        // Cancel any existing retry job
        retryJob?.cancel()
        
        // Clear current error state
        _error.value = null
        _retryAttempt.value = 0
        
        // Start retry operation
        retryJob = viewModelScope.launch {
            try {
                startRecordingWithRetry()
            } catch (e: Exception) {
                _error.value = "Retry failed: ${e.message}"
                VLogger.e(TAG, "❌ Manual retry failed", 
                    mapOf("error" to (e.message ?: "Unknown error")), e)
            }
        }
    }

    /**
     * Cancel ongoing retry operation
     */
    fun cancelRetry() {
        retryJob?.cancel()
        retryJob = null
        _isRetrying.value = false
        _retryAttempt.value = 0
        
        VLogger.d(TAG, "🛑 Retry operation cancelled")
    }

    /**
     * Get recording statistics for debugging
     * Equivalent to iOS recording statistics
     */
    fun getRecordingStats(): Map<String, Any> {
        val serviceStats = speechRecognitionService.getRecognitionStats()
        val uiStateValue = uiState.value
        
        return serviceStats + mapOf(
            "viewModelState" to mapOf(
                "hasPermission" to uiStateValue.hasPermission,
                "lastCommand" to uiStateValue.lastCommand,
                "error" to uiStateValue.error,
                "isProcessingCommand" to uiStateValue.isProcessingCommand
            )
        )
    }

    /**
     * Cleanup resources when ViewModel is cleared
     */
    override fun onCleared() {
        super.onCleared()
        
        VLogger.d(TAG, "🧹 VoiceRecordingViewModel cleanup")
        
        // Cancel any pending retry operations
        retryJob?.cancel()
        
        // Stop recording if active
        viewModelScope.launch {
            if (uiState.value.isRecording) {
                stopRecording()
            }
        }
    }
}

/**
 * Helper data classes for combining flows
 */
private data class RecordingUiStateBasic(
    val isRecording: Boolean,
    val audioLevel: Float,
    val recognitionState: SpeechRecognitionService.RecognitionState,
    val hasPermission: Boolean,
    val error: String?
)

private data class RecordingUiStateExtended(
    val lastCommand: String?,
    val isProcessingCommand: Boolean,
    val isRetrying: Boolean,
    val retryAttempt: Int
)