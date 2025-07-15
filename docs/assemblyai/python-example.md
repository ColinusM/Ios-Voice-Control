# AssemblyAI Streaming Python Example

## Complete Python Implementation

```python
import assemblyai as aai
import json
from urllib.parse import urlencode

# Set your API key
aai.settings.api_key = "YOUR_API_KEY"

# Event handler functions
def on_open(session_opened: aai.RealtimeSessionOpened):
    print("Session ID:", session_opened.session_id)

def on_data(transcript: aai.RealtimeTranscript):
    if not transcript.text:
        return
    
    if isinstance(transcript, aai.RealtimeFinalTranscript):
        print(transcript.text, end="\r\n")
    else:
        print(transcript.text, end="\r")

def on_error(error: aai.RealtimeError):
    print("An error occurred:", error)

def on_close():
    print("Closing Session")

# Configure the transcriber
transcriber = aai.RealtimeTranscriber(
    on_data=on_data,
    on_error=on_error,
    sample_rate=44_100,
    on_open=on_open,
    on_close=on_close
)

# Optional: Add custom vocabulary
word_boost = ["foo", "bar"]
params = {
    "sample_rate": 16000, 
    "word_boost": json.dumps(word_boost)
}
url = f"wss://api.assemblyai.com/v2/realtime/ws?{urlencode(params)}"

# Start the connection
transcriber.connect()

# Open microphone stream
microphone_stream = aai.extras.MicrophoneStream()

# Stream audio (press Ctrl+C to abort)
transcriber.stream(microphone_stream)

transcriber.close()
```

## Key Implementation Points

### Event Handlers
- `on_open`: Called when session is established
- `on_data`: Handles transcript data (partial and final)
- `on_error`: Handles connection and transcription errors
- `on_close`: Called when session is terminated

### Configuration Options
- `sample_rate`: Audio sample rate (16kHz or 44.1kHz)
- `word_boost`: Custom vocabulary for improved accuracy
- URL parameters for additional configuration

### Audio Streaming
- Uses `MicrophoneStream` for real-time audio input
- Handles both partial and final transcripts
- Supports continuous streaming until interrupted

### Dependencies
- Requires AssemblyAI SDK with extras: `pip install assemblyai[extras]`
- Microphone access for audio input
- WebSocket connection for real-time communication

### Best Practices
- Set appropriate sample rate for your audio source
- Handle both partial and final transcript types
- Implement proper error handling
- Use custom vocabulary for domain-specific terms