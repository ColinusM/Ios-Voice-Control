package com.voicecontrol.app.ui.screen.main

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.voicecontrol.app.authentication.viewmodel.AuthenticationViewModel
import com.voicecontrol.app.ui.component.common.LoadingIndicator
import com.voicecontrol.app.ui.theme.VoiceControlTheme

/**
 * Main Voice Control Screen for Voice Control App
 * 
 * Direct port of iOS VoiceControlMainView to Compose
 * Primary interface for voice command control of audio mixer
 * 
 * Features:
 * - Voice command recording and processing (equivalent to iOS RecordButton)
 * - Real-time audio mixer feedback (equivalent to iOS VoiceControlMainView)
 * - Network status and connection monitoring
 * - Settings and configuration access
 * - Professional audio control interface design
 * - User account management
 * - Accessibility support for voice commands
 * 
 * @param authViewModel Authentication view model for user state management
 * @param onNavigateToSettings Callback to navigate to settings screen
 * @param onNavigateToNetworkSettings Callback to navigate to network settings
 * @param onNavigateToSubscription Callback to navigate to subscription screen
 * @param onSignOut Callback to sign out and return to authentication
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceControlMainScreen(
    authViewModel: AuthenticationViewModel,
    onNavigateToSettings: () -> Unit,
    onNavigateToNetworkSettings: () -> Unit,
    onNavigateToSubscription: () -> Unit,
    onSignOut: () -> Unit
) {
    // State for main screen functionality
    var isRecording by remember { mutableStateOf(false) }
    var lastCommand by remember { mutableStateOf<String?>(null) }
    var connectionStatus by remember { mutableStateOf("Disconnected") }
    var isMenuOpen by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            VoiceControlTopBar(
                connectionStatus = connectionStatus,
                onMenuClick = { isMenuOpen = !isMenuOpen },
                onSettingsClick = onNavigateToSettings,
                onNetworkClick = onNavigateToNetworkSettings,
                onSignOutClick = onSignOut
            )
        },
        floatingActionButton = {
            VoiceRecordButton(
                isRecording = isRecording,
                onStartRecording = { isRecording = true },
                onStopRecording = { 
                    isRecording = false
                    // TODO: Process voice command
                    lastCommand = "Channel 1 mute on"
                }
            )
        },
        floatingActionButtonPosition = FabPosition.Center
    ) { paddingValues ->
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            
            // MARK: - Welcome Header
            VoiceControlWelcomeSection(
                modifier = Modifier.padding(bottom = 32.dp)
            )
            
            // MARK: - Connection Status Card
            ConnectionStatusCard(
                status = connectionStatus,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )
            
            // MARK: - Voice Command History
            VoiceCommandHistory(
                lastCommand = lastCommand,
                isRecording = isRecording,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // MARK: - Quick Actions
            QuickActionsRow(
                onNetworkSettings = onNavigateToNetworkSettings,
                onSubscription = onNavigateToSubscription,
                modifier = Modifier.padding(bottom = 80.dp) // Account for FAB
            )
        }
    }
}

/**
 * Top app bar with connection status and menu
 * Equivalent to iOS navigation bar
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VoiceControlTopBar(
    connectionStatus: String,
    onMenuClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onNetworkClick: () -> Unit,
    onSignOutClick: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    
    TopAppBar(
        title = {
            Column {
                Text(
                    text = "Voice Control",
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = connectionStatus,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (connectionStatus == "Connected") 
                        MaterialTheme.colorScheme.primary 
                    else 
                        MaterialTheme.colorScheme.error
                )
            }
        },
        actions = {
            IconButton(onClick = { showMenu = true }) {
                Icon(
                    imageVector = Icons.Default.MoreVert,
                    contentDescription = "More options"
                )
            }
            
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("Settings") },
                    onClick = {
                        showMenu = false
                        onSettingsClick()
                    },
                    leadingIcon = {
                        Icon(Icons.Default.Settings, contentDescription = null)
                    }
                )
                
                DropdownMenuItem(
                    text = { Text("Network Settings") },
                    onClick = {
                        showMenu = false
                        onNetworkClick()
                    },
                    leadingIcon = {
                        Icon(Icons.Default.Wifi, contentDescription = null)
                    }
                )
                
                Divider()
                
                DropdownMenuItem(
                    text = { Text("Sign Out") },
                    onClick = {
                        showMenu = false
                        onSignOutClick()
                    },
                    leadingIcon = {
                        Icon(Icons.Default.ExitToApp, contentDescription = null)
                    }
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    )
}

/**
 * Welcome section with app information
 * Equivalent to iOS welcome header
 */
@Composable
private fun VoiceControlWelcomeSection(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        
        // App logo placeholder
        Card(
            modifier = Modifier.size(60.dp),
            shape = MaterialTheme.shapes.large,
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Mic,
                    contentDescription = "Voice Control",
                    modifier = Modifier.size(32.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Ready for Voice Commands",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "Press and hold the microphone button to give voice commands to your Yamaha mixing console",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
    }
}

/**
 * Connection status card showing mixer connection
 * Equivalent to iOS connection status view
 */
@Composable
private fun ConnectionStatusCard(
    status: String,
    modifier: Modifier = Modifier
) {
    val isConnected = status == "Connected"
    val cardColors = if (isConnected) {
        CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    } else {
        CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    }
    
    Card(
        modifier = modifier,
        colors = cardColors,
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = if (isConnected) Icons.Default.Wifi else Icons.Default.WifiOff,
                contentDescription = "Connection status",
                tint = if (isConnected) 
                    MaterialTheme.colorScheme.onPrimaryContainer 
                else 
                    MaterialTheme.colorScheme.onErrorContainer,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Mixer Connection",
                    style = MaterialTheme.typography.titleSmall,
                    color = if (isConnected) 
                        MaterialTheme.colorScheme.onPrimaryContainer 
                    else 
                        MaterialTheme.colorScheme.onErrorContainer
                )
                Text(
                    text = status,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isConnected) 
                        MaterialTheme.colorScheme.onPrimaryContainer 
                    else 
                        MaterialTheme.colorScheme.onErrorContainer
                )
            }
            
            if (!isConnected) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "Warning",
                    tint = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

/**
 * Voice command history and current status
 * Equivalent to iOS voice command display
 */
@Composable
private fun VoiceCommandHistory(
    lastCommand: String?,
    isRecording: Boolean,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            
            Text(
                text = "Voice Commands",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            if (isRecording) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    LoadingIndicator(
                        message = null,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Listening...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            } else if (lastCommand != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Command executed",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Last command: \"$lastCommand\"",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                Text(
                    text = "No commands yet. Press the microphone to start.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Voice recording button (FAB)
 * Equivalent to iOS RecordButton
 */
@Composable
private fun VoiceRecordButton(
    isRecording: Boolean,
    onStartRecording: () -> Unit,
    onStopRecording: () -> Unit,
    modifier: Modifier = Modifier
) {
    FloatingActionButton(
        onClick = {
            if (isRecording) {
                onStopRecording()
            } else {
                onStartRecording()
            }
        },
        modifier = modifier.size(80.dp),
        containerColor = if (isRecording) 
            MaterialTheme.colorScheme.error 
        else 
            MaterialTheme.colorScheme.primary,
        contentColor = if (isRecording) 
            MaterialTheme.colorScheme.onError 
        else 
            MaterialTheme.colorScheme.onPrimary
    ) {
        Icon(
            imageVector = if (isRecording) Icons.Default.Stop else Icons.Default.Mic,
            contentDescription = if (isRecording) "Stop recording" else "Start recording",
            modifier = Modifier.size(32.dp)
        )
    }
}

/**
 * Quick actions row for common functions
 * Equivalent to iOS quick action buttons
 */
@Composable
private fun QuickActionsRow(
    onNetworkSettings: () -> Unit,
    onSubscription: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        
        // Network Settings Quick Action
        OutlinedButton(
            onClick = onNetworkSettings,
            modifier = Modifier.weight(1f)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Wifi,
                    contentDescription = "Network",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Network",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        // Subscription Quick Action
        OutlinedButton(
            onClick = onSubscription,
            modifier = Modifier.weight(1f)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = "Subscription",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Upgrade",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun VoiceControlMainScreenPreview() {
    VoiceControlTheme {
        VoiceControlMainScreenContent(
            connectionStatus = "Connected",
            lastCommand = "Channel 1 mute on",
            isRecording = false,
            onStartRecording = { },
            onStopRecording = { },
            onNavigateToSettings = { },
            onNavigateToNetworkSettings = { },
            onNavigateToSubscription = { },
            onSignOut = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun VoiceControlMainScreenRecordingPreview() {
    VoiceControlTheme {
        VoiceControlMainScreenContent(
            connectionStatus = "Connected",
            lastCommand = null,
            isRecording = true,
            onStartRecording = { },
            onStopRecording = { },
            onNavigateToSettings = { },
            onNavigateToNetworkSettings = { },
            onNavigateToSubscription = { },
            onSignOut = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun VoiceControlMainScreenDisconnectedPreview() {
    VoiceControlTheme {
        VoiceControlMainScreenContent(
            connectionStatus = "Disconnected",
            lastCommand = null,
            isRecording = false,
            onStartRecording = { },
            onStopRecording = { },
            onNavigateToSettings = { },
            onNavigateToNetworkSettings = { },
            onNavigateToSubscription = { },
            onSignOut = { }
        )
    }
}

/**
 * Content composable for previews
 * Separates UI from ViewModel dependencies for preview purposes
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VoiceControlMainScreenContent(
    connectionStatus: String,
    lastCommand: String?,
    isRecording: Boolean,
    onStartRecording: () -> Unit,
    onStopRecording: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToNetworkSettings: () -> Unit,
    onNavigateToSubscription: () -> Unit,
    onSignOut: () -> Unit
) {
    Scaffold(
        topBar = {
            VoiceControlTopBar(
                connectionStatus = connectionStatus,
                onMenuClick = { },
                onSettingsClick = onNavigateToSettings,
                onNetworkClick = onNavigateToNetworkSettings,
                onSignOutClick = onSignOut
            )
        },
        floatingActionButton = {
            VoiceRecordButton(
                isRecording = isRecording,
                onStartRecording = onStartRecording,
                onStopRecording = onStopRecording
            )
        },
        floatingActionButtonPosition = FabPosition.Center
    ) { paddingValues ->
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            
            VoiceControlWelcomeSection(
                modifier = Modifier.padding(bottom = 32.dp)
            )
            
            ConnectionStatusCard(
                status = connectionStatus,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )
            
            VoiceCommandHistory(
                lastCommand = lastCommand,
                isRecording = isRecording,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            QuickActionsRow(
                onNetworkSettings = onNavigateToNetworkSettings,
                onSubscription = onNavigateToSubscription,
                modifier = Modifier.padding(bottom = 80.dp)
            )
        }
    }
}