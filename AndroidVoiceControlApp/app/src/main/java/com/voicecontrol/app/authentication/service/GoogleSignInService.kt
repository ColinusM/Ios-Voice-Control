package com.voicecontrol.app.authentication.service

import android.content.Context
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.auth.api.identity.BeginSignInRequest
import com.google.android.gms.auth.api.identity.BeginSignInResult
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.auth.api.identity.SignInClient
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.voicecontrol.app.BuildConfig
import com.voicecontrol.app.R
import com.voicecontrol.app.authentication.model.AuthenticationError
import com.voicecontrol.app.authentication.model.User
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Google Sign-In Service for Voice Control App
 * 
 * Direct port of iOS GoogleSignInService to Android with One Tap Sign-In support
 * Handles Google authentication with comprehensive error handling and modern Android APIs
 * 
 * Features:
 * - One Tap Sign-In for better UX (Android-specific enhancement)
 * - Classic Google Sign-In fallback
 * - Firebase Auth integration
 * - Coroutine-based async operations (equivalent to iOS async/await)
 * - Activity result handling with ActivityResultLauncher
 * - Comprehensive error handling with custom error types
 */
@Singleton
class GoogleSignInService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val TAG = "GoogleSignInService"
        
        // Server client ID for Firebase integration
        // This should match the web client ID from google-services.json
        private const val SERVER_CLIENT_ID = "1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv.apps.googleusercontent.com"
    }
    
    private val firebaseAuth = FirebaseAuth.getInstance()
    
    // One Tap Sign-In client (Android-specific - more streamlined UX)
    private val oneTapClient: SignInClient by lazy {
        Identity.getSignInClient(context)
    }
    
    // Classic Google Sign-In client (fallback)
    private val googleSignInClient: GoogleSignInClient by lazy {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(SERVER_CLIENT_ID)
            .requestEmail()
            .requestProfile()
            .build()
        
        GoogleSignIn.getClient(context, gso)
    }
    
    // One Tap Sign-In request configuration
    private val oneTapRequest: BeginSignInRequest by lazy {
        BeginSignInRequest.builder()
            .setPasswordRequestOptions(
                BeginSignInRequest.PasswordRequestOptions.builder()
                    .setSupported(true)
                    .build()
            )
            .setGoogleIdTokenRequestOptions(
                BeginSignInRequest.GoogleIdTokenRequestOptions.builder()
                    .setSupported(true)
                    .setServerClientId(SERVER_CLIENT_ID)
                    .setFilterByAuthorizedAccounts(false)
                    .build()
            )
            .setAutoSelectEnabled(true)
            .build()
    }
    
    /**
     * Activity result launcher for One Tap Sign-In
     * Must be registered in the calling Activity
     */
    private var oneTapLauncher: ActivityResultLauncher<IntentSenderRequest>? = null
    
    /**
     * Activity result launcher for classic Google Sign-In  
     * Must be registered in the calling Activity
     */
    private var classicLauncher: ActivityResultLauncher<android.content.Intent>? = null
    
    /**
     * Continuation for suspending sign-in coroutine
     */
    private var signInContinuation: kotlin.coroutines.Continuation<User>? = null
    
    /**
     * Register activity result launchers
     * Must be called from Activity.onCreate() before the activity is started
     * 
     * @param activity The ComponentActivity to register launchers with
     */
    fun registerActivityResultLaunchers(activity: ComponentActivity) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📝 Registering activity result launchers")
        }
        
        // One Tap Sign-In launcher
        oneTapLauncher = activity.registerForActivityResult(
            ActivityResultContracts.StartIntentSenderForResult()
        ) { result ->
            handleOneTapResult(result.data)
        }
        
        // Classic Google Sign-In launcher
        classicLauncher = activity.registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            handleClassicSignInResult(result.data)
        }
    }
    
    /**
     * Initiate Google Sign-In flow
     * Equivalent to iOS GoogleSignInService.signIn()
     * 
     * Tries One Tap Sign-In first, falls back to classic flow if needed
     * 
     * @param activity The Activity to launch sign-in from
     * @return User model for signed-in user
     * @throws AuthenticationError for various authentication failures
     */
    suspend fun signIn(activity: ComponentActivity): User {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🚀 Starting Google Sign-In flow")
        }
        
        return suspendCancellableCoroutine { continuation ->
            signInContinuation = continuation
            
            continuation.invokeOnCancellation {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "❌ Google Sign-In cancelled by user")
                }
                signInContinuation = null
            }
            
            // Try One Tap Sign-In first
            tryOneTapSignIn(activity)
        }
    }
    
    /**
     * Attempt One Tap Sign-In
     * Android-specific enhancement for better UX
     */
    private fun tryOneTapSignIn(activity: ComponentActivity) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🎯 Attempting One Tap Sign-In")
        }
        
        oneTapClient.beginSignIn(oneTapRequest)
            .addOnSuccessListener { result: BeginSignInResult ->
                try {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.d(TAG, "✅ One Tap Sign-In available, launching...")
                    }
                    
                    val intentSenderRequest = IntentSenderRequest.Builder(
                        result.pendingIntent.intentSender
                    ).build()
                    
                    oneTapLauncher?.launch(intentSenderRequest)
                        ?: throw IllegalStateException("One Tap launcher not registered")
                    
                } catch (e: Exception) {
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.e(TAG, "❌ Error launching One Tap Sign-In: ${e.message}")
                    }
                    fallbackToClassicSignIn(activity)
                }
            }
            .addOnFailureListener { exception ->
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.w(TAG, "⚠️ One Tap Sign-In not available: ${exception.message}")
                }
                fallbackToClassicSignIn(activity)
            }
    }
    
    /**
     * Fallback to classic Google Sign-In
     */
    private fun fallbackToClassicSignIn(activity: ComponentActivity) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔄 Falling back to classic Google Sign-In")
        }
        
        try {
            val signInIntent = googleSignInClient.signInIntent
            classicLauncher?.launch(signInIntent)
                ?: throw IllegalStateException("Classic sign-in launcher not registered")
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Error launching classic sign-in: ${e.message}")
            }
            signInContinuation?.resumeWithException(
                AuthenticationError.GoogleSignInError
            )
            signInContinuation = null
        }
    }
    
    /**
     * Handle One Tap Sign-In result
     */
    private fun handleOneTapResult(data: android.content.Intent?) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📨 Processing One Tap Sign-In result")
        }
        
        try {
            val credential = oneTapClient.getSignInCredentialFromIntent(data)
            val idToken = credential.googleIdToken
            
            if (idToken != null) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ One Tap ID token received, authenticating with Firebase")
                }
                authenticateWithFirebase(idToken)
            } else {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ No ID token in One Tap result")
                }
                signInContinuation?.resumeWithException(
                    AuthenticationError.GoogleSignInError
                )
                signInContinuation = null
            }
            
        } catch (e: ApiException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ One Tap Sign-In failed: ${e.message}")
            }
            signInContinuation?.resumeWithException(
                AuthenticationError.fromGoogleSignInException(e)
            )
            signInContinuation = null
        }
    }
    
    /**
     * Handle classic Google Sign-In result
     */
    private fun handleClassicSignInResult(data: android.content.Intent?) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "📨 Processing classic Google Sign-In result")
        }
        
        try {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            val account = task.getResult(ApiException::class.java)
            val idToken = account.idToken
            
            if (idToken != null) {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.d(TAG, "✅ Classic sign-in ID token received, authenticating with Firebase")
                }
                authenticateWithFirebase(idToken)
            } else {
                if (BuildConfig.ENABLE_LOGGING) {
                    Log.e(TAG, "❌ No ID token in classic sign-in result")
                }
                signInContinuation?.resumeWithException(
                    AuthenticationError.GoogleSignInError
                )
                signInContinuation = null
            }
            
        } catch (e: ApiException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Classic Google Sign-In failed: ${e.message}")
            }
            signInContinuation?.resumeWithException(
                AuthenticationError.fromGoogleSignInException(e)
            )
            signInContinuation = null
        }
    }
    
    /**
     * Authenticate with Firebase using Google ID token
     */
    private fun authenticateWithFirebase(idToken: String) {
        if (BuildConfig.ENABLE_LOGGING) {
            Log.d(TAG, "🔐 Authenticating with Firebase using Google ID token")
        }
        
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        
        firebaseAuth.signInWithCredential(credential)
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val firebaseUser = firebaseAuth.currentUser
                    if (firebaseUser != null) {
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.d(TAG, "✅ Firebase authentication successful: ${firebaseUser.uid}")
                        }
                        
                        val user = User.fromFirebaseUser(firebaseUser)
                        signInContinuation?.resume(user)
                    } else {
                        if (BuildConfig.ENABLE_LOGGING) {
                            Log.e(TAG, "❌ Firebase user is null after successful authentication")
                        }
                        signInContinuation?.resumeWithException(
                            AuthenticationError.Unknown("Authentication succeeded but user is null")
                        )
                    }
                } else {
                    val exception = task.exception
                    if (BuildConfig.ENABLE_LOGGING) {
                        Log.e(TAG, "❌ Firebase authentication failed: ${exception?.message}")
                    }
                    signInContinuation?.resumeWithException(
                        exception?.let { AuthenticationError.fromFirebaseException(it) }
                            ?: AuthenticationError.Unknown("Firebase authentication failed")
                    )
                }
                signInContinuation = null
            }
    }
    
    /**
     * Sign out from Google
     * Equivalent to iOS GoogleSignInService.signOut()
     */
    suspend fun signOut() {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🚪 Signing out from Google")
            }
            
            // Sign out from Google Sign-In
            googleSignInClient.signOut().await()
            
            // Clear One Tap state
            oneTapClient.signOut().await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Google sign-out successful")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Google sign-out error: ${e.message}")
            }
            // Don't throw error for sign-out failures - just log
        }
    }
    
    /**
     * Revoke Google access (complete disconnect)
     * Equivalent to iOS Google Sign-In revoke
     */
    suspend fun revokeAccess() {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🗑️ Revoking Google access")
            }
            
            googleSignInClient.revokeAccess().await()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Google access revoked successfully")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Google access revoke error: ${e.message}")
            }
            throw AuthenticationError.Unknown(
                customMessage = "Failed to revoke Google access: ${e.message}",
                throwable = e
            )
        }
    }
    
    /**
     * Check if user is signed in to Google
     */
    fun isSignedIn(): Boolean {
        val account = GoogleSignIn.getLastSignedInAccount(context)
        return account != null
    }
    
    /**
     * Get currently signed-in Google account
     */
    fun getCurrentAccount() = GoogleSignIn.getLastSignedInAccount(context)
}