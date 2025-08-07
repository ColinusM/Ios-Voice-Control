package com.voicecontrol.app.speech.service

import android.util.Log
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.speech.model.StreamingConfig
import com.voicecontrol.app.speech.model.TranscriptionResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Speech Recognition Service for Voice Control App
 * 
 * Integrates AudioManager and AssemblyAI streamer for complete real-time speech recognition
 * Direct port of iOS speech recognition coordination to Android
 * 
 * Features:
 * - Complete speech recognition pipeline (Audio → Streaming → Results)
 * - Real-time audio capture and streaming to AssemblyAI
 * - Buffer management for efficient audio processing
 * - Connection state management and error handling
 * - Configurable recognition parameters
 * - Lifecycle management and resource cleanup
 * - Thread-safe operations with coroutines
 */
@Singleton
class SpeechRecognitionService @Inject constructor(
    private val audioManager: AudioManager,
    private val assemblyAIStreamer: AssemblyAIStreamer
) {
    
    companion object {
        private const val TAG = "SpeechRecognitionService"
        private const val AUDIO_BUFFER_SIZE = 4096
        private const val MIN_AUDIO_LEVEL_THRESHOLD = 0.02f
    }
    
    // Coroutine scope for managing async operations
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var recognitionJob: Job? = null
    
    // Current configuration
    private var currentConfig = StreamingConfig.professionalAudio()
    
    // State flows for reactive UI updates
    private val _isRecognizing = MutableStateFlow(false)
    val isRecognizing: StateFlow<Boolean> = _isRecognizing.asStateFlow()
    
    private val _recognitionState = MutableStateFlow(RecognitionState.Stopped)
    val recognitionState: StateFlow<RecognitionState> = _recognitionState.asStateFlow()
    
    private val _hasAudioPermission = MutableStateFlow(false)
    val hasAudioPermission: StateFlow<Boolean> = _hasAudioPermission.asStateFlow()
    
    private val _audioLevel = MutableStateFlow(0.0f)
    val audioLevel: StateFlow<Float> = _audioLevel.asStateFlow()
    
    // Transcription results from AssemblyAI
    val transcriptionFlow: Flow<TranscriptionResult> = assemblyAIStreamer.transcriptionFlow
    
    /**
     * Recognition states for the complete pipeline
     * Equivalent to iOS speech recognition states
     */
    enum class RecognitionState {
        Stopped,           // Not recording or recognizing
        Starting,          // Initializing audio and streaming
        Recording,         // Audio recording active
        Processing,        // Audio streaming to AssemblyAI
        Stopping,          // Cleaning up resources
        Error              // Error occurred
    }
    
    init {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎙️ SpeechRecognitionService initialized")
        }
        
        // Observe audio manager permission state
        serviceScope.launch {
            audioManager.hasAudioPermissionFlow.collect { hasPermission ->
                _hasAudioPermission.value = hasPermission
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔐 Audio permission: $hasPermission")
                }
            }
        }
        
        // Observe audio level for UI feedback
        serviceScope.launch {
            audioManager.audioLevelFlow.collect { level ->
                _audioLevel.value = level
            }
        }
        
        // Observe AssemblyAI connection state
        serviceScope.launch {
            assemblyAIStreamer.connectionState.collect { connectionState ->
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔗 AssemblyAI connection: $connectionState")
                }
                
                // Update recognition state based on connection
                when (connectionState) {
                    AssemblyAIStreamer.ConnectionState.Connecting -> {
                        if (_recognitionState.value == RecognitionState.Starting) {
                            // Keep starting state
                        }
                    }
                    AssemblyAIStreamer.ConnectionState.Connected -> {
                        if (_recognitionState.value == RecognitionState.Starting) {
                            _recognitionState.value = RecognitionState.Recording
                        }
                    }
                    AssemblyAIStreamer.ConnectionState.Error -> {
                        if (_isRecognizing.value) {
                            _recognitionState.value = RecognitionState.Error
                        }
                    }
                    AssemblyAIStreamer.ConnectionState.Disconnected -> {
                        if (_isRecognizing.value) {
                            _recognitionState.value = RecognitionState.Stopped
                            _isRecognizing.value = false
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Update audio permission status
     * Should be called after permission request result
     */
    fun updateAudioPermission(granted: Boolean) {
        audioManager.updateAudioPermission(granted)
        _hasAudioPermission.value = granted
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔐 Audio permission updated: $granted")
        }
    }
    
    /**
     * Start speech recognition with configuration
     * Equivalent to iOS startRecognition method
     */
    suspend fun startRecognition(config: StreamingConfig = StreamingConfig.professionalAudio()): Boolean {
        if (_isRecognizing.value) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Speech recognition already running")
            }
            return true
        }
        
        if (!_hasAudioPermission.value) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Cannot start recognition - no audio permission")
            }
            _recognitionState.value = RecognitionState.Error
            return false
        }
        
        currentConfig = config
        _isRecognizing.value = true
        _recognitionState.value = RecognitionState.Starting
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 Starting speech recognition")
            Log.d(TAG, "📊 Config: $config")
        }
        
        // Start recognition pipeline in coroutine
        recognitionJob = serviceScope.launch {
            try {
                // Step 1: Connect to AssemblyAI
                val streamingStarted = assemblyAIStreamer.startStreaming(config)
                if (!streamingStarted) {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.e(TAG, "❌ Failed to start AssemblyAI streaming")
                    }
                    _recognitionState.value = RecognitionState.Error
                    _isRecognizing.value = false
                    return@launch
                }
                
                // Step 2: Start audio recording with callback
                val audioStarted = audioManager.startRecording { audioData, length ->
                    handleAudioData(audioData, length)
                }
                
                if (!audioStarted) {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.e(TAG, "❌ Failed to start audio recording")
                    }
                    assemblyAIStreamer.stopStreaming()
                    _recognitionState.value = RecognitionState.Error
                    _isRecognizing.value = false
                    return@launch
                }
                
                _recognitionState.value = RecognitionState.Processing
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Speech recognition pipeline started successfully")
                }
                
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Error starting speech recognition", e)
                }
                _recognitionState.value = RecognitionState.Error
                _isRecognizing.value = false
            }
        }
        
        return true
    }
    
    /**
     * Stop speech recognition
     * Equivalent to iOS stopRecognition method
     */
    suspend fun stopRecognition() {
        if (!_isRecognizing.value) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Speech recognition not running")
            }
            return
        }
        
        _recognitionState.value = RecognitionState.Stopping
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🛑 Stopping speech recognition")
        }
        
        try {
            // Cancel recognition job
            recognitionJob?.cancel()
            recognitionJob = null
            
            // Stop audio recording
            audioManager.stopRecording()
            
            // Stop AssemblyAI streaming
            assemblyAIStreamer.stopStreaming()
            
            _isRecognizing.value = false
            _recognitionState.value = RecognitionState.Stopped
            _audioLevel.value = 0.0f
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Speech recognition stopped successfully")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error stopping speech recognition", e)
            }
            _recognitionState.value = RecognitionState.Error
        }
    }
    
    /**
     * Handle audio data from AudioManager
     * Processes and streams to AssemblyAI
     * Equivalent to iOS audio data processing
     */
    private fun handleAudioData(audioData: ByteArray, length: Int) {
        if (!_isRecognizing.value || _recognitionState.value != RecognitionState.Processing) {
            return
        }
        
        try {
            // Apply audio level threshold to reduce noise
            val audioLevel = _audioLevel.value
            if (audioLevel < MIN_AUDIO_LEVEL_THRESHOLD) {
                // Skip very quiet audio to reduce processing
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.v(TAG, "🔇 Skipping quiet audio (level: ${"%.4f".format(audioLevel)})")
                }
                return
            }
            
            // Send audio data to AssemblyAI
            assemblyAIStreamer.sendAudioData(audioData, length)
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.v(TAG, "🎵 Sent $length bytes to AssemblyAI (level: ${"%.3f".format(audioLevel)})")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error processing audio data", e)
            }
        }
    }
    
    /**
     * Update streaming configuration
     * Can be called while recognition is running
     * Equivalent to iOS updateConfiguration method
     */
    fun updateConfiguration(config: StreamingConfig) {
        currentConfig = config
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📊 Updated configuration: $config")
        }
    }
    
    /**
     * Get current configuration
     * Equivalent to iOS currentConfiguration property
     */
    fun getCurrentConfiguration(): StreamingConfig {
        return currentConfig
    }
    
    /**
     * Check if speech recognition is available
     * Verifies permissions and hardware support
     * Equivalent to iOS isAvailable property
     */
    val isAvailable: Boolean
        get() = _hasAudioPermission.value && audioManager.isAudioFormatSupported()
    
    /**
     * Check if currently processing audio
     * Equivalent to iOS isProcessing property
     */
    val isProcessing: Boolean
        get() = _recognitionState.value == RecognitionState.Processing
    
    /**
     * Check if there's an active error state
     * Equivalent to iOS hasError property
     */
    val hasError: Boolean
        get() = _recognitionState.value == RecognitionState.Error
    
    /**
     * Clear error state and reset to stopped
     * Equivalent to iOS clearError method
     */
    fun clearError() {
        if (_recognitionState.value == RecognitionState.Error) {
            _recognitionState.value = RecognitionState.Stopped
            _isRecognizing.value = false
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔄 Error state cleared")
            }
        }
    }
    
    /**
     * Get recognition statistics for debugging
     * Equivalent to iOS recognitionStats property
     */
    fun getRecognitionStats(): Map<String, Any> {
        return mapOf(
            "isRecognizing" to _isRecognizing.value,
            "recognitionState" to _recognitionState.value.name,
            "hasPermission" to _hasAudioPermission.value,
            "audioLevel" to _audioLevel.value,
            "assemblyAIConnected" to (assemblyAIStreamer.connectionState.value == AssemblyAIStreamer.ConnectionState.Connected),
            "audioRecording" to audioManager.currentlyRecording,
            "configuration" to currentConfig
        )
    }
    
    /**
     * Cleanup resources when service is destroyed
     * Equivalent to iOS cleanup method
     */
    fun cleanup() {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 Cleaning up SpeechRecognitionService")
        }
        
        // Stop recognition if active
        if (_isRecognizing.value) {
            serviceScope.launch {
                stopRecognition()
            }
        }
        
        // Cleanup individual components
        audioManager.cleanup()
        assemblyAIStreamer.cleanup()
        
        // Cancel coroutine scope
        serviceScope.cancel()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 SpeechRecognitionService cleanup completed")
        }
    }
}