name: "iOS Voice Control Specialized Agents - Orchestrator + Debugger Architecture"
description: |
  Implement sophisticated agent architecture adapted from Sib2Ae music project to iOS Voice Control app development. 
  Creates symbiotic orchestrator + debugger agents with shared knowledge accumulation for iOS-specific workflows.

## Goal

Implement specialized Claude Code sub-agents for iOS Voice Control app development that provide:
- **ios-voice-orchestrator**: Primary development agent with success criteria enforcement and progressive thinking
- **ios-voice-debugger**: Specialized debugging agent with continuous learning and pattern accumulation
- **Shared knowledge base**: Centralized accumulation of iOS debugging solutions and anti-patterns
- **Complete integration** with existing project patterns (MVVM, Firebase Auth, AssemblyAI, SwiftUI)

## Why

- **Reduce debugging cycles**: Accumulated knowledge prevents repeating solved problems
- **Enforce quality standards**: Orchestrator demands measurable success criteria before proceeding
- **Continuous learning**: Each debug session improves future development efficiency
- **iOS-specific expertise**: Agents understand Firebase Auth, AssemblyAI streaming, SwiftUI state management
- **Project consistency**: Agents follow established MVVM patterns and architectural conventions

## What

Specialized agent system that transforms iOS development workflow:

### User-Visible Behavior
- Ask for "authentication flow debugging" → `ios-voice-debugger` automatically invoked
- Request "implement speech feature" → `ios-voice-orchestrator` demands clear success criteria
- Development knowledge accumulates in `/docs/ios-debug-knowledge.md` for team learning
- Consistent build patterns using iPhone 16 iOS 18.5 simulator only

### Technical Requirements
- **Agent Files**: `.claude/agents/ios-voice-orchestrator.md` and `.claude/agents/ios-voice-debugger.md`
- **Knowledge Base**: `/docs/ios-debug-knowledge.md` with auto-update patterns
- **Validation Gates**: 5-level autonomous validation (build → test → integration → security → deployment)
- **Project Integration**: Works with existing CLAUDE.md patterns and conventions

### Success Criteria

- [ ] Orchestrator agent successfully implements new iOS features with enforced success criteria
- [ ] Debugger agent resolves iOS build/auth/speech issues and updates knowledge base
- [ ] Knowledge base accumulates ≥10 documented patterns after initial deployment
- [ ] Agents follow existing project patterns (MVVM, dependency injection, error handling)
- [ ] Complete validation pipeline passes with 100% success rate
- [ ] Integration with existing iPhone 16 iOS 18.5 simulator workflow

## All Needed Context

### Documentation & References

```yaml
# MUST READ - iOS Voice Control App Context
- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/CLAUDE.md
  why: Established iOS development patterns, simulator requirements, validation commands
  critical: iPhone 16 iOS 18.5 simulator mandatory, buffer-based logging only

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift
  why: MVVM pattern reference, ObservableObject implementation, error handling
  critical: @Published properties, @MainActor enforcement, dependency injection

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/Authentication/Models/AuthenticationError.swift
  why: Comprehensive error modeling with 21 error types and recovery suggestions
  critical: Pattern for user-friendly error messages and failure reasons

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift
  why: WebSocket streaming patterns, real-time processing, usage tracking
  critical: Connection state management, error handling, subscription gating

# Agent Architecture References
- file: /Users/colinmignot/Claude Code/Sib2Ae/PRPs-agentic-eng/.claude/agents/music-sync-orchestrator.md
  why: Primary orchestrator pattern with success criteria enforcement
  critical: Demands measurable outcomes, progressive thinking, knowledge-informed development

- file: /Users/colinmignot/Claude Code/Sib2Ae/PRPs-agentic-eng/.claude/agents/music-debug-learner.md
  why: Debug specialist pattern with continuous learning and auto-commit
  critical: Validation gate protocol, knowledge update rules, success criteria validation

- file: /Users/colinmignot/Claude Code/Sib2Ae/PRPs-agentic-eng/docs/music-debug-knowledge.md
  why: Knowledge base structure with success/failure documentation
  critical: Template for iOS debug knowledge accumulation

# iOS Development Best Practices
- url: https://www.xcodebuildmcp.com/
  why: XcodeBuildMCP integration for enhanced iOS development in Claude Code
  critical: Autonomous build validation, simulator control, project management

- url: https://docs.anthropic.com/en/docs/claude-code/sub-agents
  why: Official Claude Code sub-agent configuration and best practices
  critical: YAML frontmatter configuration, tool access control, invocation patterns
```

### Current Codebase Structure

```bash
VoiceControlApp/
├── Authentication/
│   ├── ViewModels/AuthenticationManager.swift    # Central auth state (286 lines)
│   ├── Services/                                 # Firebase, Google, Biometric services  
│   ├── Models/AuthenticationError.swift          # 21 error types with recovery
│   └── Views/                                    # Auth UI components
├── SpeechRecognition/
│   ├── AssemblyAIStreamer.swift                  # WebSocket streaming (557 lines)
│   ├── SpeechRecognitionManager.swift            # Engine coordination
│   └── Models/                                   # Transcription models
├── Subscriptions/
│   ├── ViewModels/SubscriptionManager.swift      # Premium feature gating
│   └── Services/StoreKitService.swift            # StoreKit integration
├── VoiceCommand/
│   ├── Learning/LearningPromptManager.swift      # ML-based learning
│   └── Processing/                               # Voice command processing
└── Shared/
    ├── Components/                               # Reusable SwiftUI components
    ├── Extensions/                               # Swift extensions
    └── Services/                                 # Common services

# Current Agent Infrastructure
.claude/                                          # Missing - needs creation
CLAUDE.md                                         # Existing iOS patterns
claude_md_files/CLAUDE-SWIFT-IOS-AGENT.md       # Referenced but missing
```

### Desired Agent Architecture Structure

```bash
.claude/
├── agents/
│   ├── ios-voice-orchestrator.md               # Primary development agent
│   └── ios-voice-debugger.md                   # Debug specialist agent
docs/
├── ios-debug-knowledge.md                      # Shared knowledge base
└── claude-code-ios-integration.md              # Integration documentation

# Enhanced Agent Support Files
claude_md_files/
├── CLAUDE-SWIFT-IOS-AGENT.md                   # iOS-specific patterns (create)
└── ios-voice-control-patterns.md               # Project-specific patterns

# Validation Infrastructure  
scripts/
├── ios-validation-pipeline.sh                  # 5-level autonomous validation
└── agent-knowledge-validator.py                # Knowledge base validation
```

### Known iOS Gotchas & Library Quirks

```swift
// CRITICAL: iPhone 16 iOS 18.5 Simulator Only
// Reason: Firebase Auth compatibility, no iOS 26 crashes (FBSceneErrorDomain)
let simulatorID = "5B1989A0-1EC8-4187-8A99-466B20CB58F2"

// CRITICAL: Every new Swift file MUST be added to Xcode project before building
// Pattern established in CLAUDE.md - use pbxproj automation
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && python3 -c "
import pbxproj
project = pbxproj.XcodeProject.load('VoiceControlApp.xcodeproj/project.pbxproj')
project.add_file('VoiceControlApp/Path/To/NewFile.swift', target_name='VoiceControlApp')
project.save()
"

// CRITICAL: Buffer-based log capture only (5 second max)
// NEVER use live streaming - causes blocking in Claude Code environment
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30

// CRITICAL: Firebase Auth bypassed in simulator (intentional)
// Auto-login with test credentials: colin.mignot1@gmail.com
// Pattern in AuthenticationManager.swift:464

// CRITICAL: AssemblyAI v3 API WebSocket session termination
// Must call stopStreaming() immediately on session_terminated message
// Pattern in AssemblyAIStreamer.swift:557

// CRITICAL: SwiftUI @Published properties require @MainActor
@MainActor
private func handleAuthStateChange(_ firebaseUser: FirebaseAuth.User?) {
    // Thread-safe state updates required
}

// CRITICAL: ObservableObject coordination pattern
// Weak references prevent retain cycles in ViewModels
private weak var subscriptionManager: SubscriptionManager?
private weak var authManager: AuthenticationManager?
```

## Implementation Blueprint

### Agent Configuration Files

Create iOS-specific sub-agents following established patterns from music project.

```markdown
# ios-voice-orchestrator.md structure:
- MVVM architecture enforcement
- Success criteria validation (be disagreeable with vague requirements)
- Progressive thinking (think/think harder/ultrathink)
- Knowledge-informed development (read ios-debug-knowledge.md first)
- iOS-specific patterns (authentication, speech, networking)

# ios-voice-debugger.md structure:
- Firebase Auth debugging patterns
- AssemblyAI WebSocket troubleshooting  
- SwiftUI state management issues
- Xcode project configuration problems
- Auto-commit after successful debugging
- Knowledge base updates after validation
```

### Shared Knowledge Base Structure

```markdown
# /docs/ios-debug-knowledge.md categories:
## Authentication Patterns
- ✅ Successes: Firebase Auth + Google Sign-In, biometric flow
- ❌ Failures: iOS 26 crashes → iPhone 16 iOS 18.5 solution

## Speech Recognition Patterns
- ✅ Successes: AssemblyAI WebSocket v3 implementation
- ❌ Failures: Connection drops → reconnection logic

## SwiftUI State Management
- ✅ Successes: Observable pattern coordination
- ❌ Failures: Race conditions → @MainActor enforcement

## Build System Patterns  
- ✅ Successes: Automated file addition to Xcode project
- ❌ Failures: Missing build targets → pbxproj automation

## Network Integration
- ✅ Successes: RCP command transmission
- ❌ Failures: Timeout handling → graceful degradation
```

### List of Tasks (Implementation Order)

```yaml
Task 1: Create Agent Infrastructure
CREATE .claude/agents/ directory:
  - MKDIR .claude/agents in project root
  - VERIFY directory creation with ls -la .claude/

Task 2: Implement ios-voice-orchestrator.md  
CREATE .claude/agents/ios-voice-orchestrator.md:
  - MIRROR pattern from: music-sync-orchestrator.md
  - ADAPT iOS development workflows (auth, speech, networking)
  - ENFORCE success criteria validation ("be disagreeable")
  - IMPLEMENT progressive thinking (think/think harder/ultrathink)
  - INTEGRATE with existing MVVM patterns

Task 3: Implement ios-voice-debugger.md
CREATE .claude/agents/ios-voice-debugger.md:
  - MIRROR pattern from: music-debug-learner.md
  - SPECIALIZE for iOS debugging scenarios
  - IMPLEMENT knowledge update protocol
  - ADD auto-commit after successful debugging
  - FOCUS on Firebase Auth, AssemblyAI, SwiftUI state issues

Task 4: Create Shared Knowledge Base
CREATE docs/ios-debug-knowledge.md:
  - MIRROR structure from: music-debug-knowledge.md
  - INITIALIZE with current project patterns
  - CATEGORIZE by iOS domain (auth, speech, UI, build, network)
  - DOCUMENT existing success patterns from codebase
  - PREPARE for continuous learning updates

Task 5: Create iOS Validation Pipeline
CREATE scripts/ios-validation-pipeline.sh:
  - IMPLEMENT 5-level autonomous validation
  - INTEGRATE with iPhone 16 iOS 18.5 simulator requirements
  - ADD xcodebuild, unit tests, UI tests, security analysis
  - INCLUDE buffer-based log capture and analysis
  - PROVIDE measurable success/failure criteria

Task 6: Enhance CLAUDE-SWIFT-IOS-AGENT.md
CREATE claude_md_files/CLAUDE-SWIFT-IOS-AGENT.md:
  - REFERENCE existing in CLAUDE.md but missing
  - DOCUMENT iOS-specific development patterns
  - INCLUDE scope error prevention, framework imports
  - ADD type safety and architectural guidelines
  - INTEGRATE with agent system for consistency

Task 7: Integration Testing
TEST agent system integration:
  - VERIFY orchestrator demands success criteria
  - VALIDATE debugger updates knowledge base
  - CONFIRM shared knowledge flow between agents
  - TEST complete development → debug → learn cycle
  - MEASURE agent effectiveness metrics

Task 8: Documentation and Team Onboarding
CREATE docs/claude-code-ios-integration.md:
  - DOCUMENT agent usage patterns
  - PROVIDE team onboarding guide
  - INCLUDE troubleshooting common issues
  - ADD metrics tracking for agent effectiveness
  - INTEGRATE with existing project documentation
```

### Per Task Pseudocode

```markdown
# Task 2: ios-voice-orchestrator.md Implementation
---
name: ios-voice-orchestrator
description: PROACTIVELY implements iOS Voice Control features with enforced success criteria and knowledge-informed development
tools: [Read, Write, Edit, Grep, Bash, MultiEdit, Glob, Task]
---

# iOS Voice Control Development Orchestrator

## Pre-Implementation Protocol
ALWAYS START BY:
1. Reading `/docs/ios-debug-knowledge.md` for accumulated patterns
2. DEMANDING CLEAR SUCCESS CRITERIA - be disagreeable with vague requirements
3. Applying documented solutions, avoiding documented failures
4. Building on proven MVVM patterns from codebase

## Success Criteria Validation (Be Disagreeable)
If user says: "Implement authentication feature"
Agent responds: "Success criteria unclear. Define exactly:
- Which auth flows? (Firebase email, Google OAuth, biometric?)  
- What should happen on success? (Navigate where? Store what?)
- Error handling requirements? (Retry attempts? User messaging?)
- Performance expectations? (Login time? Offline behavior?)
- Testing validation? (Unit tests? UI tests? Coverage threshold?)"

## Progressive Thinking Implementation
- "think" - Standard iOS development tasks (UI components, simple services)
- "think harder" - Complex state management, multi-service integration
- "ultrathink" - Architecture decisions, performance optimization, security

## iOS-Specific Responsibilities
### Authentication System
- Firebase Auth + Google Sign-In integration
- Biometric authentication (Face ID/Touch ID)
- Guest mode with usage tracking
- Token refresh and session management

### Speech Recognition System  
- AssemblyAI WebSocket streaming
- Audio permission management
- Real-time transcription with word-level accuracy
- Usage tracking and subscription gating

### UI State Management
- SwiftUI ObservableObject patterns
- @Published property coordination
- Navigation state management
- Error state presentation

# Task 3: ios-voice-debugger.md Implementation  
---
name: ios-voice-debugger
description: MUST BE USED for iOS Voice Control debugging failures. Specializes in Firebase Auth, AssemblyAI, SwiftUI state issues.
tools: [Read, Write, Edit, Grep, Bash]
---

# iOS Voice Control Debug Specialist

## Trigger Conditions (When MUST Be Called)
1. Firebase Authentication errors or token refresh failures
2. AssemblyAI WebSocket connection drops or streaming issues
3. SwiftUI state management race conditions or binding failures
4. Xcode build failures or project configuration issues
5. iOS simulator deployment or testing problems

## Validation Gate Protocol
SUCCESS CONDITION: Issue resolved with measurable validation
KNOWLEDGE UPDATE TRIGGER: Only after successful resolution

## iOS-Specific Debug Areas
### Firebase Authentication Debugging
- Token refresh failures and race conditions
- Google Sign-In integration issues
- Biometric authentication state problems
- Keychain persistence edge cases

### AssemblyAI Streaming Debugging
- WebSocket connection drops and reconnection logic
- Audio permission and AVAudioEngine conflicts
- Real-time transcription accuracy issues
- Usage tracking and subscription gate failures

### SwiftUI State Management Debugging
- @Published property race conditions
- ObservableObject coordination issues
- Navigation state inconsistencies
- Memory leaks in observable patterns

### Build System Debugging
- Missing Swift files in Xcode project targets
- Package dependency resolution failures
- Simulator targeting inconsistencies
- Code signing and provisioning issues

## Auto-Commit Protocol
When user-defined success criteria validated:
git add .
git commit -m "✅ iOS Debug success: [issue] - [criteria_met]"

## Knowledge Base Update Rules
After successful resolution:
1. Document WORKING solution with exact steps
2. Document ALL failed approaches and why they failed
3. Update `/docs/ios-debug-knowledge.md` with new patterns
4. Record debugging path from failure to success
```

### Integration Points

```yaml
EXISTING_CLAUDE_MD:
  - integrate: "iPhone 16 iOS 18.5 simulator mandatory patterns"
  - preserve: "Buffer-based log capture commands (5s max)"
  - enhance: "Swift file addition automation with pbxproj"

AGENT_COORDINATION:
  - orchestrator_reads: "/docs/ios-debug-knowledge.md before development"
  - debugger_updates: "/docs/ios-debug-knowledge.md after successful fixes"
  - shared_knowledge: "Both agents learn from accumulated patterns"

VALIDATION_INTEGRATION:
  - level1: "xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp build"
  - level2: "xcodebuild test with iPhone 16 iOS 18.5 destination"
  - level3: "xcrun simctl launch and log analysis"
  - level4: "Security analysis and performance validation"
  - level5: "App Store preparation and deployment readiness"

PROJECT_PATTERNS:
  - mvvm: "Follow AuthenticationManager.swift ObservableObject patterns"
  - errors: "Use AuthenticationError.swift enum modeling approach"
  - services: "Mirror FirebaseAuthService.swift dependency injection"
  - testing: "Extend AuthenticationManagerTests.swift patterns"
```

## Validation Loop

### Level 1: Agent Configuration Validation

```bash
# Verify agent files exist and are properly configured
ls -la .claude/agents/
cat .claude/agents/ios-voice-orchestrator.md | head -10
cat .claude/agents/ios-voice-debugger.md | head -10

# Expected: Both files exist with proper YAML frontmatter
# Validation: YAML parseable, required fields present
```

### Level 2: iOS Build System Integration

```bash
# Test agent integration with existing iOS build patterns
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"

# Clean build with agents available
xcodebuild clean -project VoiceControlApp.xcodeproj -scheme VoiceControlApp
xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Launch on simulator to verify no regressions
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Expected: Build succeeds, app launches without crashes
# Validation: BUILD SUCCEEDED in output, no critical errors in logs
```

### Level 3: Agent Functionality Testing

```bash
# Test orchestrator success criteria enforcement
# Claude command: "Implement new auth feature"
# Expected: Agent demands specific success criteria before proceeding

# Test debugger knowledge accumulation  
# Claude command: "Debug Firebase Auth token refresh failure"
# Expected: Agent updates ios-debug-knowledge.md after resolution

# Test shared knowledge flow
# Expected: Orchestrator reads debugger's accumulated knowledge
```

### Level 4: Knowledge Base Validation

```python
# CREATE scripts/agent-knowledge-validator.py
import re
import json
from pathlib import Path

def validate_knowledge_base():
    """Validate ios-debug-knowledge.md follows expected structure"""
    kb_path = Path("docs/ios-debug-knowledge.md")
    
    if not kb_path.exists():
        return {"status": "fail", "error": "Knowledge base file missing"}
    
    content = kb_path.read_text()
    
    # Validate required sections
    required_sections = [
        "Authentication Patterns",
        "Speech Recognition Patterns", 
        "SwiftUI State Management",
        "Build System Patterns",
        "Network Integration"
    ]
    
    missing_sections = [s for s in required_sections if s not in content]
    if missing_sections:
        return {"status": "fail", "error": f"Missing sections: {missing_sections}"}
    
    # Count documented patterns
    success_patterns = len(re.findall(r'✅ SUCCESS:', content))
    failure_patterns = len(re.findall(r'❌ FAILURE:', content))
    
    return {
        "status": "pass",
        "success_patterns": success_patterns,
        "failure_patterns": failure_patterns,
        "total_patterns": success_patterns + failure_patterns
    }

if __name__ == "__main__":
    result = validate_knowledge_base()
    print(json.dumps(result, indent=2))
```

```bash
# Run knowledge base validation
python3 scripts/agent-knowledge-validator.py

# Expected: {"status": "pass", "total_patterns": >= 5}
# Validation: Knowledge base properly structured with documented patterns
```

### Level 5: End-to-End Agent Workflow

```bash
# Complete agent workflow test
# 1. Orchestrator implements feature with success criteria
# 2. Encounter debugging scenario
# 3. Debugger resolves issue and updates knowledge
# 4. Orchestrator uses updated knowledge for next feature
# 5. Measure cycle effectiveness

# Metrics to track:
# - Time from problem identification to resolution
# - Knowledge base growth (patterns per week)
# - Debug issue recurrence rate (should decrease)
# - Agent usage adoption by team members
```

## Final Validation Checklist

- [ ] Agent configuration files properly formatted: `cat .claude/agents/*.md`
- [ ] iOS build system integration: `xcodebuild build succeeds`
- [ ] App launches on simulator: `xcrun simctl launch success`
- [ ] Knowledge base validation: `python3 scripts/agent-knowledge-validator.py`
- [ ] Orchestrator enforces success criteria: Manual verification
- [ ] Debugger updates knowledge base: Manual verification  
- [ ] Agents coordinate through shared knowledge: Manual verification
- [ ] No regressions in existing development workflow: Manual verification
- [ ] Team onboarding documentation complete: Review docs/

---

## Anti-Patterns to Avoid

- ❌ Don't create agents that duplicate existing CLAUDE.md functionality
- ❌ Don't ignore established iOS simulator requirements (iPhone 16 iOS 18.5 only)
- ❌ Don't implement live log streaming (causes blocking in Claude Code)
- ❌ Don't skip file addition to Xcode project before building
- ❌ Don't create knowledge base entries without successful validation
- ❌ Don't allow vague success criteria in orchestrator handoffs
- ❌ Don't break existing authentication, speech, or subscription workflows

---

## Confidence Score: 9/10

**Why 9/10**: Comprehensive research foundation with proven patterns from music project, deep iOS codebase analysis, and established validation gates. High confidence in one-pass implementation success.

**Risk Mitigation**: Detailed integration points preserve existing functionality while adding sophisticated agent coordination. Progressive validation ensures quality at each step.

**Success Indicators**: 
- Agents successfully coordinate through shared knowledge base
- iOS development cycles become more efficient with accumulated learning
- Team adoption increases due to measurable productivity improvements
- Knowledge base grows consistently with high-quality documented patterns