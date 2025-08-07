package com.voicecontrol.app.ui.screen.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import com.voicecontrol.app.authentication.model.AuthState
import com.voicecontrol.app.authentication.viewmodel.AuthenticationViewModel
import com.voicecontrol.app.ui.component.auth.SignInCard
import com.voicecontrol.app.ui.component.auth.WelcomeHeader
import com.voicecontrol.app.ui.component.common.ErrorMessage
import com.voicecontrol.app.ui.component.common.LoadingIndicator
import com.voicecontrol.app.ui.theme.VoiceControlTheme

/**
 * Authentication Screen for Voice Control App
 * 
 * Direct port of iOS AuthenticationView and WelcomeView to Compose
 * Handles user authentication flow with email/password and Google Sign-In
 * 
 * Features:
 * - Welcome header with app branding (equivalent to iOS WelcomeView)
 * - Email/password sign-in form (equivalent to iOS SignInView)
 * - Google Sign-In integration (equivalent to iOS GoogleSignInButton)
 * - Guest mode access (Apple App Store compliance)
 * - Error handling and loading states
 * - Responsive layout with keyboard handling
 * - Accessibility support
 * 
 * @param authViewModel Authentication view model for state management
 * @param onNavigateToMain Callback to navigate to main screen after successful auth
 * @param onNavigateToBiometric Callback to navigate to biometric auth if required
 */
@Composable
fun AuthenticationScreen(
    authViewModel: AuthenticationViewModel,
    onNavigateToMain: () -> Unit,
    onNavigateToBiometric: () -> Unit
) {
    val authState by authViewModel.authState.collectAsState()
    val isLoading by authViewModel.isLoading.collectAsState()
    val errorMessage by authViewModel.errorMessage.collectAsState()
    val context = LocalContext.current
    
    // Handle navigation based on authentication state changes
    LaunchedEffect(authState) {
        when (authState) {
            is AuthState.Authenticated -> onNavigateToMain()
            is AuthState.RequiresBiometric -> onNavigateToBiometric()
            is AuthState.Guest -> onNavigateToMain()
            else -> {
                // Stay on authentication screen
            }
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        // MARK: - Welcome Header
        WelcomeHeader(
            modifier = Modifier.padding(top = 32.dp, bottom = 32.dp)
        )
        
        // MARK: - Authentication Card
        SignInCard(
            authViewModel = authViewModel,
            isLoading = isLoading,
            onGoogleSignIn = {
                // Google Sign-In requires FragmentActivity
                val activity = context as? FragmentActivity
                if (activity != null) {
                    authViewModel.signInWithGoogle(activity)
                }
            },
            onGuestMode = {
                authViewModel.enterGuestMode()
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp)
        )
        
        // MARK: - Error Message
        errorMessage?.let { error ->
            ErrorMessage(
                message = error,
                onDismiss = { authViewModel.clearError() },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            )
        }
        
        // MARK: - Loading Indicator
        if (isLoading && authState is AuthState.Authenticating) {
            LoadingIndicator(
                message = "Signing you in...",
                modifier = Modifier.padding(top = 16.dp)
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // MARK: - Footer Information
        AuthenticationFooter(
            modifier = Modifier.padding(vertical = 16.dp)
        )
    }
}

/**
 * Footer with app information and legal links
 * Equivalent to iOS authentication footer
 */
@Composable
private fun AuthenticationFooter(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Voice Control for Professional Audio",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            TextButton(
                onClick = { /* TODO: Open privacy policy */ }
            ) {
                Text(
                    text = "Privacy Policy",
                    style = MaterialTheme.typography.labelSmall
                )
            }
            
            TextButton(
                onClick = { /* TODO: Open terms of service */ }
            ) {
                Text(
                    text = "Terms of Service",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Version 1.0 • Built for iOS compatibility",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun AuthenticationScreenPreview() {
    VoiceControlTheme {
        AuthenticationScreenContent(
            isLoading = false,
            errorMessage = null,
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { },
            onClearError = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun AuthenticationScreenLoadingPreview() {
    VoiceControlTheme {
        AuthenticationScreenContent(
            isLoading = true,
            errorMessage = null,
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { },
            onClearError = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun AuthenticationScreenErrorPreview() {
    VoiceControlTheme {
        AuthenticationScreenContent(
            isLoading = false,
            errorMessage = "Invalid email or password. Please try again.",
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { },
            onClearError = { }
        )
    }
}

/**
 * Content composable for previews
 * Separates UI from ViewModel dependency for preview purposes
 */
@Composable
private fun AuthenticationScreenContent(
    isLoading: Boolean,
    errorMessage: String?,
    onSignIn: (String, String) -> Unit,
    onSignUp: (String, String, String?) -> Unit,
    onGoogleSignIn: () -> Unit,
    onGuestMode: () -> Unit,
    onClearError: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        WelcomeHeader(
            modifier = Modifier.padding(top = 32.dp, bottom = 32.dp)
        )
        
        // Mock SignInCard for preview - actual component will be created separately
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Sign In Card",
                    style = MaterialTheme.typography.headlineSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                if (isLoading) {
                    CircularProgressIndicator()
                } else {
                    Button(
                        onClick = { onSignIn("test@example.com", "password") },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Sign In")
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    OutlinedButton(
                        onClick = onGoogleSignIn,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Sign in with Google")
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    TextButton(
                        onClick = onGuestMode,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Continue as Guest")
                    }
                }
            }
        }
        
        errorMessage?.let { error ->
            ErrorMessage(
                message = error,
                onDismiss = onClearError,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        AuthenticationFooter(
            modifier = Modifier.padding(vertical = 16.dp)
        )
    }
}