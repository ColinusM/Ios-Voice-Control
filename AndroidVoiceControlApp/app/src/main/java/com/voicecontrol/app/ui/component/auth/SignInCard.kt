package com.voicecontrol.app.ui.component.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.voicecontrol.app.authentication.viewmodel.AuthenticationViewModel
import com.voicecontrol.app.ui.component.common.LoadingButton
import com.voicecontrol.app.ui.theme.VoiceControlTheme

/**
 * Sign In Card Component for Authentication Screen
 * 
 * Direct port of iOS SignInView to Compose
 * Handles email/password sign-in, sign-up, Google Sign-In, and guest mode
 * 
 * Features:
 * - Email and password input fields (equivalent to iOS UITextField)
 * - Form validation with inline error messages
 * - Sign-in and sign-up mode switching
 * - Google Sign-In integration (equivalent to iOS GoogleSignInButton)
 * - Guest mode access for Apple App Store compliance
 * - Keyboard handling and focus management
 * - Loading states and error handling
 * - Accessibility support
 * 
 * @param authViewModel Authentication view model for state management
 * @param isLoading Whether any authentication operation is in progress
 * @param onGoogleSignIn Callback for Google Sign-In button
 * @param onGuestMode Callback for guest mode button
 * @param modifier Modifier for styling and layout
 */
@Composable
fun SignInCard(
    authViewModel: AuthenticationViewModel,
    isLoading: Boolean,
    onGoogleSignIn: () -> Unit,
    onGuestMode: () -> Unit,
    modifier: Modifier = Modifier
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var isSignUpMode by remember { mutableStateOf(false) }
    
    val focusManager = LocalFocusManager.current
    val passwordFocusRequester = remember { FocusRequester() }
    val confirmPasswordFocusRequester = remember { FocusRequester() }
    
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        shape = MaterialTheme.shapes.large
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            
            // MARK: - Header
            Text(
                text = if (isSignUpMode) "Create Account" else "Sign In",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Text(
                text = if (isSignUpMode) 
                    "Create your Voice Control account" 
                else 
                    "Welcome back to Voice Control",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp, bottom = 24.dp)
            )
            
            // MARK: - Display Name Field (Sign Up only)
            if (isSignUpMode) {
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    label = { Text("Full Name") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Email, // Using email icon as placeholder
                            contentDescription = "Name icon"
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Text,
                        imeAction = ImeAction.Next
                    ),
                    singleLine = true,
                    enabled = !isLoading
                )
                
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // MARK: - Email Field
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Email,
                        contentDescription = "Email icon"
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next
                ),
                keyboardActions = KeyboardActions(
                    onNext = { passwordFocusRequester.requestFocus() }
                ),
                singleLine = true,
                enabled = !isLoading
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // MARK: - Password Field
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "Password icon"
                    )
                },
                trailingIcon = {
                    IconButton(
                        onClick = { isPasswordVisible = !isPasswordVisible }
                    ) {
                        Icon(
                            imageVector = if (isPasswordVisible) 
                                Icons.Default.Visibility 
                            else 
                                Icons.Default.VisibilityOff,
                            contentDescription = if (isPasswordVisible) 
                                "Hide password" 
                            else 
                                "Show password"
                        )
                    }
                },
                visualTransformation = if (isPasswordVisible) 
                    VisualTransformation.None 
                else 
                    PasswordVisualTransformation(),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(passwordFocusRequester),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = if (isSignUpMode) ImeAction.Next else ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onNext = { 
                        if (isSignUpMode) {
                            confirmPasswordFocusRequester.requestFocus()
                        }
                    },
                    onDone = { 
                        focusManager.clearFocus()
                        if (!isSignUpMode && email.isNotBlank() && password.isNotBlank()) {
                            authViewModel.signInWithEmailPassword(email, password)
                        }
                    }
                ),
                singleLine = true,
                enabled = !isLoading
            )
            
            // MARK: - Confirm Password Field (Sign Up only)
            if (isSignUpMode) {
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = confirmPassword,
                    onValueChange = { confirmPassword = it },
                    label = { Text("Confirm Password") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = "Confirm password icon"
                        )
                    },
                    trailingIcon = {
                        IconButton(
                            onClick = { isPasswordVisible = !isPasswordVisible }
                        ) {
                            Icon(
                                imageVector = if (isPasswordVisible) 
                                    Icons.Default.Visibility 
                                else 
                                    Icons.Default.VisibilityOff,
                                contentDescription = if (isPasswordVisible) 
                                    "Hide password" 
                                else 
                                    "Show password"
                            )
                        }
                    },
                    visualTransformation = if (isPasswordVisible) 
                        VisualTransformation.None 
                    else 
                        PasswordVisualTransformation(),
                    modifier = Modifier
                        .fillMaxWidth()
                        .focusRequester(confirmPasswordFocusRequester),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { 
                            focusManager.clearFocus()
                            if (email.isNotBlank() && password.isNotBlank() && 
                                password == confirmPassword && displayName.isNotBlank()) {
                                authViewModel.signUpWithEmailPassword(email, password, displayName)
                            }
                        }
                    ),
                    singleLine = true,
                    enabled = !isLoading,
                    isError = isSignUpMode && confirmPassword.isNotEmpty() && password != confirmPassword
                )
                
                // Password mismatch error
                if (isSignUpMode && confirmPassword.isNotEmpty() && password != confirmPassword) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(start = 16.dp, top = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Passwords do not match",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // MARK: - Primary Action Button
            LoadingButton(
                text = if (isSignUpMode) "Create Account" else "Sign In",
                isLoading = isLoading,
                onClick = {
                    focusManager.clearFocus()
                    if (isSignUpMode) {
                        if (email.isNotBlank() && password.isNotBlank() && 
                            password == confirmPassword && displayName.isNotBlank()) {
                            authViewModel.signUpWithEmailPassword(email, password, displayName)
                        }
                    } else {
                        if (email.isNotBlank() && password.isNotBlank()) {
                            authViewModel.signInWithEmailPassword(email, password)
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = if (isSignUpMode) {
                    email.isNotBlank() && password.isNotBlank() && 
                    confirmPassword.isNotBlank() && displayName.isNotBlank() &&
                    password == confirmPassword
                } else {
                    email.isNotBlank() && password.isNotBlank()
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // MARK: - Mode Switch
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isSignUpMode) 
                        "Already have an account?" 
                    else 
                        "Don't have an account?",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                TextButton(
                    onClick = { 
                        isSignUpMode = !isSignUpMode
                        // Clear form when switching modes
                        email = ""
                        password = ""
                        confirmPassword = ""
                        displayName = ""
                    },
                    enabled = !isLoading
                ) {
                    Text(
                        text = if (isSignUpMode) "Sign In" else "Sign Up",
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // MARK: - Divider
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Divider(modifier = Modifier.weight(1f))
                Text(
                    text = "or",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
                Divider(modifier = Modifier.weight(1f))
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // MARK: - Google Sign-In Button
            OutlinedButton(
                onClick = onGoogleSignIn,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // TODO: Add Google logo icon
                    Text("Sign in with Google")
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // MARK: - Guest Mode Button
            TextButton(
                onClick = onGuestMode,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Text(
                    text = "Continue as Guest",
                    style = MaterialTheme.typography.labelLarge
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // MARK: - Forgot Password (Sign In mode only)
            if (!isSignUpMode) {
                TextButton(
                    onClick = { 
                        // TODO: Implement forgot password
                    },
                    enabled = !isLoading
                ) {
                    Text(
                        text = "Forgot Password?",
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun SignInCardPreview() {
    VoiceControlTheme {
        SignInCardContent(
            isLoading = false,
            isSignUpMode = false,
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun SignInCardSignUpPreview() {
    VoiceControlTheme {
        SignInCardContent(
            isLoading = false,
            isSignUpMode = true,
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun SignInCardLoadingPreview() {
    VoiceControlTheme {
        SignInCardContent(
            isLoading = true,
            isSignUpMode = false,
            onSignIn = { _, _ -> },
            onSignUp = { _, _, _ -> },
            onGoogleSignIn = { },
            onGuestMode = { }
        )
    }
}

/**
 * Content composable for previews
 * Separates UI from ViewModel dependency for preview purposes
 */
@Composable
private fun SignInCardContent(
    isLoading: Boolean,
    isSignUpMode: Boolean,
    onSignIn: (String, String) -> Unit,
    onSignUp: (String, String, String) -> Unit,
    onGoogleSignIn: () -> Unit,
    onGuestMode: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var currentSignUpMode by remember { mutableStateOf(isSignUpMode) }
    
    val focusManager = LocalFocusManager.current
    
    Card(
        modifier = Modifier.padding(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        shape = MaterialTheme.shapes.large
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            
            Text(
                text = if (currentSignUpMode) "Create Account" else "Sign In",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Text(
                text = if (currentSignUpMode) 
                    "Create your Voice Control account" 
                else 
                    "Welcome back to Voice Control",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp, bottom = 24.dp)
            )
            
            if (currentSignUpMode) {
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    label = { Text("Full Name") },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading
                )
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                leadingIcon = { Icon(Icons.Default.Email, contentDescription = null) },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                trailingIcon = {
                    IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                        Icon(
                            if (isPasswordVisible) Icons.Default.Visibility 
                            else Icons.Default.VisibilityOff,
                            contentDescription = null
                        )
                    }
                },
                visualTransformation = if (isPasswordVisible) 
                    VisualTransformation.None 
                else 
                    PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            )
            
            if (currentSignUpMode) {
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = confirmPassword,
                    onValueChange = { confirmPassword = it },
                    label = { Text("Confirm Password") },
                    leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                    visualTransformation = if (isPasswordVisible) 
                        VisualTransformation.None 
                    else 
                        PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading,
                    isError = confirmPassword.isNotEmpty() && password != confirmPassword
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            if (isLoading) {
                CircularProgressIndicator()
            } else {
                Button(
                    onClick = {
                        if (currentSignUpMode) {
                            onSignUp(email, password, displayName)
                        } else {
                            onSignIn(email, password)
                        }
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(if (currentSignUpMode) "Create Account" else "Sign In")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row {
                Text(
                    if (currentSignUpMode) "Already have an account?" 
                    else "Don't have an account?",
                    style = MaterialTheme.typography.bodyMedium
                )
                TextButton(onClick = { currentSignUpMode = !currentSignUpMode }) {
                    Text(if (currentSignUpMode) "Sign In" else "Sign Up")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            OutlinedButton(
                onClick = onGoogleSignIn,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Text("Sign in with Google")
            }
            
            TextButton(
                onClick = onGuestMode,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                Text("Continue as Guest")
            }
        }
    }
}