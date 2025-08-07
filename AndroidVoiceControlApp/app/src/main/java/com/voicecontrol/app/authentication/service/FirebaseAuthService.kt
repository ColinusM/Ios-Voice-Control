package com.voicecontrol.app.authentication.service

import android.util.Log
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.UserProfileChangeRequest
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.authentication.model.AuthenticationError
import com.voicecontrol.app.authentication.model.User
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Firebase Authentication Service for Voice Control App
 * 
 * Direct port of iOS FirebaseAuthService to Android with Kotlin Coroutines
 * Handles all Firebase Auth operations with comprehensive error handling
 * 
 * Features:
 * - Coroutine-based async operations (equivalent to iOS async/await)
 * - Comprehensive error handling with custom error types
 * - Firebase Auth state observation via Flow
 * - Email/password authentication
 * - Email verification and password reset
 * - Account management (update profile, delete account)
 * - Secure token management
 */
@Singleton
class FirebaseAuthService @Inject constructor(
    private val firebaseAuth: FirebaseAuth,
    private val firestore: com.google.firebase.firestore.FirebaseFirestore
) {
    
    companion object {
        private const val TAG = "FirebaseAuthService"
    }
    
    /**
     * Current Firebase user
     * Equivalent to iOS FirebaseAuth.auth().currentUser
     */
    val currentUser: FirebaseUser?
        get() = firebaseAuth.currentUser
    
    /**
     * Observe authentication state changes
     * Equivalent to iOS Auth.auth().addStateDidChangeListener
     * 
     * @return Flow of nullable FirebaseUser representing auth state
     */
    fun observeAuthState(): Flow<FirebaseUser?> = callbackFlow {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔍 Starting Firebase Auth state observation")
        }
        
        val listener = FirebaseAuth.AuthStateListener { auth ->
            val user = auth.currentUser
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔄 Auth state changed: ${user?.uid ?: "null"}")
            }
            trySend(user)
        }
        
        firebaseAuth.addAuthStateListener(listener)
        
        awaitClose {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🛑 Stopping Firebase Auth state observation")
            }
            firebaseAuth.removeAuthStateListener(listener)
        }
    }
    
    /**
     * Sign in with email and password
     * Equivalent to iOS firebaseAuthService.signIn()
     * 
     * @param email User's email address
     * @param password User's password
     * @return AuthResult containing the signed-in user
     * @throws AuthenticationError for various authentication failures
     */
    suspend fun signIn(email: String, password: String): AuthResult {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔐 Attempting sign in for email: $email")
            }
            
            val result = firebaseAuth.signInWithEmailAndPassword(email, password).await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Sign in successful for user: ${result.user?.uid}")
            }
            
            return result
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Sign in failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected sign in error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Sign in failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Create new account with email and password
     * Equivalent to iOS firebaseAuthService.signUp()
     * 
     * @param email User's email address
     * @param password User's password
     * @param displayName Optional display name for the user
     * @return AuthResult containing the newly created user
     * @throws AuthenticationError for various authentication failures
     */
    suspend fun signUp(
        email: String, 
        password: String, 
        displayName: String? = null
    ): AuthResult {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📝 Creating account for email: $email")
            }
            
            val result = firebaseAuth.createUserWithEmailAndPassword(email, password).await()
            
            // Update profile with display name if provided
            displayName?.let { name ->
                val profileUpdates = UserProfileChangeRequest.Builder()
                    .setDisplayName(name)
                    .build()
                
                result.user?.updateProfile(profileUpdates)?.await()
                
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "📝 Profile updated with display name: $name")
                }
            }
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Account created successfully for user: ${result.user?.uid}")
            }
            
            return result
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Account creation failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected account creation error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Account creation failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Sign out current user
     * Equivalent to iOS firebaseAuthService.signOut()
     * 
     * @throws AuthenticationError if sign out fails
     */
    suspend fun signOut() {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                val currentUserId = currentUser?.uid
                Log.d(TAG, "🚪 Signing out user: $currentUserId")
            }
            
            firebaseAuth.signOut()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Sign out successful")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Sign out error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Sign out failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Send password reset email
     * Equivalent to iOS firebaseAuthService.resetPassword()
     * 
     * @param email Email address to send reset link to
     * @throws AuthenticationError if password reset fails
     */
    suspend fun resetPassword(email: String) {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📧 Sending password reset email to: $email")
            }
            
            firebaseAuth.sendPasswordResetEmail(email).await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Password reset email sent successfully")
            }
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Password reset failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected password reset error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Password reset failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Send email verification to current user
     * Equivalent to iOS firebaseAuthService.sendEmailVerification()
     * 
     * @throws AuthenticationError if email verification fails
     */
    suspend fun sendEmailVerification() {
        try {
            val user = currentUser
                ?: throw AuthenticationError.UserNotFound
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📧 Sending email verification to: ${user.email}")
            }
            
            user.sendEmailVerification().await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Email verification sent successfully")
            }
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Email verification failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected email verification error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Email verification failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Delete current user account
     * Equivalent to iOS firebaseAuthService.deleteAccount()
     * 
     * @throws AuthenticationError if account deletion fails
     */
    suspend fun deleteAccount() {
        try {
            val user = currentUser
                ?: throw AuthenticationError.UserNotFound
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🗑️ Deleting account for user: ${user.uid}")
            }
            
            user.delete().await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Account deleted successfully")
            }
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Account deletion failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected account deletion error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Account deletion failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Update user profile information
     * Equivalent to iOS user profile update operations
     * 
     * @param displayName New display name (optional)
     * @param photoUrl New photo URL (optional)
     * @throws AuthenticationError if profile update fails
     */
    suspend fun updateProfile(displayName: String? = null, photoUrl: String? = null) {
        try {
            val user = currentUser
                ?: throw AuthenticationError.UserNotFound
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📝 Updating profile for user: ${user.uid}")
            }
            
            val profileUpdates = UserProfileChangeRequest.Builder().apply {
                displayName?.let { setDisplayName(it) }
                photoUrl?.let { setPhotoUri(android.net.Uri.parse(it)) }
            }.build()
            
            user.updateProfile(profileUpdates).await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Profile updated successfully")
            }
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Profile update failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected profile update error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "Profile update failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Get current user's ID token
     * Equivalent to iOS firebaseUser.getIDToken()
     * 
     * @param forceRefresh Whether to force token refresh
     * @return ID token string
     * @throws AuthenticationError if token retrieval fails
     */
    suspend fun getIdToken(forceRefresh: Boolean = false): String {
        try {
            val user = currentUser
                ?: throw AuthenticationError.UserNotFound
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🎫 Getting ID token (forceRefresh: $forceRefresh)")
            }
            
            val tokenResult = user.getIdToken(forceRefresh).await()
            val token = tokenResult.token
                ?: throw AuthenticationError.Unknown("Failed to retrieve ID token")
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ ID token retrieved successfully")
            }
            
            return token
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ ID token retrieval failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected ID token error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "ID token retrieval failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Refresh current user data from Firebase
     * Equivalent to iOS user.reload()
     * 
     * @throws AuthenticationError if reload fails
     */
    suspend fun reloadUser() {
        try {
            val user = currentUser
                ?: throw AuthenticationError.UserNotFound
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔄 Reloading user data")
            }
            
            user.reload().await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ User data reloaded successfully")
            }
            
        } catch (e: FirebaseAuthException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ User reload failed: ${e.message}", e)
            }
            throw AuthenticationError.fromFirebaseException(e)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Unexpected user reload error: ${e.message}", e)
            }
            throw AuthenticationError.Unknown(
                customMessage = "User reload failed: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Convert current Firebase user to app User model
     * Equivalent to iOS User.from(firebaseUser:)
     * 
     * @return User model or null if no current user
     */
    fun getCurrentUserAsModel(): User? {
        return currentUser?.let { User.fromFirebaseUser(it) }
    }
}