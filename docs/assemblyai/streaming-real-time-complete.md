# AssemblyAI Streaming Speech-to-Text Complete Documentation

## Overview
AssemblyAI offers Streaming Speech-to-Text that allows you to transcribe live audio streams with high accuracy and low latency. By streaming your audio data to their secure WebSocket API, you can receive transcripts back within a few hundred milliseconds.

## Key Features

### Universal-Streaming Model
AssemblyAI's new, purpose-built speech-to-text model for voice agents with immutable transcripts in ~300ms, superior accuracy, intelligent endpointing, and unlimited concurrency. This model delivers immutable transcripts in ~300ms, making it perfect for voice agents, live captioning, and interactive applications.

### Immutable Transcripts
Unlike many other streaming speech-to-text models that implement partial/variable transcriptions, Universal-Streaming transcriptions are immutable - the text that has already been produced will not be overwritten in future transcription responses.

### Pricing
Transparent pricing starting at just $0.15/hr — charging for total session duration, not audio duration or pre-purchased capacity. They charge based on total session duration - the entire time your connection stays open, whether audio is flowing or not, giving you complete transparency and control.

## Technical Implementation

### WebSocket Connection
To use the service, users stream audio data to their secure WebSocket API and receive transcripts back within a few hundred milliseconds.

### Authentication
If you need to authenticate on the client, you can avoid exposing your API key by using temporary authentication tokens generated on your server and passed to the client.

### Audio Requirements
- Use a sample rate of at least 16000 Hz for better transcription accuracy
- Audio segments with a duration between 100 ms and 450 ms produce the best results in transcription accuracy
- PCM16 or Mu-law encoding
- Single-channel
- 50ms audio chunks recommended

### Concurrency
Unlimited concurrent streams with no hard caps or over-stream surcharges, with consistent performance from 5 to 50,000+ streams without performance degradation.

## Configuration Options

### End-of-Turn Detection
By default, Streaming Speech-to-Text ends an utterance after 700 milliseconds of silence

### Custom Vocabulary
You can add up to 2500 characters of custom vocabulary to boost their transcription probability

### Encoding Support
By default, transcriptions expect PCM16 encoding

## Core Concepts

### Turn Objects
Turn objects represent a speaking turn or utterance and include:
- `turn_order`: Incremental turn number
- `transcript`: Finalized text
- `end_of_turn`: Boolean indicating turn completion
- `words`: Detailed word-level information
- Include metadata like transcript, confidence scores, and word-level details
- Unique ID assigned to each turn

### Immutable Transcription
- Transcripts do not change once generated
- Words are finalized progressively
- Supports optional text formatting
- Transcripts are "non-overwritable", meaning previous text remains unchanged as new words are added

## Streaming Protocol Details

### Message Types
The streaming API uses WebSocket messages with different types:

1. **Turn Messages**: Contain transcript information with `end_of_turn` flag
2. **Session Messages**: Handle connection lifecycle
3. **Error Messages**: Handle errors and failures

### Final Transcript Behavior
- `end_of_turn: true` indicates a complete speaking turn
- `turn_is_formatted: true` indicates the transcript has been formatted with punctuation
- Final transcripts are immutable once received
- There can be a delay between stopping audio and receiving the final formatted transcript

## Recommended Use Cases
- Voice agents
- Live captioning
- Real-time transcription applications
- Interactive voice applications

## Configuration Parameters
- Sample rate
- Encoding type
- Turn detection confidence threshold
- Silence duration settings
- For multi-speaker scenarios, adjust "min_end_of_turn_silence" to 560ms

## SDK Support
- Python SDK available
- JavaScript SDK available
- Supports microphone streaming
- Provides comprehensive examples

## Authentication Methods
- API key authentication
- Temporary token authentication for client-side usage

## Error Handling
- Standard HTTP response codes
- Detailed error messages
- Potential error codes include 200 (OK), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), 429 (Too Many Requests)
- 402 status code if account not properly configured for streaming

## Rate Limits
- Applies specifically to LeMUR requests
- Limits requests within a 60-second window
- Rate limit information available in response headers

## Implementation Notes
- Requires an upgraded AssemblyAI account for streaming features
- Uses Express for backend implementations
- AudioWorklet for audio processing in browser environments
- Runs typically on port 8000 in development environments

## Base URLs
- Primary: `https://api.assemblyai.com`
- EU servers: `api.eu.assemblyai.com`
- WebSocket endpoints for streaming

## Versioning
- Uses path prefix (e.g., `/v2`)
- Updates tracked in the changelog

## Key Recommendations
- Use 50ms audio chunk sizes for optimal performance
- For voice agents, use unformatted transcripts for lowest latency
- Can be configured for different use cases like voice agents or live captioning
- Wait for `end_of_turn: true` and `turn_is_formatted: true` for final transcripts