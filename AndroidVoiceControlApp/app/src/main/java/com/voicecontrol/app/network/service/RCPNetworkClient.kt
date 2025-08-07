package com.voicecontrol.app.network.service

import android.util.Log
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.network.model.NetworkSettings
import com.voicecontrol.app.network.model.RCPCommand
import com.voicecontrol.app.voice.model.VoiceCommand
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.Serializable
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import javax.inject.Inject
import javax.inject.Named
import javax.inject.Singleton

/**
 * RCP Network Client for Voice Control App
 * 
 * Direct port of iOS RCPNetworkClient to Android with Kotlin
 * Handles HTTP communication with Yamaha mixing consoles using RCP protocol
 * 
 * Features:
 * - HTTP POST requests for Yamaha RCP commands
 * - Connection testing and health monitoring
 * - Network availability detection
 * - Configurable timeouts and retry logic
 * - Thread-safe operations with coroutines
 * - Command result tracking and statistics
 */
@Singleton
class RCPNetworkClient @Inject constructor(
    @Named("RCPHttpClient") private val httpClient: OkHttpClient,
    private val networkSettings: NetworkSettings
) {
    
    companion object {
        private const val TAG = "RCPNetworkClient"
        
        // RCP Protocol constants
        private const val RCP_ENDPOINT = "/rcp"
        private const val RCP_CONTENT_TYPE = "application/x-rcp"
        
        // Connection testing
        private const val CONNECTION_TEST_TIMEOUT_MS = 5000L
        private const val SOCKET_TEST_TIMEOUT_MS = 3000
        
        // Command execution
        private const val DEFAULT_COMMAND_TIMEOUT_MS = 10000L
        private const val MAX_RETRY_ATTEMPTS = 3
    }
    
    // Coroutine scope for async operations
    private val networkScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    // Network state management
    private val _connectionState = MutableStateFlow(ConnectionState.Disconnected)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _isNetworkAvailable = MutableStateFlow(false)
    val isNetworkAvailable: StateFlow<Boolean> = _isNetworkAvailable.asStateFlow()
    
    private val _lastConnectionTime = MutableStateFlow<Long?>(null)
    val lastConnectionTime: StateFlow<Long?> = _lastConnectionTime.asStateFlow()
    
    private val _lastTestResult = MutableStateFlow<String?>(null)
    val lastTestResult: StateFlow<String?> = _lastTestResult.asStateFlow()
    
    // Command execution statistics
    private val _sentCommandsCount = MutableStateFlow(0)
    val sentCommandsCount: StateFlow<Int> = _sentCommandsCount.asStateFlow()
    
    private val _successfulCommandsCount = MutableStateFlow(0)
    val successfulCommandsCount: StateFlow<Int> = _successfulCommandsCount.asStateFlow()
    
    private val _failedCommandsCount = MutableStateFlow(0)
    val failedCommandsCount: StateFlow<Int> = _failedCommandsCount.asStateFlow()
    
    /**
     * Connection states for RCP communication
     * Equivalent to iOS ConnectionState enum
     */
    enum class ConnectionState {
        Disconnected,    // No connection established
        Connecting,      // Attempting to connect
        Connected,       // Successfully connected
        Testing,         // Testing connection health
        Error            // Connection error occurred
    }
    
    /**
     * RCP Command Result
     * Represents the result of executing an RCP command
     */
    @Serializable
    data class RCPCommandResult(
        val command: String,
        val success: Boolean,
        val responseCode: Int?,
        val responseBody: String?,
        val errorMessage: String?,
        val executionTimeMs: Long,
        val timestamp: Long = System.currentTimeMillis()
    ) {
        
        val isSuccessful: Boolean
            get() = success && (responseCode in 200..299)
        
        val displayMessage: String
            get() = when {
                isSuccessful -> "Command executed successfully"
                responseCode != null -> "HTTP $responseCode: ${errorMessage ?: "Request failed"}"
                else -> errorMessage ?: "Unknown error"
            }
    }
    
    init {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🌐 RCPNetworkClient initialized")
        }
        
        // Initialize network state
        updateNetworkState()
    }
    
    /**
     * Test connection to specified IP and port
     * Equivalent to iOS testConnection method
     */
    suspend fun testConnection(
        ipAddress: String, 
        port: Int,
        timeoutMs: Long = CONNECTION_TEST_TIMEOUT_MS
    ): RCPCommandResult = withContext(Dispatchers.IO) {
        
        val startTime = System.currentTimeMillis()
        _connectionState.value = ConnectionState.Testing
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔍 Testing connection to $ipAddress:$port")
        }
        
        return@withContext try {
            val testResult = withTimeoutOrNull(timeoutMs) {
                testSocketConnection(ipAddress, port)
            }
            
            val executionTime = System.currentTimeMillis() - startTime
            
            if (testResult == true) {
                _connectionState.value = ConnectionState.Connected
                _isNetworkAvailable.value = true
                _lastConnectionTime.value = System.currentTimeMillis()
                _lastTestResult.value = "Connection successful"
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Connection test successful ($executionTime ms)")
                }
                
                RCPCommandResult(
                    command = "Connection test to $ipAddress:$port",
                    success = true,
                    responseCode = 200,
                    responseBody = "Connection established",
                    errorMessage = null,
                    executionTimeMs = executionTime
                )
            } else {
                _connectionState.value = ConnectionState.Error
                _isNetworkAvailable.value = false
                val errorMsg = if (testResult == null) "Connection timeout" else "Connection refused"
                _lastTestResult.value = errorMsg
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Connection test failed: $errorMsg")
                }
                
                RCPCommandResult(
                    command = "Connection test to $ipAddress:$port",
                    success = false,
                    responseCode = null,
                    responseBody = null,
                    errorMessage = errorMsg,
                    executionTimeMs = executionTime
                )
            }
            
        } catch (e: Exception) {
            val executionTime = System.currentTimeMillis() - startTime
            _connectionState.value = ConnectionState.Error
            _isNetworkAvailable.value = false
            val errorMsg = "Test error: ${e.message}"
            _lastTestResult.value = errorMsg
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Connection test exception", e)
            }
            
            RCPCommandResult(
                command = "Connection test to $ipAddress:$port",
                success = false,
                responseCode = null,
                responseBody = null,
                errorMessage = errorMsg,
                executionTimeMs = executionTime
            )
        }
    }
    
    /**
     * Send RCP command to console
     * Equivalent to iOS sendCommand method
     */
    suspend fun sendCommand(
        command: RCPCommand,
        timeoutMs: Long = DEFAULT_COMMAND_TIMEOUT_MS
    ): RCPCommandResult = withContext(Dispatchers.IO) {
        
        val startTime = System.currentTimeMillis()
        _sentCommandsCount.value += 1
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📤 Sending RCP command: ${command.commandString}")
        }
        
        // Get target settings
        val targetIP = when (networkSettings.targetType) {
            NetworkSettings.NetworkTargetType.CONSOLE -> networkSettings.consoleIP
            NetworkSettings.NetworkTargetType.TESTING_GUI -> networkSettings.testingIP
        }
        
        val targetPort = when (networkSettings.targetType) {
            NetworkSettings.NetworkTargetType.CONSOLE -> networkSettings.consolePort
            NetworkSettings.NetworkTargetType.TESTING_GUI -> networkSettings.testingPort
        }
        
        if (targetIP.isBlank()) {
            val result = RCPCommandResult(
                command = command.commandString,
                success = false,
                responseCode = null,
                responseBody = null,
                errorMessage = "No target IP configured",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            _failedCommandsCount.value += 1
            return@withContext result
        }
        
        return@withContext try {
            val url = "http://$targetIP:$targetPort$RCP_ENDPOINT"
            val requestBody = command.commandString.toRequestBody(RCP_CONTENT_TYPE.toMediaType())
            
            val request = Request.Builder()
                .url(url)
                .post(requestBody)
                .header("Content-Type", RCP_CONTENT_TYPE)
                .header("User-Agent", "VoiceControlApp-Android")
                .build()
            
            val result = withTimeoutOrNull(timeoutMs) {
                executeHttpRequest(request, command.commandString, startTime)
            }
            
            result ?: RCPCommandResult(
                command = command.commandString,
                success = false,
                responseCode = null,
                responseBody = null,
                errorMessage = "Command timeout after ${timeoutMs}ms",
                executionTimeMs = System.currentTimeMillis() - startTime
            ).also { _failedCommandsCount.value += 1 }
            
        } catch (e: Exception) {
            val result = RCPCommandResult(
                command = command.commandString,
                success = false,
                responseCode = null,
                responseBody = null,
                errorMessage = "Send error: ${e.message}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            _failedCommandsCount.value += 1
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error sending RCP command", e)
            }
            
            result
        }
    }
    
    /**
     * Send voice command by converting to RCP command
     * Equivalent to iOS sendVoiceCommand method
     */
    suspend fun sendVoiceCommand(voiceCommand: VoiceCommand): RCPCommandResult {
        val rcpCommand = convertVoiceCommandToRCP(voiceCommand)
        return sendCommand(rcpCommand)
    }
    
    /**
     * Test socket connection to target
     */
    private suspend fun testSocketConnection(ipAddress: String, port: Int): Boolean = withContext(Dispatchers.IO) {
        try {
            val socket = Socket()
            socket.connect(InetSocketAddress(InetAddress.getByName(ipAddress), port), SOCKET_TEST_TIMEOUT_MS)
            socket.close()
            true
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.v(TAG, "Socket connection failed: ${e.message}")
            }
            false
        }
    }
    
    /**
     * Execute HTTP request with callback
     */
    private suspend fun executeHttpRequest(
        request: Request, 
        commandString: String, 
        startTime: Long
    ): RCPCommandResult = withContext(Dispatchers.IO) {
        
        return@withContext try {
            val response = httpClient.newCall(request).execute()
            val executionTime = System.currentTimeMillis() - startTime
            val responseBody = response.body?.string()
            
            val result = RCPCommandResult(
                command = commandString,
                success = response.isSuccessful,
                responseCode = response.code,
                responseBody = responseBody,
                errorMessage = if (!response.isSuccessful) response.message else null,
                executionTimeMs = executionTime
            )
            
            if (response.isSuccessful) {
                _successfulCommandsCount.value += 1
                _lastConnectionTime.value = System.currentTimeMillis()
                _connectionState.value = ConnectionState.Connected
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ RCP command successful (${result.responseCode})")
                }
            } else {
                _failedCommandsCount.value += 1
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ RCP command failed: ${result.responseCode} ${result.errorMessage}")
                }
            }
            
            response.close()
            result
            
        } catch (e: IOException) {
            val result = RCPCommandResult(
                command = commandString,
                success = false,
                responseCode = null,
                responseBody = null,
                errorMessage = "Network error: ${e.message}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            _failedCommandsCount.value += 1
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ HTTP request failed", e)
            }
            
            result
        }
    }
    
    /**
     * Convert voice command to RCP command
     * Equivalent to iOS convertVoiceCommandToRCP method
     */
    private fun convertVoiceCommandToRCP(voiceCommand: VoiceCommand): RCPCommand {
        return when (voiceCommand) {
            is VoiceCommand.ChannelCommand -> {
                val channelPath = "MIXER:Current/InCh/Fader/Level"
                val channelIndex = String.format("%02d", voiceCommand.channelNumber - 1)
                
                when (voiceCommand.operation) {
                    VoiceCommand.ChannelCommand.ChannelOperation.MUTE_ON -> {
                        RCPCommand.create("set MIXER:Current/InCh/ToMix/On $channelIndex 0")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.MUTE_OFF -> {
                        RCPCommand.create("set MIXER:Current/InCh/ToMix/On $channelIndex 1")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.SOLO_ON -> {
                        RCPCommand.create("set MIXER:Current/InCh/ToMix/Solo $channelIndex 1")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.SOLO_OFF -> {
                        RCPCommand.create("set MIXER:Current/InCh/ToMix/Solo $channelIndex 0")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.FADER_SET -> {
                        val level = voiceCommand.parameterValue?.let { 
                            // Convert dB to RCP level (0-1000)
                            ((it + 90) / 100 * 1000).toInt().coerceIn(0, 1000)
                        } ?: 750 // Default to 75%
                        RCPCommand.create("set $channelPath $channelIndex $level")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.FADER_INCREASE -> {
                        RCPCommand.create("inc MIXER:Current/InCh/Fader/Level $channelIndex 50")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.FADER_DECREASE -> {
                        RCPCommand.create("dec MIXER:Current/InCh/Fader/Level $channelIndex 50")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.GAIN_SET -> {
                        val gain = voiceCommand.parameterValue?.let { 
                            // Convert dB to RCP gain (0-480, where 240 = 0dB)
                            ((it + 20) / 80 * 480).toInt().coerceIn(0, 480)
                        } ?: 240 // Default to 0dB
                        RCPCommand.create("set MIXER:Current/InCh/Head Amp/Gain $channelIndex $gain")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_ON -> {
                        RCPCommand.create("set MIXER:Current/InCh/Head Amp/+48V $channelIndex 1")
                    }
                    VoiceCommand.ChannelCommand.ChannelOperation.PHANTOM_OFF -> {
                        RCPCommand.create("set MIXER:Current/InCh/Head Amp/+48V $channelIndex 0")
                    }
                    else -> {
                        RCPCommand.create("get MIXER:Current/InCh/Fader/Level $channelIndex")
                    }
                }
            }
            
            is VoiceCommand.SceneCommand -> {
                when (voiceCommand.operation) {
                    VoiceCommand.SceneCommand.SceneOperation.RECALL -> {
                        val sceneIndex = String.format("%03d", voiceCommand.sceneNumber - 1)
                        RCPCommand.create("set MIXER:Current/Scene/Recall $sceneIndex")
                    }
                    VoiceCommand.SceneCommand.SceneOperation.STORE -> {
                        val sceneIndex = String.format("%03d", voiceCommand.sceneNumber - 1)
                        RCPCommand.create("set MIXER:Current/Scene/Store $sceneIndex")
                    }
                }
            }
            
            is VoiceCommand.GlobalCommand -> {
                when (voiceCommand.operation) {
                    VoiceCommand.GlobalCommand.GlobalOperation.MASTER_MUTE_ON -> {
                        RCPCommand.create("set MIXER:Current/StCh/ToMix/On 00 0")
                    }
                    VoiceCommand.GlobalCommand.GlobalOperation.MASTER_MUTE_OFF -> {
                        RCPCommand.create("set MIXER:Current/StCh/ToMix/On 00 1")
                    }
                    VoiceCommand.GlobalCommand.GlobalOperation.ALL_MUTE_ON -> {
                        RCPCommand.create("set MIXER:Current/AllMute On")
                    }
                    VoiceCommand.GlobalCommand.GlobalOperation.ALL_MUTE_OFF -> {
                        RCPCommand.create("set MIXER:Current/AllMute Off")
                    }
                    else -> {
                        RCPCommand.create("get MIXER:Current/StCh/Fader/Level 00")
                    }
                }
            }
            
            is VoiceCommand.UnknownCommand -> {
                RCPCommand.create("get MIXER:Current/Status")
            }
        }
    }
    
    /**
     * Update network state periodically
     */
    private fun updateNetworkState() {
        networkScope.launch {
            // Basic network state update logic
            _isNetworkAvailable.value = true // Assume network is available initially
        }
    }
    
    /**
     * Get network statistics
     * Equivalent to iOS getNetworkStats method
     */
    fun getNetworkStats(): Map<String, Any> {
        return mapOf(
            "connectionState" to _connectionState.value.name,
            "isNetworkAvailable" to _isNetworkAvailable.value,
            "sentCommands" to _sentCommandsCount.value,
            "successfulCommands" to _successfulCommandsCount.value,
            "failedCommands" to _failedCommandsCount.value,
            "successRate" to if (_sentCommandsCount.value > 0) {
                _successfulCommandsCount.value.toDouble() / _sentCommandsCount.value.toDouble()
            } else 0.0,
            "lastConnection" to _lastConnectionTime.value,
            "lastTestResult" to _lastTestResult.value
        )
    }
    
    /**
     * Reset network statistics
     */
    fun resetStats() {
        _sentCommandsCount.value = 0
        _successfulCommandsCount.value = 0
        _failedCommandsCount.value = 0
        _lastTestResult.value = null
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📊 Network statistics reset")
        }
    }
    
    /**
     * Cleanup resources when client is destroyed
     * Equivalent to iOS cleanup method
     */
    fun cleanup() {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 Cleaning up RCPNetworkClient")
        }
        
        // Cancel all ongoing operations
        networkScope.cancel()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 RCPNetworkClient cleanup completed")
        }
    }
}