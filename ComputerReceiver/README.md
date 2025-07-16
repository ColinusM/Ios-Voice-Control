# WiFi Text Receiver for iOS Voice Control

Computer receivers for testing the iOS Voice Control app's WiFi text transmission feature.

## 📁 Files in this folder:

### **🎯 For iPhone Testing (Use This One):**
- **`udp_receiver.py`** - Main receiver for iOS app messages
- **`test_receiver.py`** - Test script to verify receiver works

### **🎨 Alternative Options:**
- **`gui_receiver.py`** - Visual interface with buttons/windows
- **`tcp_yamaha_receiver.py`** - Professional Yamaha mixing console receiver

## 🚀 Quick Start

1. **Start the main receiver:**
   ```bash
   cd ComputerReceiver
   python3 udp_receiver.py
   ```
   You'll see: "Waiting for connections..."

2. **Test it works:**
   ```bash
   # In another terminal
   python3 test_receiver.py
   ```
   You should see messages appear in the receiver terminal.

3. **Use with iOS app:**
   - Connect iPhone and Mac to same WiFi (or use iPhone hotspot)
   - Build and run iOS Voice Control app
   - Speak into microphone: "Set channel 1 to unity gain"
   - Press send button in iOS app
   - See message appear in receiver terminal with RCP conversion

## 📱 iPhone Hotspot Setup

1. **iPhone**: Settings → Personal Hotspot → Turn On
2. **Mac**: Connect to iPhone's hotspot WiFi  
3. **iOS app** sends to Mac (usually at 172.20.10.1)
4. **Receiver** shows messages in terminal

## 🎛️ Usage Options

```bash
# Default (port 8080, all interfaces)
python3 udp_receiver.py

# Custom port
python3 udp_receiver.py --port 9090

# Yamaha RCP mode (port 49280)
python3 udp_receiver.py --port 49280

# GUI version (visual interface)
python3 gui_receiver.py

# Professional TCP version
python3 tcp_yamaha_receiver.py
```

## Message Format

The receiver handles both JSON and plain text messages:

**JSON Format (from iOS app):**
```json
{
  "id": "uuid",
  "content": "Set channel 1 to unity gain",
  "timestamp": "2024-01-01T12:00:00Z",
  "messageType": "plainText",
  "metadata": {"source": "voice_recognition"}
}
```

**Plain Text:**
```
Hello from iOS app
```

## RCP Command Detection

The receiver automatically detects potential Yamaha RCP commands and suggests conversions:

- Input: "Set channel 1 to unity gain"
- Detection: 🎵 Potential RCP command detected!
- Suggestion: `set MIXER:Current/InCh/Fader/Level [CH] 0 0`

## Network Requirements

- **Same WiFi Network**: iOS device and Mac must be on the same network
- **Firewall**: Mac firewall should allow incoming connections on the chosen port
- **iOS Permissions**: iOS app will request local network permission on first send

## Troubleshooting

**Port already in use:**
```bash
python3 udp_receiver.py --port 9090
```

**No messages received:**
1. Check both devices are on same WiFi
2. Check Mac firewall settings
3. Verify iOS app has local network permission
4. Try different port

**Permission denied on Mac:**
```bash
sudo python3 udp_receiver.py --port 80  # For privileged ports
```

## Integration with Yamaha RCP

Future versions will support full RCP command translation and forwarding to Yamaha mixing consoles on port 49280.