package com.voicecontrol.app.ui.component.common

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.voicecontrol.app.ui.theme.VoiceControlTheme
import kotlinx.coroutines.delay

/**
 * Loading Indicator Component for Voice Control App
 * 
 * Direct port of iOS loading indicators and progress views to Compose
 * Displays loading states with consistent styling and animations
 * 
 * Features:
 * - Professional loading animations (equivalent to iOS UIActivityIndicatorView)
 * - Customizable messages and styling
 * - Different loading indicator types
 * - Smooth animations (equivalent to iOS view transitions)
 * - Accessibility support with content descriptions
 * 
 * @param message Optional message to display below the indicator
 * @param modifier Modifier for styling and layout
 * @param type The type of loading indicator
 * @param color Custom color for the indicator
 */
@Composable
fun LoadingIndicator(
    message: String? = null,
    modifier: Modifier = Modifier,
    type: LoadingType = LoadingType.Circular,
    color: Color = MaterialTheme.colorScheme.primary
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        
        // Loading indicator based on type
        when (type) {
            LoadingType.Circular -> {
                CircularProgressIndicator(
                    modifier = Modifier.size(48.dp),
                    color = color,
                    strokeWidth = 4.dp
                )
            }
            
            LoadingType.Linear -> {
                LinearProgressIndicator(
                    modifier = Modifier
                        .width(200.dp)
                        .height(4.dp)
                        .clip(CircleShape),
                    color = color,
                    trackColor = color.copy(alpha = 0.2f)
                )
            }
            
            LoadingType.Pulsing -> {
                PulsingLoadingIndicator(color = color)
            }
            
            LoadingType.Dots -> {
                DotsLoadingIndicator(color = color)
            }
        }
        
        // Optional message
        message?.let { msg ->
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = msg,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * Loading indicator types
 * Equivalent to different iOS loading indicator styles
 */
enum class LoadingType {
    Circular,   // Standard circular progress indicator
    Linear,     // Linear progress bar
    Pulsing,    // Pulsing circle animation
    Dots        // Three dots animation
}

/**
 * Pulsing loading indicator
 * Custom animation for professional audio applications
 * Equivalent to iOS custom loading animations
 */
@Composable
private fun PulsingLoadingIndicator(
    color: Color = MaterialTheme.colorScheme.primary
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = EaseInOutCubic),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = EaseInOutCubic),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )
    
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(CircleShape)
        ) {
            Card(
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer(
                        scaleX = scale,
                        scaleY = scale,
                        alpha = alpha
                    ),
                shape = CircleShape,
                colors = CardDefaults.cardColors(
                    containerColor = color
                )
            ) {}
        }
    }
}

/**
 * Three dots loading indicator
 * Professional animation for speech processing states
 * Equivalent to iOS typing indicators
 */
@Composable
private fun DotsLoadingIndicator(
    color: Color = MaterialTheme.colorScheme.primary
) {
    val infiniteTransition = rememberInfiniteTransition(label = "dots")
    
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(3) { index ->
            val delay = index * 200
            
            val scale by infiniteTransition.animateFloat(
                initialValue = 0.5f,
                targetValue = 1.0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(
                        durationMillis = 600,
                        delayMillis = delay,
                        easing = EaseInOutCubic
                    ),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dot_scale_$index"
            )
            
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .graphicsLayer(
                        scaleX = scale,
                        scaleY = scale
                    )
                    .clip(CircleShape)
            ) {
                Card(
                    modifier = Modifier.fillMaxSize(),
                    shape = CircleShape,
                    colors = CardDefaults.cardColors(
                        containerColor = color
                    )
                ) {}
            }
        }
    }
}

/**
 * Full-screen loading overlay
 * For blocking operations
 * Equivalent to iOS full-screen loading views
 * 
 * @param message Loading message
 * @param isVisible Whether the overlay is visible
 * @param modifier Modifier for styling and layout
 */
@Composable
fun LoadingOverlay(
    message: String = "Loading...",
    isVisible: Boolean = true,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = modifier
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Card(
                modifier = Modifier.padding(32.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
                shape = MaterialTheme.shapes.large
            ) {
                LoadingIndicator(
                    message = message,
                    modifier = Modifier.padding(32.dp),
                    type = LoadingType.Circular
                )
            }
        }
    }
}

/**
 * Loading button
 * Button with integrated loading state
 * Equivalent to iOS loading button states
 * 
 * @param text Button text
 * @param isLoading Whether button is in loading state
 * @param onClick Button click callback
 * @param modifier Modifier for styling and layout
 * @param enabled Whether button is enabled
 */
@Composable
fun LoadingButton(
    text: String,
    isLoading: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled && !isLoading
    ) {
        if (isLoading) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
                Text(text)
            }
        } else {
            Text(text)
        }
    }
}

/**
 * Loading progress with percentage
 * For file uploads, downloads, or processing
 * Equivalent to iOS progress views with percentage
 * 
 * @param progress Current progress (0.0 to 1.0)
 * @param message Loading message
 * @param showPercentage Whether to show percentage
 * @param modifier Modifier for styling and layout
 */
@Composable
fun LoadingProgress(
    progress: Float,
    message: String = "Processing...",
    showPercentage: Boolean = true,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        LinearProgressIndicator(
            progress = progress,
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(CircleShape),
            color = MaterialTheme.colorScheme.primary,
            trackColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            if (showPercentage) {
                Text(
                    text = "${(progress * 100).toInt()}%",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun LoadingIndicatorPreview() {
    VoiceControlTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            LoadingIndicator(
                message = "Signing you in...",
                type = LoadingType.Circular
            )
            
            LoadingIndicator(
                message = "Processing voice command...",
                type = LoadingType.Pulsing
            )
            
            LoadingIndicator(
                message = "Connecting to mixer...",
                type = LoadingType.Dots
            )
            
            LoadingIndicator(
                message = "Uploading settings...",
                type = LoadingType.Linear
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun LoadingButtonPreview() {
    VoiceControlTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            LoadingButton(
                text = "Sign In",
                isLoading = false,
                onClick = { }
            )
            
            LoadingButton(
                text = "Signing In...",
                isLoading = true,
                onClick = { }
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun LoadingProgressPreview() {
    VoiceControlTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            LoadingProgress(
                progress = 0.3f,
                message = "Downloading voice models..."
            )
            
            LoadingProgress(
                progress = 0.75f,
                message = "Processing audio data...",
                showPercentage = false
            )
            
            LoadingProgress(
                progress = 1.0f,
                message = "Complete!"
            )
        }
    }
}