# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this iOS Voice Control app.

## Project Overview

This is an **iOS Voice Control App** with enterprise-grade Google Sign-In authentication. The app is designed for iPhone X (iOS 16+) compatibility and uses Firebase for backend services.

## 🤖 Technology Agents

**Available specialized agents in `claude_md_files_agents/` folder:**

- **Swift/iOS**: `CLAUDE-SWIFT-IOS-AGENT.md` - Scope error prevention, framework imports, type safety
- **React**: `CLAUDE-REACT.md` - Component patterns, type safety, testing  
- **Node.js**: `CLAUDE-NODE.md` - Server patterns, async/await, error handling

**To activate an agent, simply tell Claude:**
- "use Swift iOS agent"
- "use React agent" 
- "use Node agent"

**That's it.** No automatic detection - you control when to apply specific technology best practices.

## 🔥 MANDATORY: Use Physical iPhone Device Only

**CRITICAL RULE: NEVER use iOS Simulator for builds or testing. ALWAYS use Colin's physical iPhone device.**

For this iOS project, use the optimized CLI workflow that's 6x faster than default xcodebuild:

```bash
# REQUIRED: Fast build + install + launch to physical iPhone device
# (Network blocking hack applied for speed - blocks slow Apple provisioning servers)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14
```

**Why Physical Device Only:**
- Real-world testing conditions
- Actual performance metrics  
- Touch/gesture interaction testing
- Camera/sensor functionality
- Push notifications work properly
- Network conditions are realistic
- 6x faster than simulator builds

This command:
- Builds the iOS app (~10 seconds vs 67+ seconds default)  
- Installs to Colin's iPhone device (2b51e8a8e9ffe69c13296dd6673c5e0d47027e14)
- Launches the app automatically
- Shows console logs in terminal
- Uses optimized workflow with Apple server blocking for speed

### ❌ DO NOT USE THESE COMMANDS:
```bash
# NEVER USE SIMULATOR BUILDS:
xcodebuild -scheme VoiceControlApp -sdk iphonesimulator ...  # ❌ WRONG
xcodebuild -destination 'platform=iOS Simulator' ...        # ❌ WRONG
```

## iOS Log Capture Workflow

After deploying with the fast build command, capture device logs for debugging:

**Prerequisites:**
```bash
# Install libimobiledevice for device log access
brew install libimobiledevice
```

**Past Log Buffer Capture:**

When you say "grab logs", Claude retrieves recent logs from iOS device buffer - captures your past testing activity without needing live capture during testing.

```bash
# PAST LOGS ONLY (5s max) - Recent buffer, no live streaming
tail -200 /var/log/system.log | grep VoiceControlApp | head -30

# OAUTH/GOOGLE ERRORS - Past authentication issues  
tail -300 /var/log/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# APP CRASHES - Past error buffer
tail -100 /var/log/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

**CRITICAL: All log commands must complete within 5 seconds and only read past buffer logs - never live stream.**

**Buffer-Based Log Workflow:**
1. **Build & Deploy**: Claude launches app to iPhone
2. **Manual Testing**: You test freely - no logging interference 
3. **Request Logs**: Say "grab logs" to get recent buffer:
   - "grab logs" → MINIMAL (50 lines, app-only)
   - "grab verbose logs" → VERBOSE (200 lines, includes UIKit)
   - "grab error logs" → ERROR HUNTING (crashes only)
4. **Analysis**: Claude analyzes your past testing activity from iOS buffer
5. **Iterate**: Build → Test → Grab → Analyze → Repeat

## 🛑 MANDATORY: Universal Manual Action Stop Rule

**META RULE: When you discover that ANY task requires manual actions that Claude Code terminal cannot perform agentically, you MUST:**

1. **Stop implementation immediately** - Do not continue coding or create workarounds
2. **Clearly identify what manual action is needed** - Be specific about what the user must do
3. **Explain why Claude Code cannot complete this step agentically** - Cannot access GUI, web interfaces, IDE settings, etc.
4. **Provide exact instructions for the user** - Step-by-step guidance
5. **Wait for user confirmation** - Do not proceed until the user has completed the manual steps

### Pattern:
```
🛑 MANUAL ACTION REQUIRED

**[Task] cannot be completed without [specific manual action].**

What you need to do:
1. [Step 1]
2. [Step 2] 
3. [Step 3]

After completing these steps, I can help you:
- [Next automated steps]
```

**This rule applies to ANY manual action, including but not limited to:**
- Xcode project settings (URL schemes, capabilities, build settings)
- Package dependencies requiring GUI installation
- IDE-specific configurations
- External service configurations (Google Cloud, Firebase, etc.)
- System dependencies requiring admin access
- Development certificates or signing
- Database schemas requiring DBA approval
- Any GUI-based configuration that terminal tools cannot access

## Project Structure

```
VoiceControlApp/
├── VoiceControlAppApp.swift      # App entry point with Firebase config
├── ContentView.swift             # Main authentication UI and Google Sign-In logic
├── Info.plist                    # URL schemes for OAuth redirects
├── GoogleService-Info.plist      # Firebase/Google services configuration
└── Assets.xcassets              # App icons and images
```

## Key Files

- **ContentView.swift**: Contains all authentication logic, AuthenticationManager, and UI components
- **Info.plist**: Contains URL schemes for Google Sign-In OAuth redirects
- **GoogleService-Info.plist**: Firebase configuration with OAuth client IDs
- **VoiceControlAppApp.swift**: App initialization with Firebase and Google Sign-In setup

## Development Workflow

1. **Make changes** to Swift files
2. **Build and deploy** using the fast iOS deploy command
3. **Test manually** on the physical iPhone device
4. **Capture logs** when needed using idevicesyslog commands
5. **Iterate** quickly with the optimized build pipeline

## Anti-Patterns to Avoid

- ❌ **Don't use iOS Simulator** - Always use physical device
- ❌ **Don't create workarounds for OAuth/external service configuration** - Stop and request manual setup
- ❌ **Don't continue implementation when manual user actions are required** - Stop immediately and request user intervention
- ❌ **Don't hardcode OAuth credentials** - Use proper configuration files
- ❌ **Don't skip URL scheme configuration** - Required for OAuth redirects

## Google Cloud Console URLs

**OAuth Consent Screen (Test Users):**
```
https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
```

**Google Cloud Project Overview:**
```
https://console.cloud.google.com/home/dashboard?project=project-1020288809254
```

## 🎯 MANDATORY: Proactive Direct URL Rule

**When giving manual web navigation instructions (because Claude Code cannot access GUIs), ALWAYS proactively provide direct URLs first.**

**Auto-detect scenarios requiring manual web action and immediately provide direct URLs:**

- OAuth/Cloud console configuration → Provide direct console URLs
- IDE settings that require GUI → Provide direct documentation/settings URLs  
- External service setup → Provide direct service URLs
- Account/billing configuration → Provide direct account URLs

**Examples:**
- "You need to add test users in OAuth consent screen" → Immediately provide: `https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254`
- "Configure Firebase authentication" → Immediately provide: `https://console.firebase.google.com/project/PROJECT_ID/authentication`
- "Set up Apple Developer certificates" → Immediately provide: `https://developer.apple.com/account/resources/certificates/list`

**Pattern: Direct URL first, then step-by-step instructions.**

**Initiative rule: Don't wait for user to ask for URLs - proactively provide them when giving any manual web navigation instructions.**

Remember: When external service configuration is needed (Google Cloud, Firebase, etc.), **STOP** and request manual user action rather than creating workarounds.