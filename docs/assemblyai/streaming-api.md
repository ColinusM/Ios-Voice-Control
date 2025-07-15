# AssemblyAI Streaming Speech-to-Text API Documentation

## Core Concepts

### Turn Objects
Turn objects represent a speaking turn/utterance and include metadata such as:
- `turn_order`: Sequential order of the turn
- `transcript`: The transcribed text
- `end_of_turn_confidence`: Confidence level for turn completion
- Individual word details with timestamps

### Immutable Transcription
- Transcriptions are not overwritten
- Words are finalized progressively  
- Supports optional text formatting

## Audio Requirements

### Format Specifications
- **Encoding**: PCM16 or Mu-law encoding
- **Channels**: Single-channel (mono)
- **Chunk Size**: 50ms audio chunks recommended
- **Sample Rate**: Must match the specified parameter in configuration

### Recommended Settings
- Sample rate: 16kHz for optimal performance
- Chunk duration: 50ms (0.05 seconds)
- Buffer size: 1024 samples

## Connection Parameters

### Required Parameters
- `sample_rate`: Integer specifying audio sample rate
- `encoding`: Audio encoding format (PCM or Mu-law)

### Optional Parameters
- `format_turns`: Boolean for text formatting
- `end_of_turn_confidence_threshold`: Configurable threshold (default 0.7)
- `min_end_of_turn_silence_when_confident`: Minimum silence duration
- `max_turn_silence`: Maximum silence before turn termination

## Message Types

### Sent by Client
- **Audio data**: Binary audio chunks
- **Configuration updates**: Runtime parameter changes
- **Session termination**: Close the streaming session
- **Force endpoint**: Manually trigger turn completion

### Received from Server
- **Session begin**: Confirmation of session establishment
- **Turn transcriptions**: Real-time transcription results
- **Session termination**: Server-side session closure

## Protocol Flow

1. **Connection**: Establish WebSocket connection with authentication
2. **Session Begin**: Server sends session begin message
3. **Audio Streaming**: Client sends audio data chunks
4. **Transcription**: Server responds with turn transcriptions
5. **Session End**: Either party can terminate the session

## Recommended Use Cases
- Voice agents and conversational AI
- Live captioning and accessibility
- Real-time transcription scenarios
- Interactive voice applications

## Best Practices
- Send audio in consistent 50ms chunks
- Monitor connection stability
- Handle reconnection scenarios
- Implement proper error handling
- Use appropriate confidence thresholds