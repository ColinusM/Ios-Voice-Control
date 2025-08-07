package com.voicecontrol.app.ui.component.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.voicecontrol.app.ui.theme.VoiceControlTheme

/**
 * Welcome Header Component for Authentication Screen
 * 
 * Direct port of iOS WelcomeView header to Compose
 * Displays app branding, logo, and welcome message
 * 
 * Features:
 * - App logo and branding (equivalent to iOS Image and Text views)
 * - Professional audio industry styling
 * - Responsive layout for different screen sizes
 * - Material Design 3 theming integration
 * - Accessibility support with content descriptions
 * 
 * @param modifier Modifier for styling and layout
 */
@Composable
fun WelcomeHeader(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        // MARK: - App Logo
        AppLogo(
            modifier = Modifier
                .size(80.dp)
                .padding(bottom = 16.dp)
        )
        
        // MARK: - App Name
        Text(
            text = "Voice Control",
            style = MaterialTheme.typography.displaySmall,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )
        
        // MARK: - App Tagline
        Text(
            text = "Professional Audio Control",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
        )
        
        // MARK: - Welcome Message
        Text(
            text = "Control your Yamaha mixing console with voice commands",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}

/**
 * App Logo Component
 * 
 * Displays the Voice Control app logo
 * Equivalent to iOS app icon or custom logo view
 * 
 * @param modifier Modifier for styling and layout
 * @param icon The icon to display (default: microphone)
 */
@Composable
private fun AppLogo(
    modifier: Modifier = Modifier,
    icon: ImageVector = Icons.Default.Mic
) {
    Card(
        modifier = modifier,
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
                imageVector = icon,
                contentDescription = "Voice Control App Logo",
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

/**
 * Alternative compact welcome header for smaller screens
 * Equivalent to iOS compact navigation bar title
 * 
 * @param modifier Modifier for styling and layout
 */
@Composable
fun CompactWelcomeHeader(
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        AppLogo(
            modifier = Modifier.size(40.dp)
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column {
            Text(
                text = "Voice Control",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            Text(
                text = "Professional Audio",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Welcome header with custom branding
 * For enterprise or white-label versions
 * 
 * @param appName Custom app name
 * @param tagline Custom tagline
 * @param description Custom description
 * @param modifier Modifier for styling and layout
 */
@Composable
fun CustomWelcomeHeader(
    appName: String,
    tagline: String,
    description: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        AppLogo(
            modifier = Modifier
                .size(80.dp)
                .padding(bottom = 16.dp)
        )
        
        Text(
            text = appName,
            style = MaterialTheme.typography.displaySmall,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = tagline,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
        )
        
        Text(
            text = description,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun WelcomeHeaderPreview() {
    VoiceControlTheme {
        WelcomeHeader(
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun WelcomeHeaderDarkPreview() {
    VoiceControlTheme(darkTheme = true) {
        WelcomeHeader(
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun CompactWelcomeHeaderPreview() {
    VoiceControlTheme {
        CompactWelcomeHeader(
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun CustomWelcomeHeaderPreview() {
    VoiceControlTheme {
        CustomWelcomeHeader(
            appName = "Pro Audio Voice",
            tagline = "Enterprise Console Control",
            description = "Advanced voice control system for professional audio mixing environments",
            modifier = Modifier.padding(16.dp)
        )
    }
}