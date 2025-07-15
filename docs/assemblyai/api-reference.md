# AssemblyAI Streaming API Reference

## WebSocket Endpoint

### Connection Details
- **URL**: `wss://streaming.assemblyai.com/v3/ws`
- **Method**: WebSocket GET request
- **Expected Status**: 101 Switching Protocols

### Authentication
- **Primary**: Use API key in Authorization header
- **Alternative**: Generate temporary token via query parameter

## Query Parameters

### Required Parameters
- `sample_rate`: Audio stream sample rate (integer)

### Optional Parameters
- `encoding` (default: `pcm_s16le`): Audio stream encoding format
- `token`: API authentication token (alternative to header auth)
- `format_turns` (default: `false`): Return formatted final transcripts
- `end_of_turn_confidence_threshold` (default: `0.7`): Confidence level for turn detection
- `min_end_of_turn_silence_when_confident` (default: `160ms`): Minimum silence for turn detection
- `max_turn_silence` (default: `2400ms`): Maximum allowed turn silence

## Message Types

### Client to Server (Send)
1. **Audio Data Chunks**: Binary audio data
2. **Update Configuration**: Runtime parameter changes
3. **Force Endpoint**: Manually trigger turn completion
4. **Session Termination**: Close streaming session

### Server to Client (Receive)
1. **Session Begins**: Confirmation of session establishment
2. **Turn-based Transcriptions**: Real-time transcription results
3. **Session Termination**: Server-side session closure

## Protocol Specification

### Connection Flow
1. Establish WebSocket connection with authentication
2. Server sends session begins confirmation
3. Client streams audio data chunks
4. Server responds with transcription results
5. Either party can terminate the session

### Audio Streaming
- **Format**: PCM16 or Mu-law encoding
- **Channels**: Single-channel (mono)
- **Chunk Size**: 50ms recommended
- **Sample Rate**: Must match configuration parameter

### Error Handling
- Connection errors return appropriate HTTP status codes
- Authentication failures result in 401 Unauthorized
- Invalid parameters return 400 Bad Request
- Rate limiting may apply for high-volume usage

## Best Practices

### Connection Management
- Monitor connection stability
- Implement reconnection logic
- Handle WebSocket close events gracefully

### Audio Streaming
- Send consistent 50ms audio chunks
- Maintain stable sample rate
- Use appropriate encoding format

### Configuration
- Set appropriate confidence thresholds
- Configure silence detection parameters
- Enable turn formatting as needed