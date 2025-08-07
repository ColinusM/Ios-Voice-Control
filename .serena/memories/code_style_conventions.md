# Code Style & Conventions - Android Voice Control App

## Kotlin Conventions

### Naming
- **Classes**: PascalCase (`VoiceRecordingViewModel`, `SpeechRecognitionService`)
- **Functions**: camelCase (`startRecording()`, `handleAudioData()`)
- **Variables**: camelCase (`isRecording`, `audioLevel`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_RECONNECT_ATTEMPTS`, `TAG`)
- **Packages**: lowercase with dots (`com.voicecontrol.app.speech.service`)

### File Structure
- **Services**: End with `Service` (`SpeechRecognitionService`)
- **ViewModels**: End with `ViewModel` (`VoiceRecordingViewModel`)
- **Compose Components**: PascalCase, descriptive (`RecordButton`, `VoiceControlMainScreen`)
- **Data Classes**: Descriptive names (`TranscriptionResult`, `StreamingConfig`)

## Package Organization (Feature-Based)
```
com.voicecontrol.app/
├── authentication/          # Auth features
│   ├── model/              # Auth data classes
│   ├── service/            # Auth services  
│   └── viewmodel/          # Auth ViewModels
├── speech/                 # Speech recognition
│   ├── model/              # Speech data classes
│   └── service/            # Speech services
├── voice/                  # Voice command processing
├── ui/                     # UI components and screens
│   ├── components/         # Reusable components
│   ├── screen/            # Screen-level composables
│   └── theme/             # Theming and styling
├── di/                    # Dependency injection
└── network/               # Network services
```

## Compose UI Conventions

### Component Structure
```kotlin
@Composable
fun ComponentName(
    // State parameters first
    isActive: Boolean,
    data: String,
    // Callbacks second
    onClick: () -> Unit,
    onValueChange: (String) -> Unit,
    // Styling last
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    // Implementation
}
```

### State Management
- Use `StateFlow` in ViewModels
- `collectAsState()` for observing in Compose
- `remember` for local UI state only
- Prefer `derivedStateOf` for computed state

## Service Layer Patterns

### Dependency Injection (Hilt)
```kotlin
@Singleton
class ServiceName @Inject constructor(
    private val dependency: Dependency
) {
    // Implementation
}

@HiltViewModel  
class ViewModelName @Inject constructor(
    private val service: ServiceName
) : ViewModel() {
    // Implementation
}
```

### StateFlow Patterns
```kotlin
private val _state = MutableStateFlow(InitialValue)
val state: StateFlow<Type> = _state.asStateFlow()

// Combine multiple flows
val uiState = combine(flow1, flow2, flow3) { a, b, c ->
    UiState(a, b, c)
}.stateIn(viewModelScope, SharingStarted.Lazily, InitialUiState)
```

## Documentation Standards

### Class Headers
```kotlin
/**
 * Brief description of class purpose
 * 
 * Detailed description including iOS equivalence if applicable
 * 
 * Features:
 * - Feature 1
 * - Feature 2
 * 
 * @param param Description
 */
```

### Method Documentation
```kotlin
/**
 * Brief method description
 * Equivalent to iOS methodName if applicable
 */
suspend fun methodName(): ReturnType
```

## Logging Conventions

### Structured Logging
```kotlin
companion object {
    private const val TAG = "ClassName"
}

if (BuildConfig.ENABLE_LOGGING) {
    Log.d(TAG, "🚀 Starting process")
    Log.w(TAG, "⚠️ Warning condition")  
    Log.e(TAG, "❌ Error occurred", exception)
}
```

### Log Prefixes
- 🚀 Starting operations
- ✅ Success operations
- 🛑 Stopping operations  
- ⚠️ Warnings
- ❌ Errors
- 📊 Configuration/data
- 🔗 Connection states
- 🎵 Audio processing

## Error Handling Patterns

### Service Layer
```kotlin
try {
    // Operation
    _state.value = SuccessState
} catch (e: Exception) {
    if (BuildConfig.ENABLE_LOGGING) {
        Log.e(TAG, "❌ Operation failed", e)
    }
    _state.value = ErrorState(e.message)
}
```

### ViewModel Layer  
```kotlin
viewModelScope.launch {
    try {
        _uiState.update { it.copy(loading = true) }
        val result = service.performOperation()
        _uiState.update { it.copy(loading = false, result = result) }
    } catch (e: Exception) {
        _uiState.update { it.copy(loading = false, error = e.message) }
    }
}
```

## Performance Guidelines

### Compose Performance
- Use `key()` for list items that can reorder
- Prefer `LazyColumn` over `Column` with `Modifier.verticalScroll()`  
- Use `derivedStateOf` for expensive computations
- Minimize recomposition with stable parameters

### StateFlow Performance
- Use `SharingStarted.Lazily` for derived state
- Prefer `combine()` over manual flow collection
- Use `stateIn()` to convert hot flows to state

## Testing Conventions

### File Naming
- Unit tests: `ClassNameTest.kt`
- Integration tests: `ClassNameIntegrationTest.kt`  
- UI tests: `ScreenNameTest.kt`

### Test Structure
```kotlin
@Test
fun `methodName should do something when condition`() {
    // Given
    
    // When
    
    // Then
}
```