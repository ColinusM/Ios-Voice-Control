package com.voicecontrol.app.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import javax.inject.Singleton

/**
 * Speech Module for Dependency Injection
 * 
 * Provides speech recognition services and audio processing
 * Equivalent to iOS speech service container
 * 
 * Features:
 * - AudioManager for real-time audio capture
 * - AssemblyAIStreamer for speech-to-text streaming
 * - SpeechRecognitionService for complete recognition pipeline
 * - VoiceCommandProcessor for command processing
 * - Proper service lifecycle management
 */
@Module
@InstallIn(SingletonComponent::class)
object SpeechModule {
    
    /**
     * Provides AudioManager singleton
     * Handles real-time audio capture and processing
     * Equivalent to iOS AVAudioEngine configuration
     */
    @Provides
    @Singleton
    fun provideAudioManager(
        @ApplicationContext context: Context
    ): com.voicecontrol.app.speech.service.AudioManager {
        return com.voicecontrol.app.speech.service.AudioManager(context)
    }
    
    /**
     * Provides AssemblyAI Streamer singleton
     * Handles WebSocket streaming to AssemblyAI for speech recognition
     * Equivalent to iOS speech recognition API client
     */
    @Provides
    @Singleton
    fun provideAssemblyAIStreamer(
        @WebSocketHttpClient okHttpClient: OkHttpClient
    ): com.voicecontrol.app.speech.service.AssemblyAIStreamer {
        return com.voicecontrol.app.speech.service.AssemblyAIStreamer(okHttpClient)
    }
    
    /**
     * Provides Speech Recognition Service singleton
     * Main coordination service for complete speech recognition pipeline
     * Equivalent to iOS SpeechRecognizer coordination
     */
    @Provides
    @Singleton
    fun provideSpeechRecognitionService(
        audioManager: com.voicecontrol.app.speech.service.AudioManager,
        assemblyAIStreamer: com.voicecontrol.app.speech.service.AssemblyAIStreamer
    ): com.voicecontrol.app.speech.service.SpeechRecognitionService {
        return com.voicecontrol.app.speech.service.SpeechRecognitionService(audioManager, assemblyAIStreamer)
    }
    
    /**
     * Provides Voice Command Processor singleton
     * Processes voice commands and converts to mixer actions
     * Equivalent to iOS voice command processing pipeline
     */
    @Provides
    @Singleton
    fun provideVoiceCommandProcessor(): com.voicecontrol.app.voice.service.VoiceCommandProcessor {
        return com.voicecontrol.app.voice.service.VoiceCommandProcessor()
    }
}