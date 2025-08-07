package com.voicecontrol.app.authentication.model

import kotlinx.serialization.Serializable

/**
 * Subscription status model for Voice Control App
 * 
 * Direct port of iOS SubscriptionStatus enum to Kotlin sealed class
 * Manages subscription states, usage limits, and premium access
 * 
 * Features:
 * - Sealed class for exhaustive when expressions (equivalent to iOS enum)
 * - Usage tracking for free tier limitations
 * - Premium subscription management
 * - Apple App Store compliance via guest/free access
 */
@Serializable
sealed class SubscriptionStatus {
    
    /**
     * Premium subscription active - unlimited access
     * Equivalent to iOS .premium case
     */
    @Serializable
    object Premium : SubscriptionStatus()
    
    /**
     * Free tier with limited API access
     * Equivalent to iOS .free(remainingMinutes) case
     * 
     * @param remainingMinutes How many minutes of API usage remain
     */
    @Serializable
    data class Free(val remainingMinutes: Int) : SubscriptionStatus()
    
    /**
     * Subscription has expired
     * Equivalent to iOS .expired case
     */
    @Serializable
    object Expired : SubscriptionStatus()
    
    /**
     * Loading subscription status from server
     * Equivalent to iOS .loading case
     */
    @Serializable
    object Loading : SubscriptionStatus()
    
    /**
     * Unknown subscription status
     * Equivalent to iOS .unknown case
     */
    @Serializable
    object Unknown : SubscriptionStatus()
    
    /**
     * Error checking subscription status
     * Equivalent to iOS .error case
     */
    @Serializable
    data class Error(val message: String) : SubscriptionStatus()
    
    // MARK: - Convenience Properties
    
    /**
     * Check if user has premium access
     * Equivalent to iOS computed property
     */
    val isPremium: Boolean
        get() = this is Premium
    
    /**
     * Check if user is on free tier
     * Equivalent to iOS computed property
     */
    val isFree: Boolean
        get() = this is Free
    
    /**
     * Check if subscription has expired
     * Equivalent to iOS computed property
     */
    val isExpired: Boolean
        get() = this is Expired
    
    /**
     * Check if status is loading
     * Equivalent to iOS computed property
     */
    val isLoading: Boolean
        get() = this is Loading
    
    /**
     * Check if there's an error
     * Equivalent to iOS computed property
     */
    val hasError: Boolean
        get() = this is Error
    
    /**
     * Check if user can access API features
     * Equivalent to iOS computed property
     */
    val canAccessAPI: Boolean
        get() = when (this) {
            is Premium -> true
            is Free -> remainingMinutes > 0
            else -> false
        }
    
    /**
     * Get remaining minutes (0 for premium/unlimited)
     * Equivalent to iOS computed property
     */
    val totalRemainingMinutes: Int
        get() = when (this) {
            is Premium -> Int.MAX_VALUE // Unlimited
            is Free -> remainingMinutes
            else -> 0
        }
    
    /**
     * Get display text for UI
     * Equivalent to iOS computed property
     */
    val displayText: String
        get() = when (this) {
            is Premium -> "Voice Control Pro"
            is Free -> "$remainingMinutes minutes remaining"
            is Expired -> "Subscription expired"
            is Loading -> "Checking subscription..."
            is Unknown -> "Unknown status"
            is Error -> "Subscription error"
        }
    
    /**
     * Get status color for UI theming
     * Equivalent to iOS computed property
     */
    val statusColor: SubscriptionStatusColor
        get() = when (this) {
            is Premium -> SubscriptionStatusColor.Premium
            is Free -> if (remainingMinutes > 5) SubscriptionStatusColor.Normal else SubscriptionStatusColor.Warning
            is Expired -> SubscriptionStatusColor.Error
            is Loading -> SubscriptionStatusColor.Loading
            is Unknown -> SubscriptionStatusColor.Unknown
            is Error -> SubscriptionStatusColor.Error
        }
}

/**
 * Color scheme for subscription status display
 * Equivalent to iOS color extensions
 */
enum class SubscriptionStatusColor {
    Premium,    // Gold/Premium colors
    Normal,     // Standard blue/green
    Warning,    // Orange for low usage
    Error,      // Red for expired/errors
    Loading,    // Gray for loading
    Unknown     // Neutral gray
}

/**
 * Subscription plan types
 * Equivalent to iOS SubscriptionPlan enum
 */
@Serializable
enum class SubscriptionPlan(
    val id: String,
    val displayName: String,
    val monthlyPrice: String,
    val features: List<String>
) {
    FREE(
        id = "free",
        displayName = "Voice Control Free",
        monthlyPrice = "$0",
        features = listOf(
            "30 minutes of voice commands per month",
            "Basic Yamaha console control",
            "Email support"
        )
    ),
    
    PRO(
        id = "voice_control_pro",
        displayName = "Voice Control Pro",
        monthlyPrice = "$9.99",
        features = listOf(
            "Unlimited voice commands",
            "Advanced Yamaha console control",
            "Real-time speech recognition",
            "Priority email support",
            "Advanced voice command customization",
            "Cloud sync across devices"
        )
    );
    
    /**
     * Check if this is the free plan
     */
    val isFree: Boolean get() = this == FREE
    
    /**
     * Check if this is a premium plan
     */
    val isPremium: Boolean get() = this == PRO
}

/**
 * Subscription state for UI management
 * Equivalent to iOS SubscriptionState enum
 */
@Serializable
sealed class SubscriptionState {
    /**
     * Premium subscription active
     */
    @Serializable
    object Premium : SubscriptionState()
    
    /**
     * Free tier with usage tracking
     */
    @Serializable
    data class Free(val remainingMinutes: Int) : SubscriptionState()
    
    /**
     * Subscription expired - needs renewal
     */
    @Serializable
    object Expired : SubscriptionState()
    
    /**
     * Loading subscription information
     */
    @Serializable
    object Loading : SubscriptionState()
    
    /**
     * Unknown state - needs refresh
     */
    @Serializable
    object Unknown : SubscriptionState()
    
    /**
     * Error loading subscription data
     */
    @Serializable
    data class Error(val message: String) : SubscriptionState()
}