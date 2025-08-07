package com.voicecontrol.app.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit
import javax.inject.Named
import javax.inject.Qualifier
import javax.inject.Singleton

/**
 * Network Module for Dependency Injection
 * 
 * Provides network-related services and HTTP clients
 * Equivalent to iOS network service container
 * 
 * Features:
 * - OkHttp client for general HTTP requests
 * - WebSocket client for real-time communication
 * - Logging interceptor for debugging
 * - Proper timeout configurations
 * - Network security configurations
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    /**
     * Provides HTTP Logging Interceptor
     * For debugging network requests in development builds
     */
    @Provides
    @Singleton
    fun provideHttpLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
    }
    
    /**
     * Provides standard OkHttp client
     * For general HTTP requests (RCP commands, API calls)
     * Equivalent to iOS URLSession configuration
     */
    @Provides
    @Singleton
    @StandardHttpClient
    fun provideStandardOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(10, TimeUnit.SECONDS)
            .writeTimeout(10, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }
    
    /**
     * Provides WebSocket OkHttp client
     * For real-time communication (AssemblyAI streaming)
     * Equivalent to iOS WebSocket configuration
     */
    @Provides
    @Singleton
    @WebSocketHttpClient
    fun provideWebSocketOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(10, TimeUnit.SECONDS)
            .writeTimeout(10, TimeUnit.SECONDS)
            .readTimeout(0, TimeUnit.SECONDS) // No read timeout for streaming
            .pingInterval(30, TimeUnit.SECONDS) // Keep connection alive
            .build()
    }
    
    /**
     * Provides RCP Network client (Custom Qualifier)
     * For Yamaha mixer communication
     * Equivalent to iOS RCPNetworkClient
     */
    @Provides
    @Singleton
    @RCPHttpClient
    fun provideRCPOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(5, TimeUnit.SECONDS)  // Faster timeout for mixer
            .writeTimeout(5, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .build()
    }
    
    /**
     * Provides RCP Network client (Named Qualifier) 
     * Alternative provider for @Named("RCPHttpClient") injection
     * Same client configuration as above but with Named qualifier
     */
    @Provides
    @Singleton
    @Named("RCPHttpClient")
    fun provideNamedRCPOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(5, TimeUnit.SECONDS)  // Faster timeout for mixer
            .writeTimeout(5, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .build()
    }
}

/**
 * Qualifier annotations for different HTTP client types
 * Allows Hilt to distinguish between different OkHttpClient instances
 */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class StandardHttpClient

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class WebSocketHttpClient

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class RCPHttpClient