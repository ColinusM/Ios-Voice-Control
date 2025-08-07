package com.voicecontrol.app.speech.service

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.core.app.ActivityCompat
import com.voicecontrol.app.BuildConfig
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Audio Manager for Voice Control App
 * 
 * Direct port of iOS AudioManager to Android AudioRecord API
 * Handles real-time audio capture, processing, and streaming
 * 
 * Features:
 * - Real-time audio recording with AudioRecord (equivalent to iOS AVAudioEngine)
 * - 16kHz/16-bit PCM audio format for AssemblyAI compatibility
 * - Permission handling for microphone access
 * - Audio session management and lifecycle
 * - Background recording support
 * - Audio buffer processing and streaming
 * - Noise detection and audio level monitoring
 */
@Singleton
class AudioManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val TAG = "AudioManager"
        
        // Audio configuration for AssemblyAI compatibility
        const val SAMPLE_RATE = 16000 // 16kHz
        const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        const val BUFFER_SIZE_MULTIPLIER = 4
        
        // Recording states
        private const val RECORDING_STATE_STOPPED = 0
        private const val RECORDING_STATE_RECORDING = 1
        private const val RECORDING_STATE_PAUSED = 2
    }
    
    // Audio recording components
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private val bufferSize = AudioRecord.getMinBufferSize(
        SAMPLE_RATE,
        CHANNEL_CONFIG,
        AUDIO_FORMAT
    ) * BUFFER_SIZE_MULTIPLIER
    
    // State flows for reactive UI updates
    private val _isRecording = MutableStateFlow(false)
    val isRecordingFlow: StateFlow<Boolean> = _isRecording.asStateFlow()
    
    private val _audioLevel = MutableStateFlow(0.0f)
    val audioLevelFlow: StateFlow<Float> = _audioLevel.asStateFlow()
    
    private val _hasAudioPermission = MutableStateFlow(false)
    val hasAudioPermissionFlow: StateFlow<Boolean> = _hasAudioPermission.asStateFlow()
    
    // Audio data callback
    private var audioDataCallback: ((ByteArray, Int) -> Unit)? = null
    
    init {
        checkAudioPermission()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎙️ AudioManager initialized - Buffer size: $bufferSize bytes")
        }
    }
    
    /**
     * Check microphone permission status
     * Equivalent to iOS AVAudioSession.recordPermission
     */
    private fun checkAudioPermission() {
        val hasPermission = ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        _hasAudioPermission.value = hasPermission
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔐 Audio permission status: $hasPermission")
        }
    }
    
    /**
     * Update audio permission status
     * Called after permission request result
     */
    fun updateAudioPermission(granted: Boolean) {
        _hasAudioPermission.value = granted
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔐 Audio permission updated: $granted")
        }
    }
    
    /**
     * Set up audio recording session
     * Equivalent to iOS AVAudioSession configuration
     */
    private suspend fun setupAudioSession(): Boolean = withContext(Dispatchers.IO) {
        try {
            if (audioRecord != null) {
                releaseAudioRecord()
            }
            
            // Check permission before creating AudioRecord
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.RECORD_AUDIO
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Audio permission not granted")
                }
                return@withContext false
            }
            
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )
            
            val state = audioRecord?.state
            if (state == AudioRecord.STATE_INITIALIZED) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ AudioRecord initialized successfully")
                }
                return@withContext true
            } else {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ AudioRecord initialization failed - State: $state")
                }
                return@withContext false
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error setting up audio session", e)
            }
            return@withContext false
        }
    }
    
    /**
     * Start audio recording
     * Equivalent to iOS AVAudioEngine start()
     */
    suspend fun startRecording(onAudioData: (ByteArray, Int) -> Unit): Boolean {
        if (isRecording) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Recording already in progress")
            }
            return true
        }
        
        if (!setupAudioSession()) {
            return false
        }
        
        audioDataCallback = onAudioData
        
        return withContext(Dispatchers.IO) {
            try {
                audioRecord?.startRecording()
                isRecording = true
                _isRecording.value = true
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🎙️ Started recording audio")
                }
                
                // Start recording thread
                recordingThread = Thread { recordingLoop() }
                recordingThread?.start()
                
                true
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Error starting recording", e)
                }
                isRecording = false
                _isRecording.value = false
                false
            }
        }
    }
    
    /**
     * Stop audio recording
     * Equivalent to iOS AVAudioEngine stop()
     */
    suspend fun stopRecording() = withContext(Dispatchers.IO) {
        if (!isRecording) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Recording not in progress")
            }
            return@withContext
        }
        
        try {
            isRecording = false
            _isRecording.value = false
            
            audioRecord?.stop()
            recordingThread?.join(1000) // Wait up to 1 second for thread to finish
            
            releaseAudioRecord()
            audioDataCallback = null
            
            _audioLevel.value = 0.0f
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🛑 Stopped recording audio")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error stopping recording", e)
            }
        }
    }
    
    /**
     * Recording loop for processing audio data
     * Equivalent to iOS audio engine tap callback
     */
    private fun recordingLoop() {
        val audioBuffer = ByteArray(bufferSize)
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Recording loop started")
        }
        
        while (isRecording && audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
            try {
                val bytesRead = audioRecord?.read(audioBuffer, 0, audioBuffer.size) ?: 0
                
                if (bytesRead > 0) {
                    // Calculate audio level for UI feedback
                    val audioLevel = calculateAudioLevel(audioBuffer, bytesRead)
                    _audioLevel.value = audioLevel
                    
                    // Send audio data to callback (AssemblyAI streamer)
                    audioDataCallback?.invoke(audioBuffer, bytesRead)
                    
                    if (BuildConfig.ENABLE_LOGGING && audioLevel > 0.1f) {
                        // Only log when there's actual audio to avoid spam
                        Log.v(TAG, "🎵 Audio data: $bytesRead bytes, level: ${"%.3f".format(audioLevel)}")
                    }
                }
                
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Error reading audio data", e)
                }
                break
            }
        }
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Recording loop ended")
        }
    }
    
    /**
     * Calculate audio level for UI feedback
     * Equivalent to iOS audio level calculation
     */
    private fun calculateAudioLevel(buffer: ByteArray, length: Int): Float {
        var sum = 0L
        
        // Process 16-bit PCM data
        val shortBuffer = ByteBuffer.wrap(buffer, 0, length).asShortBuffer()
        
        while (shortBuffer.hasRemaining()) {
            val sample = shortBuffer.get().toInt()
            sum += (sample * sample).toLong()
        }
        
        val samples = length / 2 // 16-bit = 2 bytes per sample
        if (samples == 0) return 0.0f
        
        val rms = kotlin.math.sqrt(sum.toDouble() / samples)
        
        // Convert to 0.0-1.0 range (normalized for 16-bit audio)
        return (rms / 32767.0).toFloat().coerceIn(0.0f, 1.0f)
    }
    
    /**
     * Release AudioRecord resources
     * Equivalent to iOS audio engine cleanup
     */
    private fun releaseAudioRecord() {
        try {
            audioRecord?.release()
            audioRecord = null
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🧹 AudioRecord resources released")
            }
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error releasing AudioRecord", e)
            }
        }
    }
    
    /**
     * Check if device supports required audio format
     * Equivalent to iOS audio format compatibility check
     */
    fun isAudioFormatSupported(): Boolean {
        val minBufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )
        
        val isSupported = minBufferSize != AudioRecord.ERROR_BAD_VALUE
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎵 Audio format supported: $isSupported (min buffer: $minBufferSize)")
        }
        
        return isSupported
    }
    
    /**
     * Get current recording state
     * Equivalent to iOS AVAudioEngine isRunning
     */
    val currentlyRecording: Boolean
        get() = isRecording && audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING
    
    /**
     * Cleanup resources when manager is destroyed
     */
    fun cleanup() {
        if (isRecording) {
            // Use runBlocking since this is cleanup - not ideal but necessary
            kotlinx.coroutines.runBlocking {
                stopRecording()
            }
        }
        releaseAudioRecord()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 AudioManager cleanup completed")
        }
    }
}