package com.voicecontrol.app

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 MainActivity created")
        }
        
        // Enable edge-to-edge display (equivalent to iOS ignoresSafeArea)
        enableEdgeToEdge()
        
        setContent {
            VoiceControlApp()
        }
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
fun VoiceControlApp() {
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
            VoiceControlContent()
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
        authViewModel = authViewModel
    )
}