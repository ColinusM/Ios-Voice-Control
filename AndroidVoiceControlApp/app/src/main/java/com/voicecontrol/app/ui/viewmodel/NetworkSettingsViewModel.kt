package com.voicecontrol.app.ui.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.network.model.NetworkSettings
import com.voicecontrol.app.network.service.RCPNetworkClient
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Network Settings ViewModel for Voice Control App
 * 
 * Direct port of iOS NetworkSettingsViewModel to Android MVVM
 * Manages network configuration state and operations
 * 
 * Features:
 * - Reactive UI state with StateFlow
 * - Network settings persistence
 * - Connection testing coordination
 * - Real-time status updates
 * - Input validation and error handling
 * - MVVM architecture pattern with Hilt DI
 */
@HiltViewModel
class NetworkSettingsViewModel @Inject constructor(
    private val networkSettings: NetworkSettings,
    private val rcpNetworkClient: RCPNetworkClient
) : ViewModel() {
    
    companion object {
        private const val TAG = "NetworkSettingsViewModel"
    }
    
    /**
     * UI State for Network Settings Screen
     * Equivalent to iOS NetworkSettingsState
     */
    data class NetworkSettingsUiState(
        // Network configuration
        val consoleIP: String = "",
        val consolePort: Int = 49280,
        val testingIP: String = "",
        val testingPort: Int = 8080,
        val targetType: NetworkSettings.NetworkTargetType = NetworkSettings.NetworkTargetType.CONSOLE,
        val timeoutSeconds: Int = 10,
        val enableLogging: Boolean = true,
        
        // Connection status
        val connectionStatus: NetworkSettings.ConnectionStatus = NetworkSettings.ConnectionStatus.DISCONNECTED,
        val isNetworkAvailable: Boolean = false,
        val lastConnectionTime: Long? = null,
        val testResult: String? = null,
        val isTestingConnection: Boolean = false,
        
        // Validation
        val isValidConfiguration: Boolean = true,
        val hasUnsavedChanges: Boolean = false
    )
    
    // Internal state flows from NetworkSettings
    private val consoleIPFlow = networkSettings.consoleIPFlow
    private val consolePortFlow = networkSettings.consolePortFlow
    private val testingIPFlow = networkSettings.testingIPFlow
    private val testingPortFlow = networkSettings.testingPortFlow
    private val targetTypeFlow = networkSettings.targetTypeFlow
    private val connectionStatusFlow = networkSettings.connectionStatusFlow
    private val timeoutSecondsFlow = networkSettings.timeoutSecondsFlow
    private val enableLoggingFlow = networkSettings.enableLoggingFlow
    private val lastConnectionTimeFlow = networkSettings.lastConnectionTimeFlow
    
    // RCP Client state flows
    private val isNetworkAvailableFlow = rcpNetworkClient.isNetworkAvailable
    private val lastTestResultFlow = rcpNetworkClient.lastTestResult
    
    // Testing state
    private val _isTestingConnection = MutableStateFlow(false)
    
    // Combined UI state
    val uiState: StateFlow<NetworkSettingsUiState> = combine(
        consoleIPFlow,
        consolePortFlow,
        testingIPFlow,
        testingPortFlow,
        targetTypeFlow,
        connectionStatusFlow,
        timeoutSecondsFlow,
        enableLoggingFlow,
        lastConnectionTimeFlow,
        isNetworkAvailableFlow,
        lastTestResultFlow,
        _isTestingConnection
    ) { flows ->
        NetworkSettingsUiState(
            consoleIP = flows[0] as String,
            consolePort = flows[1] as Int,
            testingIP = flows[2] as String,
            testingPort = flows[3] as Int,
            targetType = flows[4] as NetworkSettings.NetworkTargetType,
            connectionStatus = flows[5] as NetworkSettings.ConnectionStatus,
            timeoutSeconds = flows[6] as Int,
            enableLogging = flows[7] as Boolean,
            lastConnectionTime = flows[8] as Long?,
            isNetworkAvailable = flows[9] as Boolean,
            testResult = flows[10] as String?,
            isTestingConnection = flows[11] as Boolean,
            isValidConfiguration = networkSettings.isValidConfiguration,
            hasUnsavedChanges = false // Could implement change detection if needed
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = NetworkSettingsUiState()
    )
    
    init {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🌐 NetworkSettingsViewModel initialized")
        }
    }
    
    /**
     * Set console IP address
     * Equivalent to iOS setConsoleIP method
     */
    fun setConsoleIP(ip: String) {
        networkSettings.consoleIP = ip
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🖥️ Console IP updated: $ip")
        }
    }
    
    /**
     * Set console port
     * Equivalent to iOS setConsolePort method
     */
    fun setConsolePort(port: Int) {
        if (port in 1..65535) {
            networkSettings.consolePort = port
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔌 Console port updated: $port")
            }
        }
    }
    
    /**
     * Set testing IP address
     * Equivalent to iOS setTestingIP method
     */
    fun setTestingIP(ip: String) {
        networkSettings.testingIP = ip
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧪 Testing IP updated: $ip")
        }
    }
    
    /**
     * Set testing port
     * Equivalent to iOS setTestingPort method
     */
    fun setTestingPort(port: Int) {
        if (port in 1..65535) {
            networkSettings.testingPort = port
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔧 Testing port updated: $port")
            }
        }
    }
    
    /**
     * Set target type
     * Equivalent to iOS setTargetType method
     */
    fun setTargetType(targetType: NetworkSettings.NetworkTargetType) {
        networkSettings.targetType = targetType
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎯 Target type updated: ${targetType.displayName}")
        }
    }
    
    /**
     * Set connection timeout
     * Equivalent to iOS setTimeoutSeconds method
     */
    fun setTimeoutSeconds(seconds: Int) {
        if (seconds > 0) {
            networkSettings.timeoutSeconds = seconds
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "⏱️ Timeout updated: ${seconds}s")
            }
        }
    }
    
    /**
     * Set network logging preference
     * Equivalent to iOS setEnableLogging method
     */
    fun setEnableLogging(enabled: Boolean) {
        networkSettings.enableLogging = enabled
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📝 Logging ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Test connection to current target
     * Equivalent to iOS testConnection method
     */
    fun testConnection() {
        if (_isTestingConnection.value) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Connection test already in progress")
            }
            return
        }
        
        viewModelScope.launch {
            _isTestingConnection.value = true
            networkSettings.connectionStatus = NetworkSettings.ConnectionStatus.CONNECTING
            
            try {
                val targetIP = networkSettings.currentTargetIP
                val targetPort = networkSettings.currentTargetPort
                val timeoutMs = networkSettings.timeoutMs
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔍 Testing connection to $targetIP:$targetPort")
                }
                
                val result = rcpNetworkClient.testConnection(targetIP, targetPort, timeoutMs)
                
                // Update connection status based on result
                networkSettings.connectionStatus = if (result.isSuccessful) {
                    NetworkSettings.ConnectionStatus.CONNECTED
                } else {
                    NetworkSettings.ConnectionStatus.ERROR
                }
                
                // Update last connection time if successful
                if (result.isSuccessful) {
                    networkSettings.lastConnectionTime = System.currentTimeMillis()
                }
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, if (result.isSuccessful) "✅ Connection test successful" else "❌ Connection test failed: ${result.errorMessage}")
                }
                
            } catch (e: Exception) {
                networkSettings.connectionStatus = NetworkSettings.ConnectionStatus.ERROR
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Connection test exception", e)
                }
                
            } finally {
                _isTestingConnection.value = false
            }
        }
    }
    
    /**
     * Save current settings
     * Equivalent to iOS saveSettings method
     */
    fun saveSettings() {
        networkSettings.saveSettings()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "💾 Network settings saved")
        }
    }
    
    /**
     * Reset settings to defaults
     * Equivalent to iOS resetToDefaults method
     */
    fun resetToDefaults() {
        networkSettings.resetToDefaults()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Network settings reset to defaults")
        }
    }
    
    /**
     * Validate IP address format
     * Equivalent to iOS isValidIPAddress method
     */
    fun isValidIPAddress(ip: String): Boolean {
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
     * Validate port number
     * Equivalent to iOS isValidPort method
     */
    fun isValidPort(port: Int): Boolean {
        return port in 1..65535
    }
    
    /**
     * Get current target display info
     * Equivalent to iOS getCurrentTargetInfo method
     */
    fun getCurrentTargetInfo(): String {
        val settings = networkSettings
        return "${settings.targetType.displayName} - ${settings.currentTargetIP}:${settings.currentTargetPort}"
    }
    
    /**
     * Check if configuration is complete and valid
     * Equivalent to iOS isConfigurationValid method
     */
    fun isConfigurationValid(): Boolean {
        return networkSettings.isValidConfiguration
    }
    
    /**
     * Get network statistics for debugging
     * Equivalent to iOS getNetworkStats method
     */
    fun getNetworkStats(): Map<String, Any> {
        return rcpNetworkClient.getNetworkStats()
    }
    
    override fun onCleared() {
        super.onCleared()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🧹 NetworkSettingsViewModel cleared")
        }
    }
}