package com.voicecontrol.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Voice Control App Shape System
 * 
 * Professional shape system for audio engineering applications
 * Equivalent to iOS corner radius and shape modifiers
 * 
 * Features:
 * - Material Design 3 shape system
 * - Professional rounded corners for audio equipment aesthetic
 * - Consistent corner radii across the app
 * - Accessibility-friendly touch targets
 */
val VoiceControlShapes = Shapes(
    
    // MARK: - Small Components (Chips, small buttons, indicators)
    extraSmall = RoundedCornerShape(4.dp),  // Very subtle rounding for small elements
    small = RoundedCornerShape(8.dp),       // Standard small component rounding
    
    // MARK: - Medium Components (Cards, dialogs, large buttons)
    medium = RoundedCornerShape(12.dp),     // Standard card and dialog rounding
    
    // MARK: - Large Components (Sheets, large containers)
    large = RoundedCornerShape(16.dp),      // Bottom sheets, large containers
    extraLarge = RoundedCornerShape(28.dp), // Very large components, rounded containers
)

/**
 * Custom shapes for Voice Control specific components
 * Equivalent to iOS custom shape modifiers and clipping
 */
object VoiceControlCustomShapes {
    
    // MARK: - Recording Interface Shapes
    
    /** Circular shape for record buttons and indicators */
    val circular = RoundedCornerShape(50) // 50% creates perfect circle
    
    /** Recording button outer ring */
    val recordingButtonOuter = RoundedCornerShape(36.dp)
    
    /** Recording button inner circle */
    val recordingButtonInner = RoundedCornerShape(28.dp)
    
    // MARK: - Professional Audio Equipment Shapes
    
    /** Mixing console style - slight rounding like professional equipment */
    val mixingConsole = RoundedCornerShape(6.dp)
    
    /** Channel strip shape - very subtle rounding */
    val channelStrip = RoundedCornerShape(4.dp)
    
    /** Fader track shape - minimal rounding for professional look */
    val faderTrack = RoundedCornerShape(2.dp)
    
    /** Fader thumb shape - rounded for smooth operation feel */
    val faderThumb = RoundedCornerShape(8.dp)
    
    /** EQ knob shape - circular for rotary controls */
    val eqKnob = circular
    
    // MARK: - Network Interface Shapes
    
    /** Network status indicator - slightly rounded rectangle */
    val networkStatus = RoundedCornerShape(6.dp)
    
    /** Connection test button - professional rounded corners */
    val connectionButton = RoundedCornerShape(8.dp)
    
    /** IP address input field - subtle rounding */
    val ipAddressField = RoundedCornerShape(8.dp)
    
    // MARK: - Voice Command Interface Shapes
    
    /** Voice command bubble - speech bubble style */
    val voiceCommandBubble = RoundedCornerShape(
        topStart = 16.dp,
        topEnd = 16.dp,
        bottomStart = 4.dp,
        bottomEnd = 16.dp
    )
    
    /** Voice command response bubble - response style */
    val voiceCommandResponse = RoundedCornerShape(
        topStart = 16.dp,
        topEnd = 16.dp,
        bottomStart = 16.dp,
        bottomEnd = 4.dp
    )
    
    /** Transcription display - document style */
    val transcriptionDisplay = RoundedCornerShape(12.dp)
    
    // MARK: - Authentication Interface Shapes
    
    /** Sign-in card - welcoming rounded corners */
    val signInCard = RoundedCornerShape(16.dp)
    
    /** Authentication button - friendly rounding */
    val authButton = RoundedCornerShape(12.dp)
    
    /** Biometric prompt background - secure feeling shape */
    val biometricPrompt = RoundedCornerShape(20.dp)
    
    /** Input field - accessible rounding */
    val inputField = RoundedCornerShape(8.dp)
    
    // MARK: - Navigation Shapes
    
    /** Bottom navigation - subtle top rounding */
    val bottomNavigation = RoundedCornerShape(
        topStart = 16.dp,
        topEnd = 16.dp,
        bottomStart = 0.dp,
        bottomEnd = 0.dp
    )
    
    /** Tab indicator - pill shape */
    val tabIndicator = RoundedCornerShape(16.dp)
    
    /** Floating action button - slightly rounded square */
    val fab = RoundedCornerShape(16.dp)
    
    /** Extended FAB - more rounded for text content */
    val extendedFab = RoundedCornerShape(16.dp)
    
    // MARK: - Status and Feedback Shapes
    
    /** Success indicator - friendly rounding */
    val successIndicator = RoundedCornerShape(8.dp)
    
    /** Warning indicator - attention-getting rounding */
    val warningIndicator = RoundedCornerShape(6.dp)
    
    /** Error indicator - alert rounding */
    val errorIndicator = RoundedCornerShape(8.dp)
    
    /** Loading indicator background */
    val loadingIndicator = RoundedCornerShape(12.dp)
    
    // MARK: - Settings Interface Shapes
    
    /** Settings section card */
    val settingsCard = RoundedCornerShape(12.dp)
    
    /** Settings toggle background */
    val settingsToggle = RoundedCornerShape(16.dp)
    
    /** Settings slider track */
    val settingsSliderTrack = RoundedCornerShape(2.dp)
    
    /** Settings slider thumb */
    val settingsSliderThumb = RoundedCornerShape(8.dp)
    
    // MARK: - Premium/Subscription Shapes
    
    /** Premium card - elegant rounding */
    val premiumCard = RoundedCornerShape(16.dp)
    
    /** Subscription plan card - professional rounding */
    val subscriptionPlan = RoundedCornerShape(12.dp)
    
    /** Premium badge - distinctive rounding */
    val premiumBadge = RoundedCornerShape(20.dp)
    
    // MARK: - Overlay Shapes
    
    /** Dialog overlay - generous rounding for prominence */
    val dialogOverlay = RoundedCornerShape(24.dp)
    
    /** Sheet overlay - top rounding only */
    val sheetOverlay = RoundedCornerShape(
        topStart = 20.dp,
        topEnd = 20.dp,
        bottomStart = 0.dp,
        bottomEnd = 0.dp
    )
    
    /** Tooltip shape - subtle rounding */
    val tooltip = RoundedCornerShape(8.dp)
    
    // MARK: - Technical Interface Shapes
    
    /** Waveform display background */
    val waveformDisplay = RoundedCornerShape(4.dp)
    
    /** Level meter - minimal rounding for precise display */
    val levelMeter = RoundedCornerShape(2.dp)
    
    /** Frequency spectrum display */
    val spectrumDisplay = RoundedCornerShape(6.dp)
    
    /** Technical readout background */
    val technicalReadout = RoundedCornerShape(4.dp)
}