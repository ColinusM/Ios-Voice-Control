package com.voicecontrol.app.speech.service

import android.util.Log
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.di.WebSocketHttpClient
import com.voicecontrol.app.speech.model.TranscriptionResult
import com.voicecontrol.app.speech.model.StreamingConfig
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString.Companion.toByteString
import java.util.Base64
import javax.inject.Inject
import javax.inject.Singleton

/**
 * AssemblyAI Streaming Client for Voice Control App
 * 
 * Direct port of iOS AssemblyAIStreamer to Android using OkHttp WebSocket
 * Handles real-time speech-to-text transcription via AssemblyAI Streaming API
 * 
 * Features:
 * - Real-time WebSocket streaming (equivalent to iOS URLSessionWebSocketTask)
 * - PCM audio streaming with base64 encoding
 * - Configurable streaming parameters (language, punctuation, etc.)
 * - Connection state management with automatic reconnection
 * - Error handling and retry logic
 * - Transcription result streaming via Flow
 * - Professional logging and diagnostics
 */
@Singleton
class AssemblyAIStreamer @Inject constructor(
    @WebSocketHttpClient private val okHttpClient: OkHttpClient
) {
    
    companion object {
        private const val TAG = "AssemblyAIStreamer"
        private const val ASSEMBLYAI_STREAMING_URL = "wss://api.assemblyai.com/v2/realtime/ws"
        private const val MAX_RECONNECT_ATTEMPTS = 3
        private const val RECONNECT_DELAY_MS = 2000L
    }
    
    // WebSocket connection
    private var webSocket: WebSocket? = null
    private var isConnected = false
    private var reconnectAttempts = 0
    
    // Configuration
    private var currentConfig: StreamingConfig = StreamingConfig.default()
    
    // State flows for reactive UI updates
    private val _connectionState = MutableStateFlow(ConnectionState.Disconnected)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _isListening = MutableStateFlow(false)
    val isListening: StateFlow<Boolean> = _isListening.asStateFlow()
    
    // Transcription results channel
    private val transcriptionChannel = Channel<TranscriptionResult>(Channel.UNLIMITED)
    val transcriptionFlow: Flow<TranscriptionResult> = transcriptionChannel.receiveAsFlow()
    
    // JSON parser for WebSocket messages
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }
    
    /**
     * Connection states for the WebSocket
     * Equivalent to iOS WebSocket connection states
     */
    enum class ConnectionState {
        Disconnected,
        Connecting,
        Connected,
        Error
    }
    
    /**
     * Start streaming session with configuration
     * Equivalent to iOS startStreaming method
     */
    suspend fun startStreaming(config: StreamingConfig = StreamingConfig.default()): Boolean {
        if (isConnected) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Already connected to AssemblyAI")
            }
            return true
        }
        
        currentConfig = config
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 Starting AssemblyAI streaming session")
            Log.d(TAG, "📊 Config: $config")
        }
        
        return connectWebSocket()
    }
    
    /**
     * Stop streaming session
     * Equivalent to iOS stopStreaming method
     */
    suspend fun stopStreaming() {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🛑 Stopping AssemblyAI streaming session")
        }
        
        _isListening.value = false
        disconnectWebSocket()
    }
    
    /**
     * Send audio data to AssemblyAI
     * Equivalent to iOS sendAudioData method
     */
    fun sendAudioData(audioData: ByteArray, length: Int) {
        if (!isConnected || webSocket == null) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Cannot send audio - not connected")
            }
            return
        }
        
        try {
            // Encode audio data as base64 (AssemblyAI requirement)
            val audioBytes = audioData.copyOf(length)
            val base64Audio = Base64.getEncoder().encodeToString(audioBytes)
            
            val audioMessage = """
                {
                    "audio_data": "$base64Audio"
                }
            """.trimIndent()
            
            val success = webSocket?.send(audioMessage) ?: false
            
            if (!success && BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Failed to send audio data")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error sending audio data", e)
            }
        }
    }
    
    /**
     * Connect to AssemblyAI WebSocket
     * Equivalent to iOS WebSocket connection setup
     */
    private fun connectWebSocket(): Boolean {
        try {
            _connectionState.value = ConnectionState.Connecting
            
            val request = Request.Builder()
                .url(ASSEMBLYAI_STREAMING_URL)
                .addHeader("Authorization", BuildConfig.ASSEMBLYAI_API_KEY)
                .build()
            
            webSocket = okHttpClient.newWebSocket(request, AssemblyAIWebSocketListener())
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔗 Connecting to AssemblyAI WebSocket...")
            }
            
            return true
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error connecting to AssemblyAI", e)
            }
            _connectionState.value = ConnectionState.Error
            return false
        }
    }
    
    /**
     * Disconnect from AssemblyAI WebSocket
     * Equivalent to iOS WebSocket disconnection
     */
    private fun disconnectWebSocket() {
        try {
            webSocket?.close(1000, "Normal closure")
            webSocket = null
            isConnected = false
            _connectionState.value = ConnectionState.Disconnected
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔌 Disconnected from AssemblyAI")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error disconnecting from AssemblyAI", e)
            }
        }
    }
    
    /**
     * Send streaming configuration to AssemblyAI
     * Equivalent to iOS configuration message sending
     */
    private fun sendStreamingConfig() {
        val configMessage = """
            {
                "sample_rate": 16000,
                "language_code": "${currentConfig.languageCode}",
                "punctuate": ${currentConfig.enablePunctuation},
                "format_text": ${currentConfig.formatText},
                "enable_extra_session_information": true,
                "word_boost": ${json.encodeToString(kotlinx.serialization.builtins.ListSerializer(kotlinx.serialization.builtins.serializer()), currentConfig.wordBoost)}
            }
        """.trimIndent()
        
        val success = webSocket?.send(configMessage) ?: false
        
        if (BuildConfig.ENABLE_LOGGING) {
            if (success) {
                Log.d(TAG, "📤 Sent streaming configuration")
            } else {
                Log.w(TAG, "⚠️ Failed to send streaming configuration")
            }
        }
    }
    
    /**
     * Parse transcription message from AssemblyAI
     * Equivalent to iOS message parsing logic
     */
    private fun parseTranscriptionMessage(message: String) {
        try {
            val jsonElement = json.parseToJsonElement(message)
            val jsonObject = jsonElement.jsonObject
            
            val messageType = jsonObject["message_type"]?.jsonPrimitive?.content
            
            when (messageType) {
                "SessionBegins" -> {
                    handleSessionBegin(jsonObject)
                }
                
                "PartialTranscript" -> {
                    val text = jsonObject["text"]?.jsonPrimitive?.content ?: ""
                    val confidence = jsonObject["confidence"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: 0.0
                    
                    if (text.isNotEmpty()) {
                        val result = TranscriptionResult(
                            text = text,
                            isFinal = false,
                            confidence = confidence
                        )
                        
                        transcriptionChannel.trySend(result)
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.d(TAG, "📝 Partial: \"$text\" (${String.format("%.2f", confidence)})")
                        }
                    }
                }
                
                "FinalTranscript" -> {
                    val text = jsonObject["text"]?.jsonPrimitive?.content ?: ""
                    val confidence = jsonObject["confidence"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: 0.0
                    
                    if (text.isNotEmpty()) {
                        val result = TranscriptionResult(
                            text = text,
                            isFinal = true,
                            confidence = confidence
                        )
                        
                        transcriptionChannel.trySend(result)
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.d(TAG, "✅ Final: \"$text\" (${String.format("%.2f", confidence)})")
                        }
                    }
                }
                
                "SessionEnded" -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "🔚 AssemblyAI session ended")
                    }
                    _isListening.value = false
                }
                
                else -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.v(TAG, "📨 Unknown message type: $messageType")
                    }
                }
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error parsing transcription message", e)
            }
        }
    }
    
    /**
     * Handle session begin message
     * Equivalent to iOS session initialization
     */
    private fun handleSessionBegin(sessionInfo: kotlinx.serialization.json.JsonObject) {
        _isListening.value = true
        
        if (BuildConfig.ENABLE_LOGGING) {
            val sessionId = sessionInfo["session_id"]?.jsonPrimitive?.content ?: "unknown"
            Log.d(TAG, "🎬 AssemblyAI session started - ID: $sessionId")
        }
    }
    
    /**
     * WebSocket listener for AssemblyAI events
     * Equivalent to iOS URLSessionWebSocketDelegate
     */
    private inner class AssemblyAIWebSocketListener : WebSocketListener() {
        
        override fun onOpen(webSocket: WebSocket, response: Response) {
            super.onOpen(webSocket, response)
            
            isConnected = true
            reconnectAttempts = 0
            _connectionState.value = ConnectionState.Connected
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Connected to AssemblyAI WebSocket")
            }
            
            // Send configuration after connection
            sendStreamingConfig()
        }
        
        override fun onMessage(webSocket: WebSocket, text: String) {
            super.onMessage(webSocket, text)
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.v(TAG, "📨 Received message: $text")
            }
            
            parseTranscriptionMessage(text)
        }
        
        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            super.onFailure(webSocket, t, response)
            
            isConnected = false
            _connectionState.value = ConnectionState.Error
            _isListening.value = false
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ WebSocket connection failed", t)
                Log.e(TAG, "📊 Response: ${response?.code} ${response?.message}")
            }
            
            // Attempt reconnection if within retry limit
            if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
                attemptReconnection()
            }
        }
        
        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            super.onClosed(webSocket, code, reason)
            
            isConnected = false
            _connectionState.value = ConnectionState.Disconnected
            _isListening.value = false
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔌 WebSocket closed - Code: $code, Reason: $reason")
            }
        }
    }
    
    /**
     * Attempt reconnection with exponential backoff
     * Equivalent to iOS reconnection logic
     */
    private fun attemptReconnection() {
        if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Max reconnection attempts reached")
            }
            return
        }
        
        reconnectAttempts++
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Attempting reconnection ($reconnectAttempts/$MAX_RECONNECT_ATTEMPTS)")
        }
        
        // Use a simple thread for reconnection delay (not ideal but functional)
        Thread {
            try {
                Thread.sleep(RECONNECT_DELAY_MS * reconnectAttempts) // Exponential backoff
                connectWebSocket()
            } catch (e: InterruptedException) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ Reconnection interrupted")
                }
            }
        }.start()
    }
    
    /**
     * Cleanup resources when streamer is destroyed
     */
    fun cleanup() {
        if (isConnected) {
            disconnectWebSocket()
        }
        transcriptionChannel.close()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 AssemblyAI streamer cleanup completed")
        }
    }
}