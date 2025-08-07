package com.voicecontrol.app.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.voicecontrol.app.authentication.model.AuthState
import com.voicecontrol.app.authentication.viewmodel.AuthenticationViewModel
import com.voicecontrol.app.ui.screen.auth.AuthenticationScreen
import com.voicecontrol.app.ui.screen.auth.BiometricAuthScreen
import com.voicecontrol.app.ui.screen.main.VoiceControlMainScreen

/**
 * Navigation Routes for Voice Control App
 * 
 * Equivalent to iOS NavigationView destination enum
 * Defines all possible navigation destinations in the app
 */
object VoiceControlRoutes {
    const val AUTHENTICATION = "authentication"
    const val BIOMETRIC_AUTH = "biometric_auth"
    const val MAIN = "main"
    const val SETTINGS = "settings"
    const val NETWORK_SETTINGS = "network_settings"
    const val SUBSCRIPTION = "subscription"
}

/**
 * Main Navigation Component for Voice Control App
 * 
 * Equivalent to iOS ContentView navigation logic and NavigationView
 * Handles authentication-based routing and screen transitions
 * 
 * Features:
 * - Authentication state-based routing (equivalent to iOS conditional views)
 * - Smooth transitions between auth and main app screens
 * - Deep linking support for settings and features
 * - Back stack management with proper state preservation
 * 
 * @param authState Current authentication state
 * @param authViewModel Authentication view model for state management
 */
@Composable
fun VoiceControlNavigation(
    authState: AuthState,
    authViewModel: AuthenticationViewModel,
    hasMicrophonePermission: () -> Boolean = { false },
    requestMicrophonePermission: (((Boolean) -> Unit)?) -> Unit = {}
) {
    val navController = rememberNavController()
    
    // Determine start destination based on auth state
    // Equivalent to iOS NavigationView conditional view presentation
    val startDestination = when (authState) {
        is AuthState.Authenticated -> VoiceControlRoutes.MAIN
        is AuthState.RequiresBiometric -> VoiceControlRoutes.BIOMETRIC_AUTH
        is AuthState.Guest -> VoiceControlRoutes.MAIN
        else -> VoiceControlRoutes.AUTHENTICATION
    }
    
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        
        // MARK: - Authentication Flow
        
        /**
         * Authentication Screen
         * Equivalent to iOS AuthenticationView and WelcomeView
         */
        composable(VoiceControlRoutes.AUTHENTICATION) {
            AuthenticationScreen(
                authViewModel = authViewModel,
                onNavigateToMain = {
                    // Clear back stack and navigate to main
                    navController.navigate(VoiceControlRoutes.MAIN) {
                        popUpTo(VoiceControlRoutes.AUTHENTICATION) { inclusive = true }
                    }
                },
                onNavigateToBiometric = {
                    navController.navigate(VoiceControlRoutes.BIOMETRIC_AUTH)
                }
            )
        }
        
        /**
         * Biometric Authentication Screen
         * Equivalent to iOS biometric authentication prompt
         */
        composable(VoiceControlRoutes.BIOMETRIC_AUTH) {
            BiometricAuthScreen(
                authViewModel = authViewModel,
                onBiometricSuccess = {
                    // Clear back stack and navigate to main
                    navController.navigate(VoiceControlRoutes.MAIN) {
                        popUpTo(VoiceControlRoutes.AUTHENTICATION) { inclusive = true }
                    }
                },
                onBiometricSkip = {
                    // Allow skip to main app (equivalent to iOS bypass)
                    navController.navigate(VoiceControlRoutes.MAIN) {
                        popUpTo(VoiceControlRoutes.AUTHENTICATION) { inclusive = true }
                    }
                },
                onSignOut = {
                    // Return to authentication
                    navController.navigate(VoiceControlRoutes.AUTHENTICATION) {
                        popUpTo(0) // Clear entire back stack
                    }
                }
            )
        }
        
        // MARK: - Main App Flow
        
        /**
         * Main Voice Control Screen
         * Equivalent to iOS VoiceControlMainView
         */
        composable(VoiceControlRoutes.MAIN) {
            VoiceControlMainScreen(
                authViewModel = authViewModel,
                hasMicrophonePermission = hasMicrophonePermission,
                requestMicrophonePermission = requestMicrophonePermission,
                onNavigateToSettings = {
                    navController.navigate(VoiceControlRoutes.SETTINGS)
                },
                onNavigateToNetworkSettings = {
                    navController.navigate(VoiceControlRoutes.NETWORK_SETTINGS)
                },
                onNavigateToSubscription = {
                    navController.navigate(VoiceControlRoutes.SUBSCRIPTION)
                },
                onSignOut = {
                    // Return to authentication and clear back stack
                    navController.navigate(VoiceControlRoutes.AUTHENTICATION) {
                        popUpTo(0) // Clear entire back stack
                    }
                }
            )
        }
        
        // MARK: - Settings Flow
        
        /**
         * Settings Screen
         * Equivalent to iOS SettingsView
         */
        composable(VoiceControlRoutes.SETTINGS) {
            // TODO: Implement SettingsScreen
            /*
            SettingsScreen(
                authViewModel = authViewModel,
                onNavigateBack = {
                    navController.navigateUp()
                },
                onNavigateToNetworkSettings = {
                    navController.navigate(VoiceControlRoutes.NETWORK_SETTINGS)
                },
                onNavigateToSubscription = {
                    navController.navigate(VoiceControlRoutes.SUBSCRIPTION)
                }
            )
            */
        }
        
        /**
         * Network Settings Screen
         * Equivalent to iOS NetworkSettingsView
         */
        composable(VoiceControlRoutes.NETWORK_SETTINGS) {
            // TODO: Implement NetworkSettingsScreen
            /*
            NetworkSettingsScreen(
                onNavigateBack = {
                    navController.navigateUp()
                }
            )
            */
        }
        
        /**
         * Subscription Screen
         * Equivalent to iOS SubscriptionView
         */
        composable(VoiceControlRoutes.SUBSCRIPTION) {
            // TODO: Implement SubscriptionScreen
            /*
            SubscriptionScreen(
                authViewModel = authViewModel,
                onNavigateBack = {
                    navController.navigateUp()
                },
                onSubscriptionSuccess = {
                    navController.navigateUp()
                }
            )
            */
        }
    }
}

/**
 * Navigation Actions Helper
 * 
 * Equivalent to iOS navigation coordinator functions
 * Provides centralized navigation logic for complex flows
 */
object VoiceControlNavigationActions {
    
    /**
     * Handle authentication success navigation
     * Equivalent to iOS post-authentication navigation
     */
    fun handleAuthSuccess(
        authState: AuthState,
        onNavigateToMain: () -> Unit,
        onNavigateToBiometric: () -> Unit
    ) {
        when (authState) {
            is AuthState.Authenticated -> onNavigateToMain()
            is AuthState.RequiresBiometric -> onNavigateToBiometric()
            is AuthState.Guest -> onNavigateToMain()
            else -> {
                // Stay on current screen for other states
            }
        }
    }
    
    /**
     * Handle sign out navigation
     * Equivalent to iOS sign out flow
     */
    fun handleSignOut(
        onNavigateToAuth: () -> Unit
    ) {
        onNavigateToAuth()
    }
    
    /**
     * Handle deep link navigation
     * Equivalent to iOS deep linking and URL scheme handling
     */
    fun handleDeepLink(
        deepLink: String,
        authState: AuthState,
        onNavigateToRoute: (String) -> Unit
    ) {
        // Only allow deep links if authenticated
        if (authState.hasAccess) {
            when (deepLink) {
                "settings" -> onNavigateToRoute(VoiceControlRoutes.SETTINGS)
                "network" -> onNavigateToRoute(VoiceControlRoutes.NETWORK_SETTINGS)
                "subscription" -> onNavigateToRoute(VoiceControlRoutes.SUBSCRIPTION)
                else -> onNavigateToRoute(VoiceControlRoutes.MAIN)
            }
        } else {
            // Redirect to authentication for unauthenticated deep links
            onNavigateToRoute(VoiceControlRoutes.AUTHENTICATION)
        }
    }
}