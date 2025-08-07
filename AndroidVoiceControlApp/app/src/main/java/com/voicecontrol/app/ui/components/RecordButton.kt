package com.voicecontrol.app.ui.components

import androidx.compose.animation.core.*
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.ripple.rememberRipple
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.voicecontrol.app.speech.service.SpeechRecognitionService
import com.voicecontrol.app.ui.theme.*
import kotlin.math.cos
import kotlin.math.sin

/**
 * Record Button Component for Voice Control App
 * 
 * Direct port of iOS RecordButton to Compose with animations
 * Provides visual feedback for speech recognition state
 * 
 * Features:
 * - Animated recording state transitions
 * - Audio level visualization (pulse animation)
 * - Material Design 3 styling
 * - Accessibility support
 * - Haptic feedback integration
 * - Multiple size variants
 * - Custom color theming
 */
@Composable
fun RecordButton(
    isRecording: Boolean,
    audioLevel: Float = 0f,
    recognitionState: SpeechRecognitionService.RecognitionState = SpeechRecognitionService.RecognitionState.Stopped,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: RecordButtonSize = RecordButtonSize.Large,
    enabled: Boolean = true,
    showLabel: Boolean = true
) {
    val density = LocalDensity.current
    
    // Animation states
    val infiniteTransition = rememberInfiniteTransition(label = "RecordButton")
    
    // Scale animation for recording state
    val recordingScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isRecording) 1.1f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "RecordingScale"
    )
    
    // Pulse animation for audio level
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isRecording) 1f + (audioLevel * 0.3f) else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "PulseScale"
    )
    
    // Rotation animation for processing state
    val rotationAngle by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = if (recognitionState == SpeechRecognitionService.RecognitionState.Processing) 360f else 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "ProcessingRotation"
    )
    
    // Color transitions
    val buttonColor by animateColorAsState(
        targetValue = when {
            !enabled -> VoiceControlColors.DisconnectedGray
            recognitionState == SpeechRecognitionService.RecognitionState.Error -> VoiceControlColors.RecordingRed
            isRecording -> VoiceControlColors.RecordingRed
            else -> VoiceControlColors.ConnectedGreen
        },
        animationSpec = tween(300),
        label = "ButtonColor"
    )
    
    val iconColor by animateColorAsState(
        targetValue = Color.White,
        animationSpec = tween(300),
        label = "IconColor"
    )
    
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = modifier
    ) {
        // Main record button
        Box(
            modifier = Modifier
                .size(size.buttonSize)
                .scale(recordingScale * pulseScale)
                .clip(CircleShape)
                .background(
                    color = buttonColor,
                    shape = CircleShape
                )
                .clickable(
                    enabled = enabled,
                    interactionSource = remember { MutableInteractionSource() },
                    indication = rememberRipple(bounded = true, color = Color.White.copy(alpha = 0.3f)),
                    onClick = onClick
                ),
            contentAlignment = Alignment.Center
        ) {
            
            // Audio level visualization rings
            if (isRecording && audioLevel > 0.1f) {
                Canvas(
                    modifier = Modifier.fillMaxSize()
                ) {
                    drawAudioLevelRings(
                        audioLevel = audioLevel,
                        color = Color.White.copy(alpha = 0.3f),
                        strokeWidth = with(density) { 2.dp.toPx() }
                    )
                }
            }
            
            // Processing indicator
            if (recognitionState == SpeechRecognitionService.RecognitionState.Processing) {
                Canvas(
                    modifier = Modifier.fillMaxSize()
                ) {
                    drawProcessingIndicator(
                        rotationAngle = rotationAngle,
                        color = Color.White.copy(alpha = 0.5f),
                        strokeWidth = with(density) { 3.dp.toPx() }
                    )
                }
            }
            
            // Center icon
            Icon(
                imageVector = getRecordButtonIcon(isRecording, recognitionState),
                contentDescription = getContentDescription(isRecording, recognitionState),
                modifier = Modifier.size(size.iconSize),
                tint = iconColor
            )
        }
        
        // Status label
        if (showLabel) {
            RecordButtonLabel(
                isRecording = isRecording,
                recognitionState = recognitionState,
                audioLevel = audioLevel,
                textStyle = when (size) {
                    RecordButtonSize.Small -> MaterialTheme.typography.bodySmall
                    RecordButtonSize.Medium -> MaterialTheme.typography.bodyMedium
                    RecordButtonSize.Large -> MaterialTheme.typography.bodyLarge
                }
            )
        }
    }
}

/**
 * Record button size variants
 * Equivalent to iOS RecordButtonSize enum
 */
enum class RecordButtonSize(
    val buttonSize: Dp,
    val iconSize: Dp
) {
    Small(buttonSize = 48.dp, iconSize = 20.dp),
    Medium(buttonSize = 64.dp, iconSize = 28.dp),
    Large(buttonSize = 80.dp, iconSize = 36.dp)
}

/**
 * Record button status label
 */
@Composable
private fun RecordButtonLabel(
    isRecording: Boolean,
    recognitionState: SpeechRecognitionService.RecognitionState,
    audioLevel: Float,
    textStyle: androidx.compose.ui.text.TextStyle
) {
    val labelText = when {
        !isRecording -> "Tap to Record"
        recognitionState == SpeechRecognitionService.RecognitionState.Starting -> "Starting..."
        recognitionState == SpeechRecognitionService.RecognitionState.Recording -> "Recording..."
        recognitionState == SpeechRecognitionService.RecognitionState.Processing -> "Processing..."
        recognitionState == SpeechRecognitionService.RecognitionState.Stopping -> "Stopping..."
        recognitionState == SpeechRecognitionService.RecognitionState.Error -> "Error"
        else -> "Ready"
    }
    
    val labelColor = when (recognitionState) {
        SpeechRecognitionService.RecognitionState.Error -> VoiceControlColors.RecordingRed
        SpeechRecognitionService.RecognitionState.Recording -> VoiceControlColors.ConnectedGreen
        SpeechRecognitionService.RecognitionState.Processing -> VoiceControlColors.AudioBlue
        else -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
    }
    
    Text(
        text = labelText,
        style = textStyle.copy(
            fontWeight = if (isRecording) FontWeight.Medium else FontWeight.Normal,
            fontSize = textStyle.fontSize
        ),
        color = labelColor
    )
    
    // Audio level indicator
    if (isRecording && audioLevel > 0.05f) {
        LinearProgressIndicator(
            progress = { audioLevel.coerceIn(0f, 1f) },
            modifier = Modifier
                .width(60.dp)
                .height(2.dp)
                .padding(top = 2.dp),
            color = VoiceControlColors.ConnectedGreen,
            trackColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
        )
    }
}

/**
 * Get appropriate icon for current state
 */
private fun getRecordButtonIcon(
    isRecording: Boolean,
    recognitionState: SpeechRecognitionService.RecognitionState
): ImageVector {
    return when {
        recognitionState == SpeechRecognitionService.RecognitionState.Error -> Icons.Default.Error
        recognitionState == SpeechRecognitionService.RecognitionState.Processing -> Icons.Default.Autorenew
        recognitionState == SpeechRecognitionService.RecognitionState.Starting -> Icons.Default.PlayArrow
        recognitionState == SpeechRecognitionService.RecognitionState.Stopping -> Icons.Default.Stop
        isRecording -> Icons.Default.Stop
        else -> Icons.Default.Mic
    }
}

/**
 * Get content description for accessibility
 */
private fun getContentDescription(
    isRecording: Boolean,
    recognitionState: SpeechRecognitionService.RecognitionState
): String {
    return when {
        recognitionState == SpeechRecognitionService.RecognitionState.Error -> "Speech recognition error"
        recognitionState == SpeechRecognitionService.RecognitionState.Processing -> "Processing speech"
        recognitionState == SpeechRecognitionService.RecognitionState.Starting -> "Starting recording"
        recognitionState == SpeechRecognitionService.RecognitionState.Stopping -> "Stopping recording"
        isRecording -> "Stop recording"
        else -> "Start recording"
    }
}

/**
 * Draw audio level visualization rings
 */
private fun DrawScope.drawAudioLevelRings(
    audioLevel: Float,
    color: Color,
    strokeWidth: Float
) {
    val center = this.center
    val maxRadius = size.minDimension / 2f * 0.9f
    val ringCount = 3
    
    repeat(ringCount) { i ->
        val progress = (audioLevel * (i + 1) / ringCount).coerceIn(0f, 1f)
        val radius = maxRadius * (0.6f + progress * 0.4f)
        val alpha = (1f - i * 0.3f) * progress
        
        if (progress > 0.1f) {
            drawCircle(
                color = color.copy(alpha = alpha),
                radius = radius,
                center = center,
                style = Stroke(width = strokeWidth)
            )
        }
    }
}

/**
 * Draw processing state indicator
 */
private fun DrawScope.drawProcessingIndicator(
    rotationAngle: Float,
    color: Color,
    strokeWidth: Float
) {
    val center = this.center
    val radius = size.minDimension / 2f * 0.8f
    val dotCount = 8
    val dotRadius = strokeWidth * 1.5f
    
    repeat(dotCount) { i ->
        val angle = (rotationAngle + i * 45f) * (Math.PI / 180f)
        val x = center.x + radius * cos(angle).toFloat()
        val y = center.y + radius * sin(angle).toFloat()
        val alpha = 1f - (i * 0.1f)
        
        drawCircle(
            color = color.copy(alpha = alpha),
            radius = dotRadius,
            center = androidx.compose.ui.geometry.Offset(x, y)
        )
    }
}

/**
 * Compact record button variant for smaller spaces
 */
@Composable
fun CompactRecordButton(
    isRecording: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    RecordButton(
        isRecording = isRecording,
        recognitionState = if (isRecording) 
            SpeechRecognitionService.RecognitionState.Recording 
        else 
            SpeechRecognitionService.RecognitionState.Stopped,
        onClick = onClick,
        modifier = modifier,
        size = RecordButtonSize.Small,
        enabled = enabled,
        showLabel = false
    )
}

/**
 * Large record button with enhanced animations
 */
@Composable
fun LargeRecordButton(
    isRecording: Boolean,
    audioLevel: Float,
    recognitionState: SpeechRecognitionService.RecognitionState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    RecordButton(
        isRecording = isRecording,
        audioLevel = audioLevel,
        recognitionState = recognitionState,
        onClick = onClick,
        modifier = modifier,
        size = RecordButtonSize.Large,
        enabled = enabled,
        showLabel = true
    )
}