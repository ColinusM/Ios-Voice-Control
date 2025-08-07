package com.voicecontrol.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Voice Control App Color Palette
 * 
 * Professional audio industry inspired color scheme
 * Equivalent to iOS Color extensions and custom colors
 * 
 * Features:
 * - Professional audio mixing console inspired colors
 * - High contrast for accessibility
 * - Distinct colors for voice/recording states
 * - Dark mode optimized variants
 * - Material Design 3 compliant color roles
 */
object VoiceControlColors {
    
    // MARK: - Brand Colors
    
    /** Primary brand blue - Professional mixing console blue */
    val BrandBlue = Color(0xFF1976D2)
    
    /** Secondary brand orange - Recording/voice activity indicator */
    val BrandOrange = Color(0xFFFF6F00)
    
    /** Success green - Successful operations, connected status */
    val BrandGreen = Color(0xFF2E7D32)
    
    /** Warning orange - Caution states, usage warnings */
    val BrandWarning = Color(0xFFED6C02)
    
    /** Error red - Error states, failed operations */
    val BrandError = Color(0xFFD32F2F)
    
    // MARK: - Light Theme Colors
    
    // Primary colors
    val PrimaryBlue = Color(0xFF1976D2)          // Professional blue
    val OnPrimary = Color(0xFFFFFFFF)            // White text on primary
    val PrimaryContainer = Color(0xFFE3F2FD)     // Light blue container
    val OnPrimaryContainer = Color(0xFF0D47A1)   // Dark blue text on container
    
    // Secondary colors (Recording/Voice states)
    val SecondaryOrange = Color(0xFFFF6F00)      // Voice recording orange
    val OnSecondary = Color(0xFFFFFFFF)          // White text on secondary
    val SecondaryContainer = Color(0xFFFFE0B2)   // Light orange container
    val OnSecondaryContainer = Color(0xFFE65100) // Dark orange text on container
    
    // Tertiary colors (Success states)
    val TertiaryGreen = Color(0xFF2E7D32)        // Success green
    val OnTertiary = Color(0xFFFFFFFF)           // White text on tertiary
    val TertiaryContainer = Color(0xFFC8E6C9)    // Light green container
    val OnTertiaryContainer = Color(0xFF1B5E20)  // Dark green text on container
    
    // Error colors
    val Error = Color(0xFFD32F2F)                // Error red
    val OnError = Color(0xFFFFFFFF)              // White text on error
    val ErrorContainer = Color(0xFFFFEBEE)       // Light red container
    val OnErrorContainer = Color(0xFFB71C1C)     // Dark red text on error container
    
    // Background colors
    val Background = Color(0xFFFFFBFE)           // Off-white background
    val OnBackground = Color(0xFF1C1B1F)         // Dark text on background
    val Surface = Color(0xFFFFFBFE)              // Surface color
    val OnSurface = Color(0xFF1C1B1F)            // Text on surface
    val SurfaceVariant = Color(0xFFE7E0EC)       // Surface variant
    val OnSurfaceVariant = Color(0xFF49454F)     // Text on surface variant
    
    // Outline colors
    val Outline = Color(0xFF79747E)              // Outline color
    val OutlineVariant = Color(0xFFCAC4D0)       // Outline variant
    
    // MARK: - Dark Theme Colors
    
    // Primary colors (Dark)
    val DarkPrimaryBlue = Color(0xFF90CAF9)      // Light blue for dark theme
    val DarkOnPrimary = Color(0xFF0D47A1)        // Dark blue text
    val DarkPrimaryContainer = Color(0xFF1565C0) // Medium blue container
    val DarkOnPrimaryContainer = Color(0xFFE3F2FD) // Light blue text
    
    // Secondary colors (Dark)
    val DarkSecondaryOrange = Color(0xFFFFB74D)  // Light orange for dark theme
    val DarkOnSecondary = Color(0xFFE65100)      // Dark orange text
    val DarkSecondaryContainer = Color(0xFFFF8F00) // Medium orange container
    val DarkOnSecondaryContainer = Color(0xFFFFE0B2) // Light orange text
    
    // Tertiary colors (Dark)
    val DarkTertiaryGreen = Color(0xFF81C784)    // Light green for dark theme
    val DarkOnTertiary = Color(0xFF1B5E20)       // Dark green text
    val DarkTertiaryContainer = Color(0xFF388E3C) // Medium green container
    val DarkOnTertiaryContainer = Color(0xFFC8E6C9) // Light green text
    
    // Error colors (Dark)
    val DarkError = Color(0xFFEF5350)            // Light red for dark theme
    val DarkOnError = Color(0xFFB71C1C)          // Dark red text
    val DarkErrorContainer = Color(0xFFC62828)   // Medium red container
    val DarkOnErrorContainer = Color(0xFFFFEBEE) // Light red text
    
    // Background colors (Dark)
    val DarkBackground = Color(0xFF1C1B1F)       // Dark background
    val DarkOnBackground = Color(0xFFE6E1E5)     // Light text on dark background
    val DarkSurface = Color(0xFF1C1B1F)          // Dark surface
    val DarkOnSurface = Color(0xFFE6E1E5)        // Light text on dark surface
    val DarkSurfaceVariant = Color(0xFF49454F)   // Dark surface variant
    val DarkOnSurfaceVariant = Color(0xFFCAC4D0) // Light text on dark surface variant
    
    // Outline colors (Dark)
    val DarkOutline = Color(0xFF938F99)          // Dark outline
    val DarkOutlineVariant = Color(0xFF49454F)   // Dark outline variant
    
    // MARK: - Semantic Colors
    
    /** Recording state red - Indicates active recording */
    val RecordingRed = Color(0xFFE53E3E)
    
    /** Processing state amber - Indicates speech processing */
    val ProcessingAmber = Color(0xFFFFC107)
    
    /** Connected state green - Indicates successful connection */
    val ConnectedGreen = Color(0xFF4CAF50)
    
    /** Disconnected state gray - Indicates no connection */
    val DisconnectedGray = Color(0xFF9E9E9E)
    
    /** Premium gold - Premium subscription indicator */
    val PremiumGold = Color(0xFFFFD700)
    
    /** Guest mode blue-gray - Guest user indicator */
    val GuestModeBlueGray = Color(0xFF607D8B)
    
    // MARK: - Audio Mixer Inspired Colors
    
    /** Audio blue - Professional audio interface blue */
    val AudioBlue = Color(0xFF1976D2)
    
    /** Channel strip background - Mixing console channel color */
    val ChannelStripBackground = Color(0xFF37474F)
    
    /** Fader track - Fader background color */
    val FaderTrack = Color(0xFF455A64)
    
    /** Fader thumb - Fader control color */
    val FaderThumb = Color(0xFF90A4AE)
    
    /** EQ curve - Equalizer curve color */
    val EQCurve = Color(0xFF26C6DA)
    
    /** Level meter green - Safe audio levels */
    val LevelMeterGreen = Color(0xFF66BB6A)
    
    /** Level meter yellow - Moderate audio levels */
    val LevelMeterYellow = Color(0xFFFFEB3B)
    
    /** Level meter red - High audio levels */
    val LevelMeterRed = Color(0xFFFF5722)
    
    // MARK: - Network Status Colors
    
    /** Network connected - Strong connection */
    val NetworkConnected = Color(0xFF4CAF50)
    
    /** Network connecting - Connection in progress */
    val NetworkConnecting = Color(0xFFFFC107)
    
    /** Network error - Connection failed */
    val NetworkError = Color(0xFFF44336)
    
    /** Network testing - Testing connection */
    val NetworkTesting = Color(0xFF2196F3)
    
    // MARK: - Voice Command State Colors
    
    /** Command listening - Waiting for voice input */
    val CommandListening = Color(0xFF2196F3)
    
    /** Command processing - Processing voice command */
    val CommandProcessing = Color(0xFFFF9800)
    
    /** Command success - Command executed successfully */
    val CommandSuccess = Color(0xFF4CAF50)
    
    /** Command failed - Command execution failed */
    val CommandFailed = Color(0xFFF44336)
    
    // MARK: - Alpha Variants for Overlays
    
    /** Semi-transparent black for overlays */
    val OverlayBlack = Color(0x80000000)
    
    /** Semi-transparent white for overlays */
    val OverlayWhite = Color(0x80FFFFFF)
    
    /** Recording overlay - Semi-transparent red */
    val RecordingOverlay = Color(0x40E53E3E)
    
    /** Processing overlay - Semi-transparent amber */
    val ProcessingOverlay = Color(0x40FFC107)
}