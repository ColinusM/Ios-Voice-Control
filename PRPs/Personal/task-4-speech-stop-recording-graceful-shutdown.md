# Task 4: Speech Stop Recording Graceful Shutdown

## Problem
When pressing "stop recording" button, the app immediately terminates everything and loses the final formatted transcript that's still in transit from AssemblyAI servers.

## Root Cause
Current `stopStreaming()` method in `AssemblyAIStreamer.swift:236` immediately:
1. Stops audio recording
2. Sends session termination  
3. Disconnects WebSocket
4. Resets state

But AssemblyAI may still be processing and sending the final formatted transcript!

## Solution Strategy
Implement graceful shutdown that waits for final formatted transcript:

1. **Stop audio capture immediately** when button is pressed
2. **Keep WebSocket connection alive** 
3. **Wait for final transcript** with both conditions:
   - `end_of_turn: true`
   - `turn_is_formatted: true`
4. **Then do full cleanup** (disconnect, reset state)

## Key Insight
Even after pressing "stop recording", we can still receive the formatted transcript because it's already being processed by AssemblyAI servers. We just need to wait for it before closing the connection.

## Current Code Location
- `AssemblyAIStreamer.swift:236` - Already correctly filtering for formatted final transcripts
- Need to modify `stopStreaming()` method to implement graceful shutdown pattern