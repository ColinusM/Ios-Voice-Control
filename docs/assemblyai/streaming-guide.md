# AssemblyAI Universal-Streaming Speech-to-Text Guide

## Core Concepts

### Turn Objects
Turn objects represent a speaking turn/utterance and include:
- **Unique ID**: Identifies the specific turn
- **Metadata**: Additional information about the turn
- **Transcript**: The transcribed text content
- **Confidence Scores**: Reliability metrics
- **Word-level Details**: Individual word timestamps and confidence

### Immutable Transcription
- **No Overwriting**: Transcriptions are never replaced
- **Incremental Building**: Each response builds on previous text
- **Real-time Updates**: Provides live, incremental transcription

## Technical Requirements

### Audio Format Specifications
- **Encoding**: PCM16 or Mu-law encoding
- **Channels**: Single-channel (mono)
- **Chunk Size**: 50ms audio chunks recommended
- **Sample Rate**: Must match the specified parameter

### Connection Parameters
- **Sample Rate**: Required audio sample rate
- **Encoding Type**: Audio encoding format
- **Turn Confidence Threshold**: Configurable detection sensitivity
- **Silence Detection**: Customizable silence handling

## Implementation Strategy

### Recommended Workflow
1. **Capture Partials**: Collect partial transcripts in real-time
2. **Detect Turn End**: Identify when speaker completes their turn
3. **Combine Transcripts**: Merge running transcript with latest partial
4. **Process Results**: Send completed transcript to language model
5. **Reset State**: Clear running transcript for next turn

### Sample Code Structure (Python)
```python
client = StreamingClient(
    StreamingClientOptions(
        api_key="<YOUR_API_KEY>",
        api_host="streaming.assemblyai.com"
    )
)

client.connect(StreamingParameters(
    sample_rate=16000,
    format_turns=True
))
```

## Authentication

### API Key Authentication
- **Primary Method**: Use API key in Authorization header
- **Temporary Tokens**: Available for client-side authentication
- **Security**: Keep API keys secure and rotate regularly

### Connection Options
- **Direct API Key**: Include in connection headers
- **Token-based**: Generate temporary tokens for client applications
- **Query Parameters**: Alternative authentication method

## Recommended Settings

### Optimal Configuration
- **Chunk Size**: 50ms for best performance
- **Transcript Format**: Unformatted for lowest latency
- **Confidence Threshold**: Adjust based on use case requirements
- **Silence Detection**: Configure appropriate timing parameters

### Performance Tuning
- **Sample Rate**: Match audio source capabilities
- **Buffer Size**: Optimize for your specific hardware
- **Confidence Levels**: Balance accuracy vs. responsiveness
- **Silence Timing**: Adjust for speaking patterns

## Use Cases

### Primary Applications
- **Voice Agents**: Conversational AI and chatbots
- **Live Captioning**: Real-time accessibility features
- **Real-time Transcription**: Meeting and event transcription
- **Interactive Voice**: Command and control systems

### Implementation Patterns
- **Streaming to LLM**: Direct integration with language models
- **Real-time Display**: Live transcript visualization
- **Turn-based Processing**: Segment-based analysis
- **Continuous Listening**: Always-on transcription

## Best Practices

### Connection Management
- Handle connection failures gracefully
- Implement reconnection logic
- Monitor connection health

### Audio Processing
- Maintain consistent chunk timing
- Handle audio format variations
- Implement proper buffering

### Error Handling
- Catch and handle network errors
- Implement retry mechanisms
- Log errors for debugging