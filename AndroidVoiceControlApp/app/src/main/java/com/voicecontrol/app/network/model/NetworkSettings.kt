package com.voicecontrol.app.network.model

import android.content.SharedPreferences
import android.util.Log
import com.voicecontrol.app.BuildConfig
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import javax.inject.Inject
import javax.inject.Named
import javax.inject.Singleton

/**
 * Network Settings Model for Voice Control App
 * 
 * Direct port of iOS NetworkSettings to Android with Kotlin
 * Manages network configuration for RCP communication with mixers
 * 
 * Features:
 * - IP address and port configuration for console and testing
 * - Target selection (console vs. testing GUI)
 * - Connection timeout and retry settings
 * - Network logging preferences
 * - Settings persistence with SharedPreferences
 * - Reactive state updates with StateFlow
 */
@Singleton
class NetworkSettings @Inject constructor(
    @Named("settings") private val sharedPreferences: SharedPreferences
) {
    
    companion object {
        private const val TAG = "NetworkSettings"
        
        // SharedPreferences keys
        private const val PREF_CONSOLE_IP = "network_console_ip"
        private const val PREF_CONSOLE_PORT = "network_console_port"
        private const val PREF_TESTING_IP = "network_testing_ip"
        private const val PREF_TESTING_PORT = "network_testing_port"
        private const val PREF_TARGET_TYPE = "network_target_type"
        private const val PREF_CONNECTION_STATUS = "network_connection_status"
        private const val PREF_TIMEOUT_SECONDS = "network_timeout_seconds"
        private const val PREF_ENABLE_LOGGING = "network_enable_logging"
        private const val PREF_LAST_CONNECTION_TIME = "network_last_connection_time"
        
        // Default values
        private const val DEFAULT_CONSOLE_IP = "192.168.1.100"
        private const val DEFAULT_CONSOLE_PORT = 49280
        private const val DEFAULT_TESTING_IP = "192.168.1.200"
        private const val DEFAULT_TESTING_PORT = 8080
        private const val DEFAULT_TIMEOUT_SECONDS = 10
        private const val DEFAULT_ENABLE_LOGGING = true
    }
    
    /**
     * Network target types
     * Equivalent to iOS NetworkTargetType enum
     */
    @Serializable
    enum class NetworkTargetType(val displayName: String) {
        CONSOLE("Yamaha Console"),
        TESTING_GUI("Mac GUI");
        
        companion object {
            val allCases: List<NetworkTargetType> = values().toList()
        }
    }
    
    /**
     * Connection status types
     * Equivalent to iOS ConnectionStatus enum
     */
    @Serializable
    enum class ConnectionStatus(val displayName: String) {
        DISCONNECTED("Disconnected"),
        CONNECTING("Connecting..."),
        CONNECTED("Connected"),
        ERROR("Connection Error");
        
        val isConnected: Boolean
            get() = this == CONNECTED
        
        val isError: Boolean
            get() = this == ERROR
    }
    
    // State flows for reactive UI updates
    private val _consoleIP = MutableStateFlow(loadConsoleIP())
    val consoleIPFlow: StateFlow<String> = _consoleIP.asStateFlow()
    
    private val _consolePort = MutableStateFlow(loadConsolePort())
    val consolePortFlow: StateFlow<Int> = _consolePort.asStateFlow()
    
    private val _testingIP = MutableStateFlow(loadTestingIP())
    val testingIPFlow: StateFlow<String> = _testingIP.asStateFlow()
    
    private val _testingPort = MutableStateFlow(loadTestingPort())
    val testingPortFlow: StateFlow<Int> = _testingPort.asStateFlow()
    
    private val _targetType = MutableStateFlow(loadTargetType())
    val targetTypeFlow: StateFlow<NetworkTargetType> = _targetType.asStateFlow()
    
    private val _connectionStatus = MutableStateFlow(loadConnectionStatus())
    val connectionStatusFlow: StateFlow<ConnectionStatus> = _connectionStatus.asStateFlow()
    
    private val _timeoutSeconds = MutableStateFlow(loadTimeoutSeconds())
    val timeoutSecondsFlow: StateFlow<Int> = _timeoutSeconds.asStateFlow()
    
    private val _enableLogging = MutableStateFlow(loadEnableLogging())
    val enableLoggingFlow: StateFlow<Boolean> = _enableLogging.asStateFlow()
    
    private val _lastConnectionTime = MutableStateFlow(loadLastConnectionTime())
    val lastConnectionTimeFlow: StateFlow<Long?> = _lastConnectionTime.asStateFlow()
    
    init {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🌐 NetworkSettings initialized")
            Log.d(TAG, "📊 Current settings: ${getCurrentSettingsSummary()}")
        }
    }
    
    /**
     * Console IP address
     * Equivalent to iOS consoleIP property
     */
    var consoleIP: String
        get() = _consoleIP.value
        set(value) {
            if (value != _consoleIP.value) {
                sharedPreferences.edit().putString(PREF_CONSOLE_IP, value).apply()
                _consoleIP.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🖥️ Console IP updated: $value")
                }
            }
        }
    
    /**
     * Console port number
     * Equivalent to iOS consolePort property
     */
    var consolePort: Int
        get() = _consolePort.value
        set(value) {
            if (value != _consolePort.value) {
                sharedPreferences.edit().putInt(PREF_CONSOLE_PORT, value).apply()
                _consolePort.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔌 Console port updated: $value")
                }
            }
        }
    
    /**
     * Testing GUI IP address
     * Equivalent to iOS testingIP property
     */
    var testingIP: String
        get() = _testingIP.value
        set(value) {
            if (value != _testingIP.value) {
                sharedPreferences.edit().putString(PREF_TESTING_IP, value).apply()
                _testingIP.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🧪 Testing IP updated: $value")
                }
            }
        }
    
    /**
     * Testing GUI port number
     * Equivalent to iOS testingPort property
     */
    var testingPort: Int
        get() = _testingPort.value
        set(value) {
            if (value != _testingPort.value) {
                sharedPreferences.edit().putInt(PREF_TESTING_PORT, value).apply()
                _testingPort.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔧 Testing port updated: $value")
                }
            }
        }
    
    /**
     * Target type selection
     * Equivalent to iOS targetType property
     */
    var targetType: NetworkTargetType
        get() = _targetType.value
        set(value) {
            if (value != _targetType.value) {
                sharedPreferences.edit().putString(PREF_TARGET_TYPE, value.name).apply()
                _targetType.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🎯 Target type updated: ${value.displayName}")
                }
            }
        }
    
    /**
     * Connection status
     * Equivalent to iOS connectionStatus property
     */
    var connectionStatus: ConnectionStatus
        get() = _connectionStatus.value
        set(value) {
            if (value != _connectionStatus.value) {
                sharedPreferences.edit().putString(PREF_CONNECTION_STATUS, value.name).apply()
                _connectionStatus.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔗 Connection status updated: ${value.displayName}")
                }
            }
        }
    
    /**
     * Connection timeout in seconds
     * Equivalent to iOS timeoutSeconds property
     */
    var timeoutSeconds: Int
        get() = _timeoutSeconds.value
        set(value) {
            if (value != _timeoutSeconds.value && value > 0) {
                sharedPreferences.edit().putInt(PREF_TIMEOUT_SECONDS, value).apply()
                _timeoutSeconds.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "⏱️ Timeout updated: ${value}s")
                }
            }
        }
    
    /**
     * Enable network logging
     * Equivalent to iOS enableLogging property
     */
    var enableLogging: Boolean
        get() = _enableLogging.value
        set(value) {
            if (value != _enableLogging.value) {
                sharedPreferences.edit().putBoolean(PREF_ENABLE_LOGGING, value).apply()
                _enableLogging.value = value
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "📝 Logging ${if (value) "enabled" else "disabled"}")
                }
            }
        }
    
    /**
     * Last successful connection time
     * Equivalent to iOS lastConnectionTime property
     */
    var lastConnectionTime: Long?
        get() = _lastConnectionTime.value
        set(value) {
            val timestamp = value ?: 0L
            sharedPreferences.edit().putLong(PREF_LAST_CONNECTION_TIME, timestamp).apply()
            _lastConnectionTime.value = if (timestamp > 0L) timestamp else null
            
            if (BuildConfig.ENABLE_LOGGING && value != null) {
                Log.d(TAG, "⏰ Last connection time updated: ${java.util.Date(value)}")
            }
        }
    
    /**
     * Get current target IP based on target type
     * Equivalent to iOS currentTargetIP computed property
     */
    val currentTargetIP: String
        get() = when (targetType) {
            NetworkTargetType.CONSOLE -> consoleIP
            NetworkTargetType.TESTING_GUI -> testingIP
        }
    
    /**
     * Get current target port based on target type
     * Equivalent to iOS currentTargetPort computed property
     */
    val currentTargetPort: Int
        get() = when (targetType) {
            NetworkTargetType.CONSOLE -> consolePort
            NetworkTargetType.TESTING_GUI -> testingPort
        }
    
    /**
     * Get current target URL
     * Equivalent to iOS currentTargetURL computed property
     */
    val currentTargetURL: String
        get() = "http://$currentTargetIP:$currentTargetPort"
    
    /**
     * Check if current settings are valid
     * Equivalent to iOS isValidConfiguration computed property
     */
    val isValidConfiguration: Boolean
        get() = currentTargetIP.isNotBlank() && 
                currentTargetPort in 1..65535 &&
                timeoutSeconds > 0 &&
                isValidIPAddress(currentTargetIP)
    
    /**
     * Save all current settings to SharedPreferences
     * Equivalent to iOS saveSettings method
     */
    fun saveSettings() {
        sharedPreferences.edit().apply {
            putString(PREF_CONSOLE_IP, consoleIP)
            putInt(PREF_CONSOLE_PORT, consolePort)
            putString(PREF_TESTING_IP, testingIP)
            putInt(PREF_TESTING_PORT, testingPort)
            putString(PREF_TARGET_TYPE, targetType.name)
            putString(PREF_CONNECTION_STATUS, connectionStatus.name)
            putInt(PREF_TIMEOUT_SECONDS, timeoutSeconds)
            putBoolean(PREF_ENABLE_LOGGING, enableLogging)
            lastConnectionTime?.let { putLong(PREF_LAST_CONNECTION_TIME, it) }
        }.apply()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "💾 Settings saved: ${getCurrentSettingsSummary()}")
        }
    }
    
    /**
     * Reset settings to default values
     * Equivalent to iOS resetToDefaults method
     */
    fun resetToDefaults() {
        consoleIP = DEFAULT_CONSOLE_IP
        consolePort = DEFAULT_CONSOLE_PORT
        testingIP = DEFAULT_TESTING_IP
        testingPort = DEFAULT_TESTING_PORT
        targetType = NetworkTargetType.CONSOLE
        connectionStatus = ConnectionStatus.DISCONNECTED
        timeoutSeconds = DEFAULT_TIMEOUT_SECONDS
        enableLogging = DEFAULT_ENABLE_LOGGING
        lastConnectionTime = null
        
        saveSettings()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Settings reset to defaults")
        }
    }
    
    /**
     * Get timeout in milliseconds
     * Equivalent to iOS timeoutMs computed property
     */
    val timeoutMs: Long
        get() = timeoutSeconds * 1000L
    
    /**
     * Validate IP address format
     */
    private fun isValidIPAddress(ip: String): Boolean {
        if (ip.isBlank()) return false
        
        val parts = ip.split(".")
        if (parts.size != 4) return false
        
        return parts.all { part ->
            try {
                val num = part.toInt()
                num in 0..255
            } catch (e: NumberFormatException) {
                false
            }
        }
    }
    
    /**
     * Get current settings summary for logging
     */
    private fun getCurrentSettingsSummary(): String {
        return "Target: ${targetType.displayName}, " +
               "IP: $currentTargetIP:$currentTargetPort, " +
               "Timeout: ${timeoutSeconds}s, " +
               "Status: ${connectionStatus.displayName}"
    }
    
    // Private getters for initialization
    private fun loadConsoleIP(): String {
        return sharedPreferences.getString(PREF_CONSOLE_IP, DEFAULT_CONSOLE_IP) ?: DEFAULT_CONSOLE_IP
    }
    
    private fun loadConsolePort(): Int {
        return sharedPreferences.getInt(PREF_CONSOLE_PORT, DEFAULT_CONSOLE_PORT)
    }
    
    private fun loadTestingIP(): String {
        return sharedPreferences.getString(PREF_TESTING_IP, DEFAULT_TESTING_IP) ?: DEFAULT_TESTING_IP
    }
    
    private fun loadTestingPort(): Int {
        return sharedPreferences.getInt(PREF_TESTING_PORT, DEFAULT_TESTING_PORT)
    }
    
    private fun loadTargetType(): NetworkTargetType {
        val typeName = sharedPreferences.getString(PREF_TARGET_TYPE, NetworkTargetType.CONSOLE.name)
        return try {
            NetworkTargetType.valueOf(typeName ?: NetworkTargetType.CONSOLE.name)
        } catch (e: IllegalArgumentException) {
            NetworkTargetType.CONSOLE
        }
    }
    
    private fun loadConnectionStatus(): ConnectionStatus {
        val statusName = sharedPreferences.getString(PREF_CONNECTION_STATUS, ConnectionStatus.DISCONNECTED.name)
        return try {
            ConnectionStatus.valueOf(statusName ?: ConnectionStatus.DISCONNECTED.name)
        } catch (e: IllegalArgumentException) {
            ConnectionStatus.DISCONNECTED
        }
    }
    
    private fun loadTimeoutSeconds(): Int {
        return sharedPreferences.getInt(PREF_TIMEOUT_SECONDS, DEFAULT_TIMEOUT_SECONDS)
    }
    
    private fun loadEnableLogging(): Boolean {
        return sharedPreferences.getBoolean(PREF_ENABLE_LOGGING, DEFAULT_ENABLE_LOGGING)
    }
    
    private fun loadLastConnectionTime(): Long? {
        val timestamp = sharedPreferences.getLong(PREF_LAST_CONNECTION_TIME, 0L)
        return if (timestamp > 0L) timestamp else null
    }
}