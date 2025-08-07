package com.voicecontrol.app.authentication.service

import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.authentication.model.AuthenticationError
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Biometric Authentication Service for Voice Control App
 * 
 * Direct port of iOS BiometricService to Android using BiometricPrompt
 * Handles fingerprint, face unlock, and other biometric authentication methods
 * 
 * Features:
 * - Support for all Android biometric types (fingerprint, face, iris)
 * - Hardware capability detection (equivalent to iOS biometric availability)
 * - Comprehensive error handling with custom error types
 * - Coroutine-based async operations (equivalent to iOS async/await)
 * - User enrollment status checking
 * - Security level validation
 */
@Singleton
class BiometricAuthService @Inject constructor() {
    
    companion object {
        private const val TAG = "BiometricAuthService"
    }
    
    /**
     * Biometric availability status
     * Equivalent to iOS BiometricAuthenticationStatus
     */
    enum class BiometricAvailability {
        /** Biometric authentication is available and ready to use */
        AVAILABLE,
        
        /** No biometric hardware is present on the device */
        NOT_AVAILABLE,
        
        /** Biometric hardware is present but no biometrics are enrolled */
        NOT_ENROLLED,
        
        /** Biometric hardware is temporarily unavailable */
        TEMPORARILY_NOT_AVAILABLE,
        
        /** Unknown status (error checking availability) */
        UNKNOWN_ERROR
    }
    
    /**
     * Check if biometric authentication is available on the device
     * Equivalent to iOS BiometricService.isBiometricAvailable()
     * 
     * @param activity The activity context needed for BiometricManager
     * @return BiometricAvailability status
     */
    fun checkBiometricAvailability(activity: FragmentActivity): BiometricAvailability {
        return try {
            val biometricManager = BiometricManager.from(activity)
            
            when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
                BiometricManager.BIOMETRIC_SUCCESS -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "✅ Biometric authentication is available")
                    }
                    BiometricAvailability.AVAILABLE
                }
                
                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "❌ No biometric hardware available")
                    }
                    BiometricAvailability.NOT_AVAILABLE
                }
                
                BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "⚠️ Biometric hardware temporarily unavailable")
                    }
                    BiometricAvailability.TEMPORARILY_NOT_AVAILABLE
                }
                
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "⚠️ No biometric credentials enrolled")
                    }
                    BiometricAvailability.NOT_ENROLLED
                }
                
                else -> {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.w(TAG, "⚠️ Unknown biometric status")
                    }
                    BiometricAvailability.UNKNOWN_ERROR
                }
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error checking biometric availability", e)
            }
            BiometricAvailability.UNKNOWN_ERROR
        }
    }
    
    /**
     * Authenticate using biometric prompt
     * Equivalent to iOS BiometricService.authenticate()
     * 
     * @param activity The FragmentActivity to show the prompt from
     * @param title Title for the biometric prompt
     * @param subtitle Subtitle for the biometric prompt  
     * @param description Description for the biometric prompt
     * @param negativeButtonText Text for the negative/cancel button
     * @return Unit if authentication succeeds
     * @throws AuthenticationError.BiometricError for various failure scenarios
     */
    suspend fun authenticate(
        activity: FragmentActivity,
        title: String = "Voice Control Authentication",
        subtitle: String = "Use your biometric credential to continue",
        description: String = "Authenticate to access your voice control settings",
        negativeButtonText: String = "Cancel"
    ): Unit {
        
        // Check availability first
        val availability = checkBiometricAvailability(activity)
        if (availability != BiometricAvailability.AVAILABLE) {
            throw when (availability) {
                BiometricAvailability.NOT_AVAILABLE -> 
                    AuthenticationError.BiometricError.NotAvailable
                BiometricAvailability.NOT_ENROLLED -> 
                    AuthenticationError.BiometricError.NotEnrolled
                BiometricAvailability.TEMPORARILY_NOT_AVAILABLE ->
                    AuthenticationError.BiometricError.AuthenticationFailed
                else ->
                    AuthenticationError.BiometricError.AuthenticationFailed
            }
        }
        
        return suspendCancellableCoroutine { continuation ->
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔐 Starting biometric authentication")
            }
            
            val executor = ContextCompat.getMainExecutor(activity)
            
            val biometricPrompt = BiometricPrompt(activity, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.e(TAG, "❌ Biometric authentication error: $errorCode - $errString")
                        }
                        
                        val authError = when (errorCode) {
                            BiometricPrompt.ERROR_USER_CANCELED,
                            BiometricPrompt.ERROR_NEGATIVE_BUTTON -> {
                                AuthenticationError.BiometricError.UserCancelled
                            }
                            
                            BiometricPrompt.ERROR_HW_NOT_PRESENT,
                            BiometricPrompt.ERROR_HW_UNAVAILABLE -> {
                                AuthenticationError.BiometricError.NotAvailable
                            }
                            
                            BiometricPrompt.ERROR_NO_BIOMETRICS -> {
                                AuthenticationError.BiometricError.NotEnrolled
                            }
                            
                            else -> {
                                AuthenticationError.BiometricError.AuthenticationFailed
                            }
                        }
                        
                        if (continuation.isActive) {
                            continuation.resumeWithException(authError)
                        }
                    }
                    
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.d(TAG, "✅ Biometric authentication succeeded")
                        }
                        
                        if (continuation.isActive) {
                            continuation.resume(Unit)
                        }
                    }
                    
                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.w(TAG, "⚠️ Biometric authentication failed (retry available)")
                        }
                        
                        // Don't resume continuation here - let user retry
                        // Only resume with error if they exceed max attempts or cancel
                    }
                }
            )
            
            // Build prompt info
            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setDescription(description)
                .setNegativeButtonText(negativeButtonText)
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .build()
            
            // Handle cancellation
            continuation.invokeOnCancellation {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🚫 Biometric authentication cancelled by coroutine")
                }
                // BiometricPrompt doesn't have a direct cancel method
                // The prompt will be dismissed when the activity is destroyed
            }
            
            try {
                // Show the biometric prompt
                biometricPrompt.authenticate(promptInfo)
                
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Error showing biometric prompt", e)
                }
                
                if (continuation.isActive) {
                    continuation.resumeWithException(
                        AuthenticationError.BiometricError.AuthenticationFailed
                    )
                }
            }
        }
    }
    
    /**
     * Get available biometric types on the device
     * Android-specific enhancement - iOS doesn't differentiate between types
     * 
     * @param activity The activity context
     * @return List of available biometric type names
     */
    fun getAvailableBiometricTypes(activity: FragmentActivity): List<String> {
        val types = mutableListOf<String>()
        val biometricManager = BiometricManager.from(activity)
        
        try {
            // Check for different authenticator types
            if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) 
                == BiometricManager.BIOMETRIC_SUCCESS) {
                types.add("Strong Biometrics")
            }
            
            if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) 
                == BiometricManager.BIOMETRIC_SUCCESS) {
                types.add("Weak Biometrics")
            }
            
            if (biometricManager.canAuthenticate(BiometricManager.Authenticators.DEVICE_CREDENTIAL) 
                == BiometricManager.BIOMETRIC_SUCCESS) {
                types.add("Device Credential")
            }
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📱 Available biometric types: $types")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error checking biometric types", e)
            }
        }
        
        return types
    }
    
    /**
     * Check if device credential (PIN/Pattern/Password) is available
     * Android-specific feature - useful fallback for biometric authentication
     * 
     * @param activity The activity context
     * @return true if device credential is set up and available
     */
    fun isDeviceCredentialAvailable(activity: FragmentActivity): Boolean {
        return try {
            val biometricManager = BiometricManager.from(activity)
            biometricManager.canAuthenticate(BiometricManager.Authenticators.DEVICE_CREDENTIAL) == BiometricManager.BIOMETRIC_SUCCESS
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error checking device credential availability", e)
            }
            false
        }
    }
    
    /**
     * Get user-friendly description of biometric availability
     * Equivalent to iOS BiometricService status descriptions
     * 
     * @param activity The activity context
     * @return Human-readable description of biometric status
     */
    fun getBiometricStatusDescription(activity: FragmentActivity): String {
        return when (checkBiometricAvailability(activity)) {
            BiometricAvailability.AVAILABLE -> 
                "Biometric authentication is available"
            
            BiometricAvailability.NOT_AVAILABLE -> 
                "This device does not support biometric authentication"
            
            BiometricAvailability.NOT_ENROLLED -> 
                "No biometric credentials are enrolled. Please set up fingerprint or face recognition in Settings"
            
            BiometricAvailability.TEMPORARILY_NOT_AVAILABLE -> 
                "Biometric authentication is temporarily unavailable"
            
            BiometricAvailability.UNKNOWN_ERROR -> 
                "Unable to determine biometric authentication status"
        }
    }
}