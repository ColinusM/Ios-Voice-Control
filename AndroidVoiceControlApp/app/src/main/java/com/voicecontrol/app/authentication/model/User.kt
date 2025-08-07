package com.voicecontrol.app.authentication.model

import com.google.firebase.auth.FirebaseUser
import kotlinx.serialization.Serializable
import java.util.*

/**
 * User model for Voice Control App
 * 
 * Direct port of iOS User struct to Kotlin data class with Serialization support
 * Represents authenticated user with comprehensive profile information
 * 
 * Features:
 * - Serializable for secure storage (equivalent to iOS Codable)
 * - Firebase integration with automatic user creation
 * - Social authentication support (Google, etc.)
 * - Comprehensive user profile management
 * - Secure authentication token handling
 */
@Serializable
data class User(
    /**
     * Unique user identifier (Firebase UID)
     * Equivalent to iOS User.id
     */
    val id: String,
    
    /**
     * User's email address (primary identifier)
     * Equivalent to iOS User.email
     */
    val email: String,
    
    /**
     * User's display name (full name or chosen display name)
     * Equivalent to iOS User.displayName
     */
    val displayName: String?,
    
    /**
     * URL to user's profile photo
     * Equivalent to iOS User.photoURL
     */
    val photoUrl: String?,
    
    /**
     * Whether the user's email has been verified
     * Equivalent to iOS User.isEmailVerified
     */
    val isEmailVerified: Boolean,
    
    /**
     * User creation timestamp
     * Equivalent to iOS User.creationDate
     */
    val creationDate: Long,
    
    /**
     * Last sign-in timestamp
     * Equivalent to iOS User.lastSignInDate
     */
    val lastSignInDate: Long,
    
    /**
     * Authentication provider used (password, google.com, etc.)
     * Equivalent to iOS User.providerID
     */
    val providerId: String?,
    
    /**
     * Whether this is a premium/subscribed user
     * Equivalent to iOS User.isPremium
     */
    val isPremium: Boolean = false,
    
    /**
     * User's subscription status
     * Equivalent to iOS User.subscriptionStatus
     */
    val subscriptionStatus: SubscriptionStatus = SubscriptionStatus.Free(remainingMinutes = 30)
) {
    
    /**
     * Get user's first name from display name
     * Equivalent to iOS computed property
     */
    val firstName: String?
        get() = displayName?.split(" ")?.firstOrNull()
    
    /**
     * Get user's last name from display name  
     * Equivalent to iOS computed property
     */
    val lastName: String?
        get() = displayName?.split(" ")?.drop(1)?.joinToString(" ")?.takeIf { it.isNotEmpty() }
    
    /**
     * Get initials for avatar display
     * Equivalent to iOS computed property
     */
    val initials: String
        get() {
            return if (displayName.isNullOrEmpty()) {
                email.take(2).uppercase()
            } else {
                displayName.split(" ")
                    .mapNotNull { it.firstOrNull()?.toString() }
                    .take(2)
                    .joinToString("")
                    .uppercase()
            }
        }
    
    /**
     * Check if user signed in with social provider
     * Equivalent to iOS computed property
     */
    val isFromSocialProvider: Boolean
        get() = providerId != null && providerId != "password"
    
    /**
     * Get readable provider name
     * Equivalent to iOS computed property
     */
    val providerDisplayName: String
        get() = when (providerId) {
            "google.com" -> "Google"
            "password" -> "Email/Password"
            "apple.com" -> "Apple"
            null -> "Unknown"
            else -> providerId.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
        }
    
    companion object {
        /**
         * Create User from Firebase User
         * Equivalent to iOS User.from(firebaseUser:)
         */
        fun fromFirebaseUser(firebaseUser: FirebaseUser): User {
            return User(
                id = firebaseUser.uid,
                email = firebaseUser.email ?: "",
                displayName = firebaseUser.displayName,
                photoUrl = firebaseUser.photoUrl?.toString(),
                isEmailVerified = firebaseUser.isEmailVerified,
                creationDate = firebaseUser.metadata?.creationTimestamp ?: System.currentTimeMillis(),
                lastSignInDate = firebaseUser.metadata?.lastSignInTimestamp ?: System.currentTimeMillis(),
                providerId = firebaseUser.providerData.firstOrNull()?.providerId
            )
        }
        
        /**
         * Create User from social authentication result
         * Equivalent to iOS User from SocialAuthResult.toUser()
         */
        fun fromSocialAuth(
            id: String,
            email: String,
            displayName: String?,
            photoUrl: String?,
            providerId: String
        ): User {
            val currentTime = System.currentTimeMillis()
            return User(
                id = id,
                email = email,
                displayName = displayName,
                photoUrl = photoUrl,
                isEmailVerified = true, // Social providers typically verify emails
                creationDate = currentTime,
                lastSignInDate = currentTime,
                providerId = providerId
            )
        }
        
        /**
         * Create mock user for testing
         * Equivalent to iOS User.mock
         */
        fun mock(): User {
            return User(
                id = "mock_user_123",
                email = "test@voicecontrol.app",
                displayName = "Test User",
                photoUrl = null,
                isEmailVerified = true,
                creationDate = System.currentTimeMillis() - 86400000, // 1 day ago
                lastSignInDate = System.currentTimeMillis(),
                providerId = "password",
                isPremium = false
            )
        }
    }
}

/**
 * Guest User model for Apple App Store compliance
 * 
 * Direct port of iOS GuestUser struct
 * Manages temporary access without requiring account creation
 */
@Serializable
data class GuestUser(
    /**
     * Unique guest session ID
     * Equivalent to iOS GuestUser.id
     */
    val id: String = UUID.randomUUID().toString(),
    
    /**
     * Guest session creation date
     * Equivalent to iOS GuestUser.creationDate
     */
    val creationDate: Long = System.currentTimeMillis(),
    
    /**
     * Total API minutes used by this guest
     * Equivalent to iOS GuestUser.totalAPIMinutesUsed
     */
    val totalAPIMinutesUsed: Int = 0,
    
    /**
     * Free tier limit for guest users
     * Equivalent to iOS GuestUser.freeMinutesLimit
     */
    val freeMinutesLimit: Int = 30
) {
    
    /**
     * Check if guest can make API calls
     * Equivalent to iOS computed property
     */
    val canMakeAPICall: Boolean
        get() = totalAPIMinutesUsed < freeMinutesLimit
    
    /**
     * Remaining free minutes
     * Equivalent to iOS computed property
     */
    val remainingFreeMinutes: Int
        get() = maxOf(0, freeMinutesLimit - totalAPIMinutesUsed)
    
    /**
     * Guest display name
     * Equivalent to iOS computed property
     */
    val displayName: String
        get() = "Guest User"
    
    /**
     * Guest initials
     * Equivalent to iOS computed property
     */
    val initials: String
        get() = "GU"
    
    /**
     * Usage percentage
     * Equivalent to iOS computed property
     */
    val usagePercentage: Float
        get() = (totalAPIMinutesUsed.toFloat() / freeMinutesLimit.toFloat()).coerceIn(0f, 1f)
    
    /**
     * Increment usage by specified minutes
     * Equivalent to iOS GuestUser.incrementUsage()
     */
    fun incrementUsage(minutes: Int): GuestUser {
        return copy(totalAPIMinutesUsed = totalAPIMinutesUsed + minutes)
    }
    
    /**
     * Check if upgrade is recommended
     * Equivalent to iOS computed property
     */
    val shouldShowUpgradePrompt: Boolean
        get() = usagePercentage >= 0.8f // Show at 80% usage
    
    /**
     * Get description for logging
     * Equivalent to iOS description computed property
     */
    val description: String
        get() = "GuestUser(id: ${id.take(8)}, usage: $totalAPIMinutesUsed/$freeMinutesLimit minutes)"
}