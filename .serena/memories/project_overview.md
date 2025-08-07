# Project Overview - Android Voice Control App

## Purpose
Professional voice control application for Yamaha mixing console control via Android device. Direct port from iOS to Android using modern Android development practices.

## Tech Stack
- **Language**: Kotlin 1.9.22
- **UI Framework**: Jetpack Compose with Material Design 3
- **Architecture**: MVVM with StateFlow reactive programming
- **Dependency Injection**: Hilt DI
- **Authentication**: Firebase Auth 32.7.0 with Google Sign-In and biometric support
- **Database**: Firebase Firestore
- **Speech Recognition**: AssemblyAI WebSocket streaming API
- **Audio**: AudioRecord for real-time PCM capture
- **Network**: OkHttp3 with WebSocket support
- **Target**: Android 9.0+ (API 28+)
- **Build**: Gradle 8.x with Kotlin DSL

## Bundle ID
`com.voicecontrol.app`

## Architecture Overview
**MVVM Pattern with Reactive Flows**
- **Model**: Data classes, services, and business logic
- **View**: Jetpack Compose UI components
- **ViewModel**: StateFlow-based reactive state management with Hilt injection
- **Repository Pattern**: Service layer for data access and external API integration
- **Feature-based Package Structure**: Organized by business domain

## Key Features Implemented
1. **Authentication System**: Firebase Auth + Google Sign-In + Biometric authentication
2. **Real-time Speech Recognition**: AssemblyAI WebSocket streaming with 16kHz PCM audio
3. **Voice Command Processing**: Professional audio command parsing and execution
4. **Network Settings**: Configurable RCP protocol for Yamaha mixer communication
5. **Sophisticated UI Components**: Advanced RecordButton with audio level visualization
6. **Professional Logging**: Structured logging with build configuration controls

## Core Services Architecture
- **SpeechRecognitionService**: Main coordination layer (AudioManager + AssemblyAIStreamer)
- **AssemblyAIStreamer**: WebSocket client for real-time speech-to-text
- **AudioManager**: Low-level audio capture and processing
- **VoiceCommandProcessor**: Command parsing and mixer control
- **SecureStorageService**: Encrypted storage for sensitive data

## Current Implementation Status
- ✅ **Complete**: Authentication, network settings, service layer
- ✅ **Complete**: RecordButton component with animations and states
- ✅ **Complete**: Speech services (AssemblyAIStreamer, SpeechRecognitionService)
- ❌ **Missing**: ViewModel to connect services to UI
- ❌ **Missing**: DI configuration for speech services
- ❌ **Missing**: Main screen integration (currently uses placeholder button)