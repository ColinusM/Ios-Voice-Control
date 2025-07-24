# Voice Command Tester

A professional-grade, modular testing environment for Yamaha RCP voice commands. This tool helps validate voice command patterns with comprehensive audio engineering terminology before implementing them in the iOS Voice Control app.

## 🎯 Purpose

Test and validate voice commands that convert natural language to Yamaha RCP protocol commands, supporting 500+ professional audio variations and engineered for commercial-grade applications.

## 📦 Modular Architecture (Professional-Grade)

### Core Engine Components
- **`engine.py`** - Main coordinator class integrating all processors (330 lines)
- **`terms.py`** - Professional audio terminology database (170 lines)
- **`channels.py`** - Channel fader, mute, and labeling operations (398 lines) 
- **`routing.py`** - Send, pan, and matrix routing operations (361 lines)
- **`effects.py`** - Reverb, delay, compression, and EQ processing (297 lines)

### Web Interface & Testing
- **`server.py`** - Flask server with comprehensive API endpoints (103 lines)
- **`gui.html`** - Professional web interface for command testing
- **`tests.py`** - Automated test suite for validation
- **`requirements.txt`** - Python dependencies

### Legacy & Documentation
- **`engine_v1.py`** - Original monolithic engine (kept for reference)
- **`commands.md`** - Command documentation and examples

## 🚀 Quick Start

1. **Install dependencies:**
   ```bash
   cd voice-command-tester
   pip install -r requirements.txt
   ```

2. **Run tests first:**
   ```bash
   python tests.py
   ```

3. **Start the server:**
   ```bash
   python server.py
   ```

4. **Open browser:**
   ```
   http://localhost:5000
   ```

### 🛠️ Development Commands

```bash
# Test individual modules
python -c "from engine import VoiceCommandEngine; print('✅ Engine working')"
python -c "from terms import ProfessionalAudioTerms; print('✅ Terms working')"
python -c "from channels import ChannelProcessor; print('✅ Channels working')"

# Test comprehensive functionality
python -c "
from engine import VoiceCommandEngine
engine = VoiceCommandEngine()
result = engine.process_command('set channel 1 to unity')
print(f'✅ {len(result)} RCP commands generated')
"
```

## 🧪 Testing Examples

Try these commands in the GUI:

- `Set channel 1 to unity` → `set MIXER:Current/InCh/Fader/Level 0 0 0`
- `Mute channel 3` → `set MIXER:Current/InCh/Fader/On 2 0 0`
- `Send channel 5 to mix 2 at minus 6 dB` → `set MIXER:Current/InCh/ToMix/Level 4 1 -600`
- `Pan channel 8 hard left` → `set MIXER:Current/InCh/ToSt/Pan 7 0 -63`
- `Recall scene 15` → `ssrecall_ex scene_15`

## 🎛️ Professional Audio Commands (500+ Variations)

### Channel Control (Professional Terminology)
- **Fader levels**: "Set channel X to Y dB", "Bring up channel X", "Pull down channel X", "Crank channel X", "Bury channel X"
- **Muting**: "Mute channel X", "Kill channel X", "Cut channel X", "Solo channel X", "Unmute channel X"
- **Labeling**: "Name channel X [label]", "Label channel X as [instrument]"
- **Professional slang**: "Push the fader", "Ride the vocal", "Trim the input"

### Advanced Routing (IEM, Monitor, Matrix)
- **Send to mix**: "Send channel X to mix Y", "Route channel X to aux Y", "Patch channel X into wedge Y"
- **IEM routing**: "Send vocals to IEM mix 1", "Route guitar to in-ears"
- **Monitor sends**: "Add kick to drummer's mix", "Give vocals to singer's wedge"
- **Matrix routing**: "Send mix 1 to matrix 3", "Route aux 2 to matrix out"
- **Pre/post fader**: "Send channel X pre-fader to mix Y", "Post-fader send to monitors"

### Professional Panning
- **Stereo positioning**: "Pan channel X left", "Hard left on vocals", "Center the kick", "Spread the overheads"
- **Pan positions**: Left, right, center, hard left, hard right, slight left, slight right

### Effects Processing (Studio-Grade)
- **Reverb**: "Add reverb to vocals", "Hall reverb on strings", "Plate reverb", "Room reverb"
- **Delay**: "Slapback delay on vocals", "Echo on guitar", "Delay throw"
- **Compression**: "Compress the vocals", "Squash the bass", "Limit the drums", "Gate the snare"
- **EQ**: "Boost the highs on vocals", "Cut the bass on kick", "High-pass filter guitars"

### Dynamics Processing
- **Gates**: "Gate the kick", "Noise gate on toms"
- **Compressor parameters**: "Set compression ratio to 4:1 on vocals", "Fast attack on drums"
- **Limiting**: "Brick wall limit the mix", "Peak limit the vocals"

### Scene Management
- **Scene recall**: "Recall scene X", "Load scene X", "Go to scene X", "Scene change X"

### DCA Groups
- **DCA faders**: "Set DCA X to Y dB", "Bring up DCA group X"
- **DCA muting**: "Mute DCA X", "Kill the drums DCA"

### Context-Aware Commands (After Channel Labeling)
- **Instrument control**: "Turn up the vocals", "Mute the drums", "Boost the bass"
- **Professional workflow**: "More vocal in the wedges", "Less guitar in IEMs"

## 🔧 Professional-Grade Engine Features

### Core Processing
- **Advanced number parsing**: Handles digits ("5"), words ("five"), and professional ranges
- **Professional dB conversion**: Converts human values to RCP format with validation
- **Comprehensive pan mapping**: Maps positions to RCP values (-63 to +63) with professional terminology
- **Context awareness**: Uses channel labels for natural instrument-based commands
- **Security hardening**: Input validation, bounds checking, and sanitization

### Professional Audio Intelligence
- **Instrument recognition**: 50+ instrument aliases (vocals, vox, kick, bd, snare, sd, etc.)
- **Professional terminology**: 200+ audio engineering terms and slang
- **Multi-language support**: US/UK terminology (foldback vs monitors, etc.)
- **Professional workflows**: IEM, wedge, matrix, and advanced routing patterns

### Modular Architecture
- **Separation of concerns**: Channel, routing, effects, and terminology processors
- **Scalable design**: Easy to add new command patterns and audio terminology
- **Error isolation**: Module-level error handling prevents system crashes
- **Memory efficient**: Optimized for production deployment

## 📊 Professional Test Coverage

The test suite validates:
- **500+ voice command variations** across all modules
- **Professional terminology accuracy** for audio engineering workflows
- **Edge cases and error conditions** with security validation
- **Context-aware functionality** for instrument-based commands
- **Multi-module integration** ensuring seamless operation
- **Performance benchmarking** for real-time audio applications

## 🔄 Commercial Integration Workflow

Once commands are validated in this professional testing environment:

### Phase 1: Voice Command Validation
1. **Test professional variations** using the modular engine
2. **Validate audio engineering terminology** across all processors
3. **Performance benchmark** for real-time applications
4. **Security audit** input validation and bounds checking

### Phase 2: iOS Voice Control App Integration
1. **Copy validated patterns** from modular processors to iOS app
2. **Integrate with AssemblyAI** real-time speech recognition
3. **Implement Yamaha RCP** TCP communication layer
4. **Deploy to SwiftUI interface** with MVVM architecture
5. **Test on iPhone 16 iOS 18.5 simulator** (required platform)

### Phase 3: Production Deployment
1. **Professional audio testing** with real mixing consoles
2. **Live venue validation** for commercial applications
3. **Performance optimization** for studio environments

## 🎙️ Commercial Applications

This professional-grade system supports:

### **VoiceConsole** / **AudioPilot** / **VoicePilot** Commercial App
- **Real-time mixer control** via natural language
- **Professional audio workflows** for engineers and artists
- **Multi-console support** (Yamaha RCP protocol)
- **Studio-grade reliability** with comprehensive error handling

### Professional Use Cases
- **Live sound reinforcement** - FOH and monitor engineers
- **Recording studios** - Console automation during sessions
- **Broadcast facilities** - Hands-free mixing operations
- **Houses of worship** - Volunteer-friendly audio control
- **Corporate events** - Simplified technical operations

## 🏗️ Technical Architecture

### Backend Infrastructure
- **Modular Python engine** (5 specialized processors)
- **Professional terminology database** (500+ variations)
- **Security-hardened validation** with bounds checking
- **RESTful API endpoints** for real-time processing

### iOS Voice Control App Context
- **Target Platform**: iPhone 16 iOS 18.5 simulator (Device ID: 5B1989A0-1EC8-4187-8A99-466B20CB58F2)
- **Architecture**: MVVM with SwiftUI for professional UI
- **Speech Recognition**: AssemblyAI real-time streaming API
- **Authentication**: Firebase Authentication for user management
- **Development**: Hot reloading with Xcode 15.0+ for rapid iteration
- **Protocol**: Yamaha RCP over TCP for mixer communication

### Development Resources
- **Complete setup guide**: See `ONBOARDING.md` in project root
- **Professional workflows**: Documented in `/docs/` folder
- **Security guidelines**: See `security.md` for production deployment

## 🔧 Troubleshooting & Debug Guide

### **Common Issues and Solutions**

#### **"Send to Receiver" Button Issues**

**Problem**: "Successfully sent X RCP commands to receiver!" popup appears but no messages in ComputerReceiver GUI.

**Root Cause**: GUI receiver's UDP server not actually listening despite showing "Server started on port 8080".

**Solution Steps**:
1. **Check Mode Setting**: Ensure GUI receiver shows "Development (UDP 8080)" not just "Development"
2. **Verify UDP Server**: Test with: `netstat -an | grep 8080` - should show listening port
3. **Restart GUI Receiver**: Close and restart if mode was incorrect
4. **Test Direct UDP**: Use debug command to test receiver directly:
   ```python
   import socket, json
   sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   test_msg = {"content": "test", "rcpCommands": [{"command": "test", "description": "test"}]}
   sock.sendto(json.dumps(test_msg).encode(), ('127.0.0.1', 8080))
   ```

#### **Server Communication Flow**

**Working End-to-End Flow**:
1. **Browser** (localhost:5001) → Process command → Generate RCP → Click "Send to Receiver"
2. **Flask Server** → Receives send request → Creates UDP packet → Sends to port 8080
3. **ComputerReceiver GUI** → UDP server listening on 8080 → Displays voice command + RCP commands

**Debug Commands**:
```bash
# Test voice command tester server
curl http://localhost:5001/test

# Test direct receiver communication
curl -X POST http://localhost:5001/send_to_receiver -H "Content-Type: application/json" -d '{"content":"test","rcpCommands":[{"command":"test","description":"test"}]}'

# Check if receiver is listening
lsof -i :8080  # Should show Python process
```

#### **Professional Audio Terminology**

**Recently Added**: Support for "track" and "bus" terminology
- ✅ `"send track 1 to bus seven"` → `set MIXER:Current/InCh/ToMix/On 0 6 1`
- ✅ Word numbers (seven, eight, five) supported
- ✅ Professional abbreviations (trk, tr) supported

**Server Restart Required**: When modifying routing.py, channels.py, effects.py, or terms.py, restart the voice command server:
```bash
pkill -f "python.*server" && python server.py
```

#### **GUI Receiver Stability**

**Crash Prevention**: GUI receiver now runs in separate Terminal process for stability
**Port Conflicts**: Uses port 5001 for voice tester (not 5000) to avoid macOS AirPlay conflicts
**Message Format**: Receiver expects JSON with `rcpCommands` array containing pre-generated RCP commands

---

## 🚀 Ready for Commercial Deployment

This professional-grade voice command system is engineered for commercial audio applications with comprehensive terminology support, security hardening, and modular architecture designed for production environments.

**✅ Verified Working**: End-to-end voice command → RCP generation → UDP transmission → GUI display pipeline fully operational.