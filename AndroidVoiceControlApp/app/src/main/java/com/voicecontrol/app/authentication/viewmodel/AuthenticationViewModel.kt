package com.voicecontrol.app.authentication.viewmodel

import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.authentication.model.AuthState
import com.voicecontrol.app.authentication.model.AuthenticationError
import com.voicecontrol.app.authentication.model.GuestUser
import com.voicecontrol.app.authentication.model.SubscriptionStatus
import com.voicecontrol.app.authentication.model.User
import com.voicecontrol.app.authentication.service.BiometricAuthService
import com.voicecontrol.app.authentication.service.FirebaseAuthService
import com.voicecontrol.app.authentication.service.GoogleSignInService
import com.voicecontrol.app.authentication.service.SecureStorageService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Authentication ViewModel for Voice Control App
 * 
 * Direct port of iOS AuthenticationManager to Android MVVM pattern with StateFlow
 * Manages authentication state, user sessions, and coordinates all auth services
 * 
 * Features:
 * - StateFlow for reactive UI updates (equivalent to iOS @Published)
 * - Comprehensive state management with sealed classes
 * - Firebase Auth integration with state observation
 * - Google Sign-In support with activity result handling
 * - Biometric authentication support
 * - Guest mode for Apple App Store compliance
 * - Secure session persistence
 * - Subscription and usage tracking integration
 */
@HiltViewModel
class AuthenticationViewModel @Inject constructor(
    private val firebaseAuthService: FirebaseAuthService,
    private val googleSignInService: GoogleSignInService,
    private val biometricAuthService: BiometricAuthService,
    private val secureStorageService: SecureStorageService
) : ViewModel() {
    
    companion object {
        private const val TAG = "AuthenticationViewModel"
    }
    
    // MARK: - State Properties (equivalent to iOS @Published)
    
    private val _authState = MutableStateFlow<AuthState>(AuthState.Unauthenticated)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()
    
    private val _guestUser = MutableStateFlow<GuestUser?>(null)
    val guestUser: StateFlow<GuestUser?> = _guestUser.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    // MARK: - Initialization
    
    init {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 AuthenticationViewModel initialized")
        }
        
        // Observe Firebase Auth state changes (equivalent to iOS setupAuthListener)
        observeFirebaseAuthState()
        
        // Check for persisted session (equivalent to iOS checkPersistedSession)
        checkPersistedSession()
    }
    
    /**
     * Observe Firebase Auth state changes
     * Equivalent to iOS setupAuthListener()
     */
    private fun observeFirebaseAuthState() {
        viewModelScope.launch {
            firebaseAuthService.observeAuthState().collect { firebaseUser ->
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🔄 Firebase auth state changed: ${firebaseUser?.uid ?: "null"}")
                }
                
                handleAuthStateChange(firebaseUser)
            }
        }
    }
    
    /**
     * Handle Firebase authentication state changes
     * Equivalent to iOS handleAuthStateChange()
     */
    private suspend fun handleAuthStateChange(firebaseUser: com.google.firebase.auth.FirebaseUser?) {
        if (firebaseUser != null) {
            _currentUser.value = User.fromFirebaseUser(firebaseUser)
            
            // Check if biometric authentication is required
            if (shouldRequireBiometricAuth()) {
                _authState.value = AuthState.RequiresBiometric
            } else {
                _authState.value = AuthState.Authenticated
            }
            
            // Persist user session
            persistUserSession()
        } else {
            _currentUser.value = null
            if (_authState.value != AuthState.Guest) {
                _authState.value = AuthState.Unauthenticated
            }
            clearPersistedSession()
        }
        
        _isLoading.value = false
        _errorMessage.value = null
    }
    
    /**
     * Check for persisted authentication session
     * Equivalent to iOS checkPersistedSession()
     */
    private fun checkPersistedSession() {
        viewModelScope.launch {
            try {
                // First check for authenticated user session
                val persistedUser = secureStorageService.getCurrentUser<User>()
                if (persistedUser != null) {
                    // Verify the session is still valid with Firebase
                    if (firebaseAuthService.currentUser != null) {
                        _currentUser.value = persistedUser
                        _authState.value = if (shouldRequireBiometricAuth()) {
                            AuthState.RequiresBiometric
                        } else {
                            AuthState.Authenticated
                        }
                        
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.d(TAG, "✅ Restored authenticated session for user: ${persistedUser.id}")
                        }
                        return@launch
                    } else {
                        // Session expired, clear persisted data
                        clearPersistedSession()
                    }
                }
                
                // Check for guest session
                val persistedGuest = secureStorageService.getGuestUser<GuestUser>()
                if (persistedGuest != null) {
                    _guestUser.value = persistedGuest
                    _authState.value = AuthState.Guest
                    
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "✅ Restored guest session: ${persistedGuest.description}")
                    }
                    return@launch
                }
                
                // No persisted session found
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "ℹ️ No persisted session found")
                }
                
                // Development auto-login for testing (equivalent to iOS simulator auto-login)
                if (BuildConfig.DEBUG) {
                    autoLoginForTesting()
                }
                
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Error checking persisted session", e)
                }
                clearPersistedSession()
            }
        }
    }
    
    /**
     * Auto-login for development testing
     * Equivalent to iOS autoLoginForTesting()
     */
    private suspend fun autoLoginForTesting() {
        // Only in debug builds
        if (!BuildConfig.DEBUG) return
        
        val testEmail = "colin.mignot1@gmail.com"
        val testPassword = "Licofeuh7."
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔧 DEV MODE: Auto-login attempt with test credentials")
        }
        
        try {
            _isLoading.value = true
            firebaseAuthService.signIn(testEmail, testPassword)
            // State change will be handled by the Firebase auth listener
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ DEV MODE: Auto-login successful")
            }
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ DEV MODE: Auto-login failed, will show login screen")
            }
        } finally {
            _isLoading.value = false
        }
    }
    
    // MARK: - Authentication Methods
    
    /**
     * Sign in with email and password
     * Equivalent to iOS AuthenticationManager.signIn()
     */
    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState.Authenticating
                _isLoading.value = true
                _errorMessage.value = null
                
                firebaseAuthService.signIn(email, password)
                // State change will be handled by the Firebase auth listener
                
            } catch (e: AuthenticationError) {
                _authState.value = AuthState.Error(e)
                _errorMessage.value = e.message
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Sign in failed: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Sign up with email and password
     * Equivalent to iOS AuthenticationManager.signUp()
     */
    fun signUp(email: String, password: String, displayName: String?) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState.Authenticating
                _isLoading.value = true
                _errorMessage.value = null
                
                firebaseAuthService.signUp(email, password, displayName)
                // State change will be handled by the Firebase auth listener
                
            } catch (e: AuthenticationError) {
                _authState.value = AuthState.Error(e)
                _errorMessage.value = e.message
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Sign up failed: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Sign out current user
     * Equivalent to iOS AuthenticationManager.signOut()
     */
    fun signOut() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                
                // Sign out from Firebase
                firebaseAuthService.signOut()
                
                // Sign out from Google
                googleSignInService.signOut()
                
                // Clear persisted session (includes guest data)
                clearPersistedSession()
                
                // Clear guest user if in guest mode
                if (_authState.value.isGuest) {
                    _guestUser.value = null
                }
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Complete sign-out successful")
                }
                
                // State change will be handled by the Firebase auth listener
                
            } catch (e: AuthenticationError) {
                _authState.value = AuthState.Error(e)
                _errorMessage.value = e.message
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Sign out failed: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Sign in with Google
     * Equivalent to iOS AuthenticationManager.signInWithGoogle()
     * 
     * @param activity The FragmentActivity needed for Google Sign-In
     */
    fun signInWithGoogle(activity: FragmentActivity) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState.Authenticating
                _isLoading.value = true
                _errorMessage.value = null
                
                val user = googleSignInService.signIn(activity)
                
                // Convert to our User model and update state
                _currentUser.value = user
                
                // Check if biometric authentication is required
                if (shouldRequireBiometricAuth()) {
                    _authState.value = AuthState.RequiresBiometric
                } else {
                    _authState.value = AuthState.Authenticated
                }
                
                // Persist user session
                persistUserSession()
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Google Sign-In successful")
                }
                
            } catch (e: AuthenticationError) {
                _authState.value = AuthState.Error(e)
                _errorMessage.value = e.message
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Google Sign-In failed - ${e.message}")
                }
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Google Sign-In failed: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Reset password for email
     * Equivalent to iOS AuthenticationManager.resetPassword()
     */
    fun resetPassword(email: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _errorMessage.value = null
                
                firebaseAuthService.resetPassword(email)
                onResult(true)
                
            } catch (e: AuthenticationError) {
                _errorMessage.value = e.message
                onResult(false)
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Password reset failed: ${e.message}",
                    throwable = e
                )
                _errorMessage.value = authError.message
                onResult(false)
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Delete user account
     * Equivalent to iOS AuthenticationManager.deleteAccount()
     */
    fun deleteAccount(onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                if (_currentUser.value == null) {
                    onResult(false)
                    return@launch
                }
                
                _isLoading.value = true
                _errorMessage.value = null
                
                firebaseAuthService.deleteAccount()
                
                // Clear persisted session
                clearPersistedSession()
                
                onResult(true)
                
                // State change will be handled by the Firebase auth listener
                
            } catch (e: AuthenticationError) {
                _authState.value = AuthState.Error(e)
                _errorMessage.value = e.message
                onResult(false)
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Account deletion failed: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
                onResult(false)
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Send email verification
     * Equivalent to iOS AuthenticationManager.sendEmailVerification()
     */
    fun sendEmailVerification(onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                if (_currentUser.value == null) {
                    onResult(false)
                    return@launch
                }
                
                _isLoading.value = true
                _errorMessage.value = null
                
                firebaseAuthService.sendEmailVerification()
                onResult(true)
                
            } catch (e: AuthenticationError) {
                _errorMessage.value = e.message
                onResult(false)
            } catch (e: Exception) {
                val authError = AuthenticationError.Unknown(
                    customMessage = "Email verification failed: ${e.message}",
                    throwable = e
                )
                _errorMessage.value = authError.message
                onResult(false)
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    // MARK: - Guest Mode (Apple App Store Compliance)
    
    /**
     * Enter guest mode
     * Equivalent to iOS AuthenticationManager.enterGuestMode()
     */
    fun enterGuestMode() {
        viewModelScope.launch {
            try {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "🎯 Entering guest mode")
                }
                
                _isLoading.value = true
                _errorMessage.value = null
                
                // Load existing guest user or create new one
                val guest = secureStorageService.getGuestUser<GuestUser>() ?: GuestUser()
                _guestUser.value = guest
                
                // Save guest user to secure storage
                secureStorageService.saveGuestUser(guest)
                
                // Update auth state to guest
                _authState.value = AuthState.Guest
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Guest mode activated: ${guest.description}")
                }
                
            } catch (e: Exception) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Failed to enter guest mode", e)
                }
                val authError = AuthenticationError.Unknown(
                    customMessage = "Failed to enter guest mode: ${e.message}",
                    throwable = e
                )
                _authState.value = AuthState.Error(authError)
                _errorMessage.value = authError.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Exit guest mode
     * Equivalent to iOS AuthenticationManager.exitGuestMode()
     */
    fun exitGuestMode() {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎯 Exiting guest mode")
        }
        
        // Clear guest user data
        secureStorageService.deleteGuestUser()
        _guestUser.value = null
        
        // Return to unauthenticated state
        _authState.value = AuthState.Unauthenticated
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "✅ Guest mode exited")
        }
    }
    
    /**
     * Update guest usage
     * Equivalent to iOS AuthenticationManager.updateGuestUsage()
     */
    fun updateGuestUsage(minutesUsed: Int) {
        viewModelScope.launch {
            val guest = _guestUser.value ?: return@launch
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🎯 Updating guest usage by $minutesUsed minutes")
                Log.d(TAG, "   Previous usage: ${guest.totalAPIMinutesUsed} minutes")
            }
            
            // Update usage
            val updatedGuest = guest.incrementUsage(by = minutesUsed)
            _guestUser.value = updatedGuest
            
            // Persist updated usage
            secureStorageService.saveGuestUser(updatedGuest)
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "   New usage: ${updatedGuest.totalAPIMinutesUsed} minutes")
                Log.d(TAG, "   Remaining: ${updatedGuest.remainingFreeMinutes} minutes")
            }
            
            // Check if usage limit reached
            if (!updatedGuest.canMakeAPICall) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ Guest usage limit reached")
                }
                // Could trigger paywall or upgrade prompt here
            }
        }
    }
    
    // MARK: - Biometric Authentication
    
    /**
     * Check if biometric authentication should be required
     * Equivalent to iOS shouldRequireBiometricAuth()
     */
    private fun shouldRequireBiometricAuth(): Boolean {
        return secureStorageService.isBiometricEnabled()
    }
    
    /**
     * Complete biometric authentication
     * Equivalent to iOS AuthenticationManager.completeBiometricAuth()
     */
    fun completeBiometricAuth() {
        if (_currentUser.value != null) {
            _authState.value = AuthState.Authenticated
        }
    }
    
    /**
     * Authenticate with biometric
     * Android-specific method that handles the full biometric flow
     */
    fun authenticateWithBiometric(activity: FragmentActivity) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _errorMessage.value = null
                
                biometricAuthService.authenticate(activity)
                
                // If we get here, authentication succeeded
                completeBiometricAuth()
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Biometric authentication successful")
                }
                
            } catch (e: AuthenticationError.BiometricError) {
                _errorMessage.value = e.message
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Biometric authentication failed: ${e.message}")
                }
                
                // Don't change auth state on biometric failure - let user retry or use other methods
                
            } catch (e: Exception) {
                _errorMessage.value = "Biometric authentication failed: ${e.message}"
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ Unexpected biometric error", e)
                }
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    // MARK: - Error Handling
    
    /**
     * Clear current error message
     * Equivalent to iOS AuthenticationManager.clearError()
     */
    fun clearError() {
        _errorMessage.value = null
        if (_authState.value.hasError) {
            _authState.value = AuthState.Unauthenticated
        }
    }
    
    // MARK: - Session Management
    
    /**
     * Persist user session to secure storage
     * Equivalent to iOS persistUserSession()
     */
    private suspend fun persistUserSession() {
        val user = _currentUser.value ?: return
        
        try {
            secureStorageService.saveCurrentUser(user)
            
            // Store Firebase ID token for backend authentication
            val idToken = firebaseAuthService.getIdToken()
            secureStorageService.saveFirebaseToken(idToken)
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ User session persisted")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to persist user session", e)
            }
        }
    }
    
    /**
     * Clear persisted session data
     * Equivalent to iOS clearPersistedSession()
     */
    private fun clearPersistedSession() {
        secureStorageService.deleteCurrentUser()
        secureStorageService.deleteFirebaseToken()
        secureStorageService.deleteGuestUser()
        
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🗑️ Persisted session cleared")
        }
    }
    
    // MARK: - Token Management
    
    /**
     * Get current Firebase ID token
     * Equivalent to iOS AuthenticationManager.getCurrentIDToken()
     */
    suspend fun getCurrentIDToken(): String? {
        return try {
            firebaseAuthService.getIdToken()
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to get ID token", e)
            }
            null
        }
    }
    
    /**
     * Refresh Firebase ID token
     * Equivalent to iOS AuthenticationManager.refreshIDToken()
     */
    suspend fun refreshIDToken(): String? {
        return try {
            val token = firebaseAuthService.getIdToken(forceRefresh = true)
            secureStorageService.saveFirebaseToken(token)
            token
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to refresh ID token", e)
            }
            null
        }
    }
    
    // MARK: - Premium/Subscription Convenience Properties
    
    /**
     * Check if user has premium subscription
     * Equivalent to iOS AuthenticationManager.isPremiumUser
     */
    val isPremiumUser: Boolean
        get() = _currentUser.value?.subscriptionStatus?.isPremium ?: false
    
    /**
     * Get current subscription status
     * Equivalent to iOS AuthenticationManager.subscriptionStatus
     */
    val subscriptionStatus: SubscriptionStatus
        get() = _currentUser.value?.subscriptionStatus ?: SubscriptionStatus.Free(remainingMinutes = 0)
    
    /**
     * Update subscription status
     * Equivalent to iOS AuthenticationManager.updateSubscriptionStatus()
     */
    fun updateSubscriptionStatus(status: SubscriptionStatus) {
        viewModelScope.launch {
            val user = _currentUser.value ?: return@launch
            val updatedUser = user.copy(
                subscriptionStatus = status,
                isPremium = status.isPremium
            )
            
            _currentUser.value = updatedUser
            
            // Persist updated user
            secureStorageService.saveCurrentUser(updatedUser)
        }
    }
}