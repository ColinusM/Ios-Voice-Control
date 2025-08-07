package com.voicecontrol.app.ui.component.common

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.voicecontrol.app.ui.theme.VoiceControlTheme
import kotlinx.coroutines.delay

/**
 * Error Message Component for Voice Control App
 * 
 * Direct port of iOS error alert and banner to Compose
 * Displays error messages with consistent styling and dismissal options
 * 
 * Features:
 * - Professional error styling (equivalent to iOS alert styling)
 * - Auto-dismissal with configurable timeout
 * - Manual dismissal with close button
 * - Different error types (error, warning, info)
 * - Smooth animations (equivalent to iOS view transitions)
 * - Accessibility support
 * 
 * @param message The error message to display
 * @param onDismiss Callback when the error is dismissed
 * @param modifier Modifier for styling and layout
 * @param type The type of error message (error, warning, info)
 * @param autoDismiss Whether to auto-dismiss after a timeout
 * @param autoDismissDelay Delay in milliseconds before auto-dismiss
 */
@Composable
fun ErrorMessage(
    message: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    type: ErrorType = ErrorType.Error,
    autoDismiss: Boolean = false,
    autoDismissDelay: Long = 5000L
) {
    var isVisible by remember { mutableStateOf(true) }
    
    // Auto-dismiss logic
    LaunchedEffect(message) {
        if (autoDismiss) {
            delay(autoDismissDelay)
            isVisible = false
            delay(300) // Wait for animation
            onDismiss()
        }
    }
    
    AnimatedVisibility(
        visible = isVisible,
        enter = slideInVertically(
            initialOffsetY = { -it }
        ) + fadeIn(),
        exit = slideOutVertically(
            targetOffsetY = { -it }
        ) + fadeOut(),
        modifier = modifier
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = type.containerColor,
                contentColor = type.contentColor
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            shape = MaterialTheme.shapes.medium
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                
                // Error icon
                Icon(
                    imageVector = type.icon,
                    contentDescription = "${type.name} icon",
                    modifier = Modifier.size(24.dp),
                    tint = type.iconColor
                )
                
                Spacer(modifier = Modifier.width(12.dp))
                
                // Error message
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = type.contentColor,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Start
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                // Dismiss button
                IconButton(
                    onClick = {
                        isVisible = false
                        onDismiss()
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Dismiss error",
                        modifier = Modifier.size(20.dp),
                        tint = type.contentColor
                    )
                }
            }
        }
    }
}

/**
 * Error Type definitions
 * Equivalent to iOS alert types and styling
 */
enum class ErrorType(
    val icon: ImageVector,
    val containerColor: @Composable () -> androidx.compose.ui.graphics.Color,
    val contentColor: @Composable () -> androidx.compose.ui.graphics.Color,
    val iconColor: @Composable () -> androidx.compose.ui.graphics.Color
) {
    Error(
        icon = Icons.Default.Error,
        containerColor = { MaterialTheme.colorScheme.errorContainer },
        contentColor = { MaterialTheme.colorScheme.onErrorContainer },
        iconColor = { MaterialTheme.colorScheme.error }
    ),
    
    Warning(
        icon = Icons.Default.Warning,
        containerColor = { MaterialTheme.colorScheme.tertiaryContainer },
        contentColor = { MaterialTheme.colorScheme.onTertiaryContainer },
        iconColor = { MaterialTheme.colorScheme.tertiary }
    ),
    
    Info(
        icon = Icons.Default.Warning, // Using warning icon for info
        containerColor = { MaterialTheme.colorScheme.primaryContainer },
        contentColor = { MaterialTheme.colorScheme.onPrimaryContainer },
        iconColor = { MaterialTheme.colorScheme.primary }
    )
}

/**
 * Snackbar-style error message
 * Alternative to card-style error message
 * Equivalent to iOS toast or snackbar
 * 
 * @param message The error message to display
 * @param actionLabel Optional action button label
 * @param onAction Optional action button callback
 * @param onDismiss Callback when dismissed
 * @param modifier Modifier for styling and layout
 */
@Composable
fun ErrorSnackbar(
    message: String,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    Snackbar(
        modifier = modifier,
        action = if (actionLabel != null && onAction != null) {
            {
                TextButton(onClick = onAction) {
                    Text(actionLabel)
                }
            }
        } else null,
        dismissAction = {
            IconButton(onClick = onDismiss) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Dismiss"
                )
            }
        }
    ) {
        Text(message)
    }
}

/**
 * Inline error message for forms
 * Equivalent to iOS form field error text
 * 
 * @param message The error message to display
 * @param modifier Modifier for styling and layout
 */
@Composable
fun InlineErrorMessage(
    message: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = "Error",
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.error
        )
        
        Spacer(modifier = Modifier.width(4.dp))
        
        Text(
            text = message,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error
        )
    }
}

/**
 * Empty state error message
 * For when there's no content to display due to an error
 * Equivalent to iOS empty state views
 * 
 * @param title Error title
 * @param message Error description
 * @param actionLabel Optional action button label
 * @param onAction Optional action button callback
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmptyStateError(
    title: String,
    message: String,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = "Error",
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.error
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp)
        )
        
        if (actionLabel != null && onAction != null) {
            Spacer(modifier = Modifier.height(24.dp))
            
            Button(onClick = onAction) {
                Text(actionLabel)
            }
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun ErrorMessagePreview() {
    VoiceControlTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            ErrorMessage(
                message = "Invalid email or password. Please try again.",
                onDismiss = { },
                type = ErrorType.Error
            )
            
            ErrorMessage(
                message = "Network connection is unstable. Some features may not work properly.",
                onDismiss = { },
                type = ErrorType.Warning
            )
            
            ErrorMessage(
                message = "Voice recognition has been improved with the latest update.",
                onDismiss = { },
                type = ErrorType.Info
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun InlineErrorMessagePreview() {
    VoiceControlTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            InlineErrorMessage("Email address is required")
            InlineErrorMessage("Password must be at least 8 characters")
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun EmptyStateErrorPreview() {
    VoiceControlTheme {
        EmptyStateError(
            title = "Connection Failed",
            message = "Unable to connect to the audio mixer. Please check your network settings and try again.",
            actionLabel = "Retry Connection",
            onAction = { },
            modifier = Modifier.padding(16.dp)
        )
    }
}