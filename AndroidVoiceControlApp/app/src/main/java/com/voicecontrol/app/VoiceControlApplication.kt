package com.voicecontrol.app

import android.app.Application
import android.util.Log
import dagger.hilt.android.HiltAndroidApp

/**
 * Main Application class for Voice Control App
 * 
 * Equivalent to iOS VoiceControlAppApp.swift
 * Handles application-level initialization, Firebase setup, and Hilt dependency injection
 * 
 * Features:
 * - Firebase integration with automatic initialization
 * - Hilt dependency injection setup
 * - Application-wide configuration and logging
 * - Memory management and lifecycle handling
 */
@HiltAndroidApp
class VoiceControlApplication : Application() {
    
    companion object {
        private const val TAG = "VoiceControlApp"
    }
    
    override fun onCreate() {
        super.onCreate()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 Voice Control Application starting...")
        }
        
        // Firebase is automatically initialized via google-services plugin
        // No explicit initialization needed (unlike iOS Firebase setup)
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "✅ Voice Control Application initialized successfully")
            Log.d(TAG, "🔧 Debug mode: ${BuildConfig.DEBUG}")
            Log.d(TAG, "📱 Package name: ${packageName}")
            Log.d(TAG, "🏷️ Version: ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
        }
    }
    
    override fun onTerminate() {
        super.onTerminate()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🛑 Voice Control Application terminating...")
        }
    }
    
    override fun onLowMemory() {
        super.onLowMemory()
        if (BuildConfig.ENABLE_LOGGING) {
            Log.w(TAG, "⚠️ Low memory warning - cleaning up resources")
        }
        
        // Equivalent to iOS didReceiveMemoryWarning
        // Android handles most cleanup automatically, but we can help
        System.gc() // Suggest garbage collection
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        
        when (level) {
            TRIM_MEMORY_UI_HIDDEN -> {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.i(TAG, "🔄 App moved to background - trimming memory")
                }
            }
            TRIM_MEMORY_RUNNING_MODERATE,
            TRIM_MEMORY_RUNNING_LOW,
            TRIM_MEMORY_RUNNING_CRITICAL -> {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ Memory pressure level: $level - optimizing resources")
                }
                // Could pause non-essential services here
            }
            TRIM_MEMORY_BACKGROUND,
            TRIM_MEMORY_MODERATE,
            TRIM_MEMORY_COMPLETE -> {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ Critical memory pressure level: $level - aggressive cleanup")
                }
                // Could stop background services, clear caches
            }
        }
    }
}