package com.voicecontrol.app.ui.screen.auth

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Security
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
import com.voicecontrol.app.ui.component.common.ErrorMessage
import com.voicecontrol.app.ui.component.common.LoadingIndicator
import com.voicecontrol.app.ui.theme.VoiceControlTheme

/**
 * Biometric Authentication Screen for Voice Control App
 * 
 * Direct port of iOS biometric authentication prompt to Compose
 * Handles Face ID/Touch ID equivalent using Android BiometricPrompt
 * 
 * Features:
 * - Biometric authentication prompt (equivalent to iOS LocalAuthentication)
 * - Fallback options for biometric failures
 * - Skip option for user convenience
 * - Error handling and retry logic
 * - Professional security-focused UI design
 * - Accessibility support
 * 
 * @param authViewModel Authentication view model for state management
 * @param onBiometricSuccess Callback when biometric authentication succeeds
 * @param onBiometricSkip Callback when user chooses to skip biometric auth
 * @param onSignOut Callback to return to authentication screen
 */
@Composable
fun BiometricAuthScreen(
    authViewModel: AuthenticationViewModel,
    onBiometricSuccess: () -> Unit,
    onBiometricSkip: () -> Unit,
    onSignOut: () -> Unit
) {
    val authState by authViewModel.authState.collectAsState()
    val isLoading by authViewModel.isLoading.collectAsState()
    val errorMessage by authViewModel.errorMessage.collectAsState()
    val context = LocalContext.current
    
    // Handle successful biometric authentication
    LaunchedEffect(authState) {
        when (authState) {
            is AuthState.Authenticated -> onBiometricSuccess()
            else -> {
                // Continue showing biometric prompt
            }
        }
    }
    
    // Auto-trigger biometric prompt when screen loads
    LaunchedEffect(Unit) {
        val activity = context as? FragmentActivity
        if (activity != null) {
            authViewModel.authenticateWithBiometric(activity)
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        
        // MARK: - Biometric Icon and Header
        BiometricHeader(
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        // MARK: - Status Message
        StatusMessage(
            isLoading = isLoading,
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        // MARK: - Error Message
        errorMessage?.let { error ->
            ErrorMessage(
                message = error,
                onDismiss = { authViewModel.clearError() },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
            )
        }
        
        // MARK: - Action Buttons
        BiometricActionButtons(
            authViewModel = authViewModel,
            isLoading = isLoading,
            onBiometricSkip = onBiometricSkip,
            onSignOut = onSignOut,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        // MARK: - Security Information
        SecurityFooter(
            modifier = Modifier.padding(vertical = 16.dp)
        )
    }
}

/**
 * Biometric authentication header with icon and title
 * Equivalent to iOS biometric prompt header
 */
@Composable
private fun BiometricHeader(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        // Security Icon
        Card(
            modifier = Modifier.size(80.dp),
            shape = MaterialTheme.shapes.large,
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Fingerprint,
                    contentDescription = "Biometric authentication",
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Title
        Text(
            text = "Biometric Authentication",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Subtitle
        Text(
            text = "Use your fingerprint or face to securely access Voice Control",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}

/**
 * Status message showing current authentication state
 * Equivalent to iOS biometric prompt status
 */
@Composable
private fun StatusMessage(
    isLoading: Boolean,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        if (isLoading) {
            LoadingIndicator(
                message = "Waiting for biometric authentication...",
                modifier = Modifier.padding(16.dp)
            )
        } else {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                shape = MaterialTheme.shapes.medium
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Security,
                        contentDescription = "Security",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Text(
                        text = "Touch the fingerprint sensor or look at your device to continue",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

/**
 * Action buttons for biometric authentication flow
 * Equivalent to iOS biometric prompt action buttons
 */
@Composable
private fun BiometricActionButtons(
    authViewModel: AuthenticationViewModel,
    isLoading: Boolean,
    onBiometricSkip: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        
        // Retry Biometric Button
        Button(
            onClick = {
                val activity = context as? FragmentActivity
                if (activity != null) {
                    authViewModel.authenticateWithBiometric(activity)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Fingerprint,
                    contentDescription = "Fingerprint",
                    modifier = Modifier.size(20.dp)
                )
                Text("Try Again")
            }
        }
        
        // Skip Biometric Button
        OutlinedButton(
            onClick = onBiometricSkip,
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            Text("Skip for Now")
        }
        
        // Sign Out Button
        TextButton(
            onClick = onSignOut,
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            Text(
                text = "Sign Out",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.error
            )
        }
    }
}

/**
 * Security information footer
 * Equivalent to iOS security disclaimer
 */
@Composable
private fun SecurityFooter(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Your biometric data is stored securely on this device and never shared.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "You can disable biometric authentication in Settings at any time.",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun BiometricAuthScreenPreview() {
    VoiceControlTheme {
        BiometricAuthScreenContent(
            isLoading = false,
            errorMessage = null,
            onRetryBiometric = { },
            onSkip = { },
            onSignOut = { },
            onClearError = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun BiometricAuthScreenLoadingPreview() {
    VoiceControlTheme {
        BiometricAuthScreenContent(
            isLoading = true,
            errorMessage = null,
            onRetryBiometric = { },
            onSkip = { },
            onSignOut = { },
            onClearError = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun BiometricAuthScreenErrorPreview() {
    VoiceControlTheme {
        BiometricAuthScreenContent(
            isLoading = false,
            errorMessage = "Biometric authentication failed. Please try again or skip for now.",
            onRetryBiometric = { },
            onSkip = { },
            onSignOut = { },
            onClearError = { }
        )
    }
}

/**
 * Content composable for previews
 * Separates UI from ViewModel dependency for preview purposes
 */
@Composable
private fun BiometricAuthScreenContent(
    isLoading: Boolean,
    errorMessage: String?,
    onRetryBiometric: () -> Unit,
    onSkip: () -> Unit,
    onSignOut: () -> Unit,
    onClearError: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        
        BiometricHeader(
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        StatusMessage(
            isLoading = isLoading,
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        errorMessage?.let { error ->
            ErrorMessage(
                message = error,
                onDismiss = onClearError,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
            )
        }
        
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            
            Button(
                onClick = onRetryBiometric,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Fingerprint,
                        contentDescription = "Fingerprint",
                        modifier = Modifier.size(20.dp)
                    )
                    Text("Try Again")
                }
            }
            
            OutlinedButton(
                onClick = onSkip,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Text("Skip for Now")
            }
            
            TextButton(
                onClick = onSignOut,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Text(
                    text = "Sign Out",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        SecurityFooter(
            modifier = Modifier.padding(vertical = 16.dp)
        )
    }
}