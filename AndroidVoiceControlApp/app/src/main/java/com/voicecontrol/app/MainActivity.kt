package com.voicecontrol.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.accompanist.systemuicontroller.rememberSystemUiController
import com.voicecontrol.app.authentication.viewmodel.AuthenticationViewModel
import com.voicecontrol.app.ui.navigation.VoiceControlNavigation
import com.voicecontrol.app.ui.theme.VoiceControlTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main Activity for Voice Control App
 * 
 * Equivalent to iOS ContentView.swift - the main entry point and navigation coordinator
 * Handles system UI, authentication flow, and main app navigation
 * 
 * Features:
 * - Edge-to-edge display with proper system bar handling
 * - Authentication flow management
 * - Navigation setup with Compose Navigation
 * - Material Design 3 theming
 * - Hilt dependency injection integration
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    // Permission result callback to communicate with ViewModel
    private var permissionResultCallback: ((Boolean) -> Unit)? = null
    
    // Permission request launcher for microphone permission
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔐 Microphone permission result: $isGranted")
        }
        // Notify the callback about permission result
        permissionResultCallback?.invoke(isGranted)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 MainActivity created")
        }
        
        // Enable edge-to-edge display (equivalent to iOS ignoresSafeArea)
        enableEdgeToEdge()
        
        setContent {
            VoiceControlApp(
                hasMicrophonePermission = ::hasMicrophonePermission,
                requestMicrophonePermission = ::requestMicrophonePermission
            )
        }
    }
    
    /**
     * Check if microphone permission is granted
     * Equivalent to iOS AVAudioSession.recordPermission check
     */
    fun hasMicrophonePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    /**
     * Request microphone permission
     * Equivalent to iOS AVAudioSession.requestRecordPermission
     */
    fun requestMicrophonePermission(callback: ((Boolean) -> Unit)? = null) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎙️ Requesting microphone permission")
        }
        permissionResultCallback = callback
        requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
    }
    
    override fun onResume() {
        super.onResume()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📱 MainActivity resumed")
        }
    }
    
    override fun onPause() {
        super.onPause()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "⏸️ MainActivity paused")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🛑 MainActivity destroyed")
        }
    }
}

/**
 * Main Composable app content
 * 
 * Equivalent to iOS ContentView body
 * Manages authentication state and navigation flow
 */
@Composable
fun VoiceControlApp(
    hasMicrophonePermission: () -> Boolean = { false },
    requestMicrophonePermission: (((Boolean) -> Unit)?) -> Unit = {}
) {
    // System UI controller for status bar theming
    val systemUiController = rememberSystemUiController()
    
    VoiceControlTheme {
        // Update system bars to match theme
        LaunchedEffect(systemUiController) {
            systemUiController.setSystemBarsColor(
                color = androidx.compose.ui.graphics.Color.Transparent,
                darkIcons = false
            )
        }
        
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            VoiceControlContent(
                hasMicrophonePermission = hasMicrophonePermission,
                requestMicrophonePermission = requestMicrophonePermission
            )
        }
    }
}

/**
 * Main content with authentication flow
 * 
 * Equivalent to iOS ContentView authentication logic
 * Manages navigation between authentication and main app screens
 */
@Composable
private fun VoiceControlContent(
    hasMicrophonePermission: () -> Boolean = { false },
    requestMicrophonePermission: (((Boolean) -> Unit)?) -> Unit = {},
    authViewModel: AuthenticationViewModel = hiltViewModel()
) {
    // Observe authentication state (equivalent to iOS @Published authState)
    val authState by authViewModel.authState.collectAsState()
    
    if (BuildConfig.ENABLE_LOGGING) {
        LaunchedEffect(authState) {
            Log.d("VoiceControlContent", "📱 Auth state changed: $authState")
        }
    }
    
    // Navigation based on authentication state
    // This replaces iOS NavigationView and conditional view presentation
    VoiceControlNavigation(
        authState = authState,
        authViewModel = authViewModel,
        hasMicrophonePermission = hasMicrophonePermission,
        requestMicrophonePermission = requestMicrophonePermission
    )
}