package com.voicecontrol.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Voice Control App Material Design 3 Theme
 * 
 * Equivalent to iOS VoiceControl app theming with SwiftUI
 * Provides comprehensive theming with dynamic colors, dark mode support, and accessibility
 * 
 * Features:
 * - Material Design 3 dynamic color theming (Android 12+)
 * - Professional audio industry color palette
 * - Dark and light mode support
 * - High contrast accessibility support
 * - System bar theming integration
 */

// Light theme colors - Professional audio industry inspired
private val LightColorScheme = lightColorScheme(
    // Primary colors - Professional blue gradient
    primary = VoiceControlColors.PrimaryBlue,
    onPrimary = VoiceControlColors.OnPrimary,
    primaryContainer = VoiceControlColors.PrimaryContainer,
    onPrimaryContainer = VoiceControlColors.OnPrimaryContainer,
    
    // Secondary colors - Accent orange for voice/recording elements
    secondary = VoiceControlColors.SecondaryOrange,
    onSecondary = VoiceControlColors.OnSecondary,
    secondaryContainer = VoiceControlColors.SecondaryContainer,
    onSecondaryContainer = VoiceControlColors.OnSecondaryContainer,
    
    // Tertiary colors - Success green for confirmations
    tertiary = VoiceControlColors.TertiaryGreen,
    onTertiary = VoiceControlColors.OnTertiary,
    tertiaryContainer = VoiceControlColors.TertiaryContainer,
    onTertiaryContainer = VoiceControlColors.OnTertiaryContainer,
    
    // Error colors
    error = VoiceControlColors.Error,
    onError = VoiceControlColors.OnError,
    errorContainer = VoiceControlColors.ErrorContainer,
    onErrorContainer = VoiceControlColors.OnErrorContainer,
    
    // Background colors - Clean professional background
    background = VoiceControlColors.Background,
    onBackground = VoiceControlColors.OnBackground,
    surface = VoiceControlColors.Surface,
    onSurface = VoiceControlColors.OnSurface,
    surfaceVariant = VoiceControlColors.SurfaceVariant,
    onSurfaceVariant = VoiceControlColors.OnSurfaceVariant,
    
    // Outline colors
    outline = VoiceControlColors.Outline,
    outlineVariant = VoiceControlColors.OutlineVariant
)

// Dark theme colors - Professional dark mode for audio work
private val DarkColorScheme = darkColorScheme(
    // Primary colors - Muted professional blue for dark mode
    primary = VoiceControlColors.DarkPrimaryBlue,
    onPrimary = VoiceControlColors.DarkOnPrimary,
    primaryContainer = VoiceControlColors.DarkPrimaryContainer,
    onPrimaryContainer = VoiceControlColors.DarkOnPrimaryContainer,
    
    // Secondary colors - Warmer orange for dark mode visibility
    secondary = VoiceControlColors.DarkSecondaryOrange,
    onSecondary = VoiceControlColors.DarkOnSecondary,
    secondaryContainer = VoiceControlColors.DarkSecondaryContainer,
    onSecondaryContainer = VoiceControlColors.DarkOnSecondaryContainer,
    
    // Tertiary colors - Softer green for dark mode
    tertiary = VoiceControlColors.DarkTertiaryGreen,
    onTertiary = VoiceControlColors.DarkOnTertiary,
    tertiaryContainer = VoiceControlColors.DarkTertiaryContainer,
    onTertiaryContainer = VoiceControlColors.DarkOnTertiaryContainer,
    
    // Error colors
    error = VoiceControlColors.DarkError,
    onError = VoiceControlColors.DarkOnError,
    errorContainer = VoiceControlColors.DarkErrorContainer,
    onErrorContainer = VoiceControlColors.DarkOnErrorContainer,
    
    // Background colors - Professional dark background for focus
    background = VoiceControlColors.DarkBackground,
    onBackground = VoiceControlColors.DarkOnBackground,
    surface = VoiceControlColors.DarkSurface,
    onSurface = VoiceControlColors.DarkOnSurface,
    surfaceVariant = VoiceControlColors.DarkSurfaceVariant,
    onSurfaceVariant = VoiceControlColors.DarkOnSurfaceVariant,
    
    // Outline colors
    outline = VoiceControlColors.DarkOutline,
    outlineVariant = VoiceControlColors.DarkOutlineVariant
)

/**
 * Voice Control App Theme Composable
 * 
 * @param darkTheme Whether to use dark theme (default: system setting)
 * @param dynamicColor Whether to use dynamic color theming on Android 12+ (default: true)
 * @param content The composable content to theme
 */
@Composable
fun VoiceControlTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        // Dynamic color theming (Android 12+)
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        
        // Static color theming
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = darkTheme
        }
    }
    
    MaterialTheme(
        colorScheme = colorScheme,
        typography = VoiceControlTypography,
        shapes = VoiceControlShapes,
        content = content
    )
}

/**
 * Preview theme for Compose previews
 * Ensures consistent theming in @Preview composables
 */
@Composable
fun VoiceControlPreviewTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    VoiceControlTheme(
        darkTheme = darkTheme,
        dynamicColor = false, // Disable dynamic color for consistent previews
        content = content
    )
}