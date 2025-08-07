package com.voicecontrol.app.di

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Main Application Module for Dependency Injection
 * 
 * Provides core application dependencies and Firebase services
 * Equivalent to iOS dependency injection container setup
 * 
 * Features:
 * - Firebase Auth instance
 * - Firebase Firestore instance  
 * - Encrypted SharedPreferences for secure storage
 * - Master key for encryption
 * - Application context
 */
@Module
@InstallIn(SingletonComponent::class)
object ApplicationModule {
    
    /**
     * Provides Firebase Authentication instance
     * Equivalent to iOS Firebase Auth configuration
     */
    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth {
        return FirebaseAuth.getInstance()
    }
    
    /**
     * Provides Firebase Firestore instance
     * Equivalent to iOS Firestore configuration
     */
    @Provides
    @Singleton
    fun provideFirebaseFirestore(): FirebaseFirestore {
        return FirebaseFirestore.getInstance()
    }
    
    /**
     * Provides Master Key for encryption
     * Used for secure storage of sensitive data
     */
    @Provides
    @Singleton
    fun provideMasterKey(@ApplicationContext context: Context): MasterKey {
        return MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }
    
    /**
     * Provides Encrypted SharedPreferences
     * Equivalent to iOS Keychain for secure data storage
     */
    @Provides
    @Singleton
    fun provideEncryptedSharedPreferences(
        @ApplicationContext context: Context,
        masterKey: MasterKey
    ): android.content.SharedPreferences {
        return EncryptedSharedPreferences.create(
            context,
            "voice_control_secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }
}