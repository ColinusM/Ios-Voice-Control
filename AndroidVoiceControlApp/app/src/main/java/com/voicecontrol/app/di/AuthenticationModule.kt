package com.voicecontrol.app.di

import android.content.Context
import android.content.SharedPreferences
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.voicecontrol.app.authentication.service.BiometricAuthService
import com.voicecontrol.app.authentication.service.FirebaseAuthService
import com.voicecontrol.app.authentication.service.GoogleSignInService
import com.voicecontrol.app.authentication.service.SecureStorageService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Authentication Module for Dependency Injection
 * 
 * Provides all authentication-related services and dependencies
 * Equivalent to iOS authentication service container
 * 
 * Features:
 * - Firebase Authentication Service
 * - Google Sign-In Service  
 * - Biometric Authentication Service
 * - Secure Storage Service
 * - All authentication dependencies properly scoped
 */
@Module
@InstallIn(SingletonComponent::class)
object AuthenticationModule {
    
    /**
     * Provides Firebase Authentication Service
     * Handles email/password authentication and Firebase user management
     * Equivalent to iOS FirebaseAuthService
     */
    @Provides
    @Singleton
    fun provideFirebaseAuthService(
        firebaseAuth: FirebaseAuth,
        firestore: FirebaseFirestore
    ): FirebaseAuthService {
        return FirebaseAuthService(
            firebaseAuth = firebaseAuth,
            firestore = firestore
        )
    }
    
    /**
     * Provides Google Sign-In Service
     * Handles Google OAuth authentication flow
     * Equivalent to iOS GoogleSignInService
     */
    @Provides
    @Singleton
    fun provideGoogleSignInService(
        @ApplicationContext context: Context
    ): GoogleSignInService {
        return GoogleSignInService(context)
    }
    
    /**
     * Provides Secure Storage Service
     * Handles encrypted storage of sensitive authentication data
     * Equivalent to iOS Keychain service
     */
    @Provides
    @Singleton
    fun provideSecureStorageService(
        @ApplicationContext context: Context
    ): SecureStorageService {
        return SecureStorageService(context)
    }
    
    /**
     * Provides Biometric Authentication Service
     * Handles fingerprint and face authentication
     * Equivalent to iOS LocalAuthentication service
     */
    @Provides
    @Singleton
    fun provideBiometricAuthService(): BiometricAuthService {
        return BiometricAuthService()
    }
}