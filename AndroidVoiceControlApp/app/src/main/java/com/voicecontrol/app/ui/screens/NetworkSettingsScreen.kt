package com.voicecontrol.app.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState
import com.voicecontrol.app.network.model.NetworkSettings
import com.voicecontrol.app.ui.theme.VoiceControlColors.AudioBlue
import com.voicecontrol.app.ui.theme.VoiceControlColors.ConnectedGreen
import com.voicecontrol.app.ui.theme.VoiceControlColors.BrandOrange  
import com.voicecontrol.app.ui.theme.VoiceControlColors.BrandError
import com.voicecontrol.app.ui.viewmodel.NetworkSettingsViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * Network Settings Screen for Voice Control App
 * 
 * Direct port of iOS NetworkSettingsView to Compose UI
 * Provides interface for configuring RCP network communication
 * 
 * Features:
 * - Target selection (Console vs Testing GUI)
 * - IP address and port configuration
 * - Connection testing with real-time feedback
 * - Connection status monitoring
 * - Advanced settings (timeout, logging)
 * - Reset to defaults functionality
 * - Material Design 3 theming
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NetworkSettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: NetworkSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val scrollState = rememberScrollState()
    
    var showResetDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = "Network Settings",
                        style = MaterialTheme.typography.headlineSmall
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    // Reset button
                    IconButton(
                        onClick = { showResetDialog = true }
                    ) {
                        Icon(
                            imageVector = Icons.Default.RestartAlt,
                            contentDescription = "Reset to Defaults"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = AudioBlue,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                    actionIconContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
                .verticalScroll(scrollState),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Target Selection Section
            TargetSelectionSection(
                selectedTarget = uiState.targetType,
                onTargetSelected = { viewModel.setTargetType(it) }
            )
            
            // Console Configuration (when Console is selected)
            if (uiState.targetType == NetworkSettings.NetworkTargetType.CONSOLE) {
                ConsoleConfigurationSection(
                    consoleIP = uiState.consoleIP,
                    consolePort = uiState.consolePort,
                    onIPChanged = { viewModel.setConsoleIP(it) },
                    onPortChanged = { viewModel.setConsolePort(it) },
                    onTestConnection = { viewModel.testConnection() },
                    isTestingConnection = uiState.isTestingConnection
                )
            }
            
            // Testing Configuration (when Testing GUI is selected)
            if (uiState.targetType == NetworkSettings.NetworkTargetType.TESTING_GUI) {
                TestingConfigurationSection(
                    testingIP = uiState.testingIP,
                    testingPort = uiState.testingPort,
                    onIPChanged = { viewModel.setTestingIP(it) },
                    onPortChanged = { viewModel.setTestingPort(it) },
                    onTestConnection = { viewModel.testConnection() },
                    isTestingConnection = uiState.isTestingConnection
                )
            }
            
            // Connection Status Section
            ConnectionStatusSection(
                connectionStatus = uiState.connectionStatus,
                isNetworkAvailable = uiState.isNetworkAvailable,
                lastConnectionTime = uiState.lastConnectionTime,
                testResult = uiState.testResult
            )
            
            // Advanced Settings Section
            AdvancedSettingsSection(
                timeoutSeconds = uiState.timeoutSeconds,
                enableLogging = uiState.enableLogging,
                onTimeoutChanged = { viewModel.setTimeoutSeconds(it) },
                onLoggingChanged = { viewModel.setEnableLogging(it) }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
    
    // Reset Confirmation Dialog
    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset Network Settings") },
            text = { Text("Are you sure you want to reset all network settings to their default values? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.resetToDefaults()
                        showResetDialog = false
                    }
                ) {
                    Text("Reset", color = BrandError)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun TargetSelectionSection(
    selectedTarget: NetworkSettings.NetworkTargetType,
    onTargetSelected: (NetworkSettings.NetworkTargetType) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Command Destination",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            NetworkSettings.NetworkTargetType.allCases.forEach { targetType ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = selectedTarget == targetType,
                        onClick = { onTargetSelected(targetType) },
                        colors = RadioButtonDefaults.colors(selectedColor = AudioBlue)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = targetType.displayName,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = when (targetType) {
                                NetworkSettings.NetworkTargetType.CONSOLE -> 
                                    "Send commands to Yamaha console"
                                NetworkSettings.NetworkTargetType.TESTING_GUI -> 
                                    "Send commands to Mac GUI for testing"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ConsoleConfigurationSection(
    consoleIP: String,
    consolePort: Int,
    onIPChanged: (String) -> Unit,
    onPortChanged: (Int) -> Unit,
    onTestConnection: () -> Unit,
    isTestingConnection: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = null,
                    tint = AudioBlue
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Console Configuration",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            // Console IP Address
            OutlinedTextField(
                value = consoleIP,
                onValueChange = onIPChanged,
                label = { Text("Console IP Address") },
                placeholder = { Text("192.168.1.100") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Router,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Console Port
            OutlinedTextField(
                value = consolePort.toString(),
                onValueChange = { 
                    it.toIntOrNull()?.let { port -> 
                        if (port in 1..65535) onPortChanged(port)
                    }
                },
                label = { Text("Console Port") },
                placeholder = { Text("49280") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Cable,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Test Connection Button
            Button(
                onClick = onTestConnection,
                enabled = !isTestingConnection && consoleIP.isNotBlank() && consolePort > 0,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = ConnectedGreen)
            ) {
                if (isTestingConnection) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Testing Connection...")
                } else {
                    Icon(
                        imageVector = Icons.Default.NetworkCheck,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Test Console Connection")
                }
            }
        }
    }
}

@Composable
private fun TestingConfigurationSection(
    testingIP: String,
    testingPort: Int,
    onIPChanged: (String) -> Unit,
    onPortChanged: (Int) -> Unit,
    onTestConnection: () -> Unit,
    isTestingConnection: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.BugReport,
                    contentDescription = null,
                    tint = BrandOrange
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Testing Configuration",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            // Testing IP Address
            OutlinedTextField(
                value = testingIP,
                onValueChange = onIPChanged,
                label = { Text("Mac GUI IP Address") },
                placeholder = { Text("192.168.1.200") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Computer,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Testing Port
            OutlinedTextField(
                value = testingPort.toString(),
                onValueChange = { 
                    it.toIntOrNull()?.let { port -> 
                        if (port in 1..65535) onPortChanged(port)
                    }
                },
                label = { Text("GUI Port") },
                placeholder = { Text("8080") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Cable,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Test Connection Button
            Button(
                onClick = onTestConnection,
                enabled = !isTestingConnection && testingIP.isNotBlank() && testingPort > 0,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = BrandOrange)
            ) {
                if (isTestingConnection) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Testing Connection...")
                } else {
                    Icon(
                        imageVector = Icons.Default.NetworkCheck,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Test GUI Connection")
                }
            }
        }
    }
}

@Composable
private fun ConnectionStatusSection(
    connectionStatus: NetworkSettings.ConnectionStatus,
    isNetworkAvailable: Boolean,
    lastConnectionTime: Long?,
    testResult: String?
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.NetworkWifi,
                    contentDescription = null,
                    tint = if (connectionStatus.isConnected) ConnectedGreen else BrandError
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Connection Status",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            // Connection Status
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Status:",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .padding(end = 4.dp)
                    ) {
                        Canvas(modifier = Modifier.fillMaxSize()) {
                            drawCircle(
                                color = when (connectionStatus) {
                                    NetworkSettings.ConnectionStatus.CONNECTED -> Color(0xFF4CAF50)
                                    NetworkSettings.ConnectionStatus.CONNECTING -> Color(0xFFFFA726)
                                    NetworkSettings.ConnectionStatus.ERROR -> Color(0xFFF44336)
                                    NetworkSettings.ConnectionStatus.DISCONNECTED -> Color(0xFF757575)
                                }
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = connectionStatus.displayName,
                        style = MaterialTheme.typography.bodyMedium,
                        color = when (connectionStatus) {
                            NetworkSettings.ConnectionStatus.CONNECTED -> ConnectedGreen
                            NetworkSettings.ConnectionStatus.CONNECTING -> BrandOrange
                            NetworkSettings.ConnectionStatus.ERROR -> BrandError
                            NetworkSettings.ConnectionStatus.DISCONNECTED -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        }
                    )
                }
            }
            
            // Network Availability
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Network Available:",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = if (isNetworkAvailable) "Yes" else "No",
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isNetworkAvailable) ConnectedGreen else BrandError
                )
            }
            
            // Last Connection Time
            lastConnectionTime?.let { timestamp ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Last Successful Connection:",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date(timestamp)),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
            
            // Test Result
            testResult?.let { result ->
                HorizontalDivider()
                Text(
                    text = "Test Result:",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = result,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (result.contains("successful", ignoreCase = true)) 
                        ConnectedGreen else BrandError,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun AdvancedSettingsSection(
    timeoutSeconds: Int,
    enableLogging: Boolean,
    onTimeoutChanged: (Int) -> Unit,
    onLoggingChanged: (Boolean) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Tune,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Advanced Settings",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            // Connection Timeout
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Connection Timeout:",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "${timeoutSeconds}s",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AudioBlue
                    )
                }
                
                Slider(
                    value = timeoutSeconds.toFloat(),
                    onValueChange = { onTimeoutChanged(it.toInt()) },
                    valueRange = 1f..30f,
                    steps = 29,
                    colors = SliderDefaults.colors(
                        thumbColor = AudioBlue,
                        activeTrackColor = AudioBlue
                    )
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "1s",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        text = "30s",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
            }
            
            // Enable Network Logging
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Enable Network Logging",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Log network requests for debugging",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
                Switch(
                    checked = enableLogging,
                    onCheckedChange = onLoggingChanged,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = AudioBlue,
                        checkedTrackColor = AudioBlue.copy(alpha = 0.5f)
                    )
                )
            }
        }
    }
}