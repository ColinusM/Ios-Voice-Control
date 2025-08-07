package com.voicecontrol.app.authentication.model

/**
 * Authentication state representation for Voice Control App
 * 
 * Direct port of iOS AuthState enum to Kotlin sealed class
 * Manages all possible authentication states with type safety
 * 
 * Features:
 * - Sealed class for exhaustive when expressions (equivalent to iOS enum)
 * - Comprehensive state management including guest mode
 * - Error handling with specific error types
 * - Biometric authentication support
 * - Apple App Store compliance via guest mode
 */
sealed class AuthState {
    
    /**
     * User is not authenticated and needs to sign in
     * Equivalent to iOS .unauthenticated case
     */
    object Unauthenticated : AuthState()
    
    /**
     * Authentication in progress (loading state)
     * Equivalent to iOS .authenticating case
     */
    object Authenticating : AuthState()
    
    /**
     * User is fully authenticated and can access the app
     * Equivalent to iOS .authenticated case
     */
    object Authenticated : AuthState()
    
    /**
     * User requires biometric authentication to proceed
     * Equivalent to iOS .requiresBiometric case
     */
    object RequiresBiometric : AuthState()
    
    /**
     * Guest mode - limited access without account (Apple App Store compliance)
     * Equivalent to iOS .guest case
     */
    object Guest : AuthState()
    
    /**
     * Authentication error occurred
     * Equivalent to iOS .error(AuthenticationError) case
     * 
     * @param error The specific authentication error that occurred
     */
    data class Error(val error: AuthenticationError) : AuthState()
    
    // MARK: - Convenience Properties
    
    /**
     * Check if user is currently authenticated (full access)
     */
    val isAuthenticated: Boolean
        get() = this is Authenticated
    
    /**
     * Check if user is in guest mode
     */
    val isGuest: Boolean
        get() = this is Guest
    
    /**
     * Check if authentication is in progress
     */
    val isLoading: Boolean
        get() = this is Authenticating
    
    /**
     * Check if there's an authentication error
     */
    val hasError: Boolean
        get() = this is Error
    
    /**
     * Check if user needs biometric authentication
     */
    val requiresBiometric: Boolean
        get() = this is RequiresBiometric
    
    /**
     * Check if user has any form of access (authenticated or guest)
     */
    val hasAccess: Boolean
        get() = isAuthenticated || isGuest
    
    /**
     * Get error message if in error state
     */
    val errorMessage: String?
        get() = if (this is Error) error.message else null
}

/**
 * Authentication error types
 * 
 * Direct port of iOS AuthenticationError enum
 * Comprehensive error handling for all authentication scenarios
 */
sealed class AuthenticationError(
    val message: String,
    val code: String? = null,
    cause: Throwable? = null
) : Exception(message, cause) {
    
    /**
     * Invalid email format
     */
    object InvalidEmail : AuthenticationError(
        message = "Please enter a valid email address",
        code = "invalid_email"
    )
    
    /**
     * Password doesn't meet requirements
     */
    object WeakPassword : AuthenticationError(
        message = "Password must be at least 8 characters long",
        code = "weak_password"
    )
    
    /**
     * Email already exists during signup
     */
    object EmailAlreadyExists : AuthenticationError(
        message = "An account with this email already exists",
        code = "email_already_exists"
    )
    
    /**
     * User not found (invalid credentials)
     */
    object UserNotFound : AuthenticationError(
        message = "No account found with this email address",
        code = "user_not_found"
    )
    
    /**
     * Incorrect password
     */
    object WrongPassword : AuthenticationError(
        message = "Incorrect password. Please try again",
        code = "wrong_password"
    )
    
    /**
     * Too many failed sign-in attempts
     */
    object TooManyAttempts : AuthenticationError(
        message = "Too many failed attempts. Please try again later",
        code = "too_many_attempts"
    )
    
    /**
     * Network connectivity issues
     */
    object NetworkError : AuthenticationError(
        message = "Network connection error. Please check your internet connection",
        code = "network_error"
    )
    
    /**
     * Google Sign-In specific errors
     */
    object GoogleSignInError : AuthenticationError(
        message = "Google Sign-In failed. Please try again",
        code = "google_signin_error"
    )
    
    /**
     * Biometric authentication errors
     */
    sealed class BiometricError(message: String, code: String) : AuthenticationError(message, code) {
        object NotAvailable : BiometricError(
            message = "Biometric authentication is not available on this device",
            code = "biometric_not_available"
        )
        
        object NotEnrolled : BiometricError(
            message = "No biometric credentials are enrolled. Please set up fingerprint or face recognition in Settings",
            code = "biometric_not_enrolled"
        )
        
        object AuthenticationFailed : BiometricError(
            message = "Biometric authentication failed. Please try again",
            code = "biometric_failed"
        )
        
        object UserCancelled : BiometricError(
            message = "Biometric authentication was cancelled",
            code = "biometric_cancelled"
        )
    }
    
    /**
     * API usage limits reached (guest mode)
     */
    object UsageLimitReached : AuthenticationError(
        message = "Usage limit reached. Please upgrade to Voice Control Pro for unlimited access",
        code = "usage_limit_reached"
    )
    
    /**
     * Account requires email verification
     */
    object EmailNotVerified : AuthenticationError(
        message = "Please verify your email address before continuing",
        code = "email_not_verified"
    )
    
    /**
     * Account has been disabled
     */
    object AccountDisabled : AuthenticationError(
        message = "This account has been disabled. Please contact support",
        code = "account_disabled"
    )
    
    /**
     * Generic/unknown error with custom message
     */
    data class Unknown(val customMessage: String, val throwable: Throwable? = null) : AuthenticationError(
        message = customMessage,
        code = "unknown_error",
        cause = throwable
    )
    
    companion object {
        /**
         * Convert Firebase Auth exceptions to AuthenticationError
         * Equivalent to iOS AuthenticationError.fromFirebaseError()
         */
        fun fromFirebaseException(exception: Exception): AuthenticationError {
            return when {
                exception.message?.contains("invalid-email") == true -> InvalidEmail
                exception.message?.contains("weak-password") == true -> WeakPassword
                exception.message?.contains("email-already-in-use") == true -> EmailAlreadyExists
                exception.message?.contains("user-not-found") == true -> UserNotFound
                exception.message?.contains("wrong-password") == true -> WrongPassword
                exception.message?.contains("too-many-requests") == true -> TooManyAttempts
                exception.message?.contains("network") == true -> NetworkError
                exception.message?.contains("user-disabled") == true -> AccountDisabled
                else -> Unknown(
                    customMessage = exception.message ?: "An unknown authentication error occurred",
                    throwable = exception
                )
            }
        }
        
        /**
         * Convert Google Sign-In exceptions to AuthenticationError
         * Equivalent to iOS AuthenticationError.from(socialError)
         */
        fun fromGoogleSignInException(exception: Exception): AuthenticationError {
            return when {
                exception.message?.contains("cancelled") == true -> GoogleSignInError
                exception.message?.contains("network") == true -> NetworkError
                else -> Unknown(
                    customMessage = "Google Sign-In failed: ${exception.message}",
                    throwable = exception
                )
            }
        }
    }
}