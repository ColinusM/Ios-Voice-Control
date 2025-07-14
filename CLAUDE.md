# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Nature

This is a **PRP (Product Requirement Prompt) Framework** repository, not a traditional software project. The core concept: **"PRP = PRD + curated codebase intelligence + agent/runbook"** - designed to enable AI agents to ship production-ready code on the first pass.

## Core Architecture

### Command-Driven System

- **28+ pre-configured Claude Code commands** in `.claude/commands/`
- Commands organized by function:
  - `PRPs/` - PRP creation and execution workflows
  - `development/` - Core development utilities (prime-core, onboarding, debug)
  - `code-quality/` - Review and refactoring commands
  - `rapid-development/experimental/` - Parallel PRP creation and hackathon tools
  - `git-operations/` - Conflict resolution and smart git operations

### Template-Based Methodology

- **PRP Templates** in `PRPs/templates/` follow structured format with validation loops
- **Context-Rich Approach**: Every PRP must include comprehensive documentation, examples, and gotchas
- **Validation-First Design**: Each PRP contains executable validation gates (syntax, tests, integration)

### AI Documentation Curation

- `PRPs/ai_docs/` contains curated Claude Code documentation for context injection
- `claude_md_files/` provides framework-specific CLAUDE.md examples

## Development Commands

### PRP Execution

```bash
# Interactive mode (recommended for development)
uv run PRPs/scripts/prp_runner.py --prp [prp-name] --interactive

# Headless mode (for CI/CD)
uv run PRPs/scripts/prp_runner.py --prp [prp-name] --output-format json

# Streaming JSON (for real-time monitoring)
uv run PRPs/scripts/prp_runner.py --prp [prp-name] --output-format stream-json
```

### Key Claude Commands

- `/prp-base-create` - Generate comprehensive PRPs with research
- `/prp-base-execute` - Execute PRPs against codebase
- `/prp-planning-create` - Create planning documents with diagrams
- `/prime-core` - Prime Claude with project context
- `/review-staged-unstaged` - Review git changes using PRP methodology

## Critical Success Patterns

### The PRP Methodology

1. **Context is King**: Include ALL necessary documentation, examples, and caveats
2. **Validation Loops**: Provide executable tests/lints the AI can run and fix
3. **Information Dense**: Use keywords and patterns from the codebase
4. **Progressive Success**: Start simple, validate, then enhance

### PRP Structure Requirements

- **Goal**: Specific end state and desires
- **Why**: Business value and user impact
- **What**: User-visible behavior and technical requirements
- **All Needed Context**: Documentation URLs, code examples, gotchas, patterns
- **Implementation Blueprint**: Pseudocode with critical details and task lists
- **Validation Loop**: Executable commands for syntax, tests, integration

### Validation Gates (Must be Executable)

```bash
# Level 1: Syntax & Style
ruff check --fix && mypy .

# Level 2: Unit Tests
uv run pytest tests/ -v

# Level 3: Integration
uv run uvicorn main:app --reload
curl -X POST http://localhost:8000/endpoint -H "Content-Type: application/json" -d '{...}'

# Level 4: Deployment
# mcp servers, or other creative ways to self validate
```

## iOS Development

### Fast iOS Build and Deploy

For this iOS project, use the optimized CLI workflow that's 6x faster than default xcodebuild:

```bash
# Fast build + install + launch to physical iPhone device
# (Network blocking hack applied for speed - blocks slow Apple provisioning servers)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14
```

This command:
- Builds the iOS app (~10 seconds vs 67+ seconds default)  
- Installs to Colin's iPhone device
- Launches the app automatically
- Shows console logs in terminal
- Uses optimized workflow with Apple server blocking for speed

### iOS Log Capture Workflow

After deploying with the fast build command, capture device logs for debugging:

**Prerequisites:**
```bash
# Install libimobiledevice for device log access
brew install libimobiledevice
```

**Past Log Buffer Capture:**

When you say "grab logs", Claude retrieves recent logs from iOS device buffer - captures your past testing activity without needing live capture during testing.

```bash
# MINIMAL LOGS (default) - Recent buffer with no system noise
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 --quiet --no-kernel | head -100

# ULTRA MINIMAL - Only VoiceControlApp process from recent buffer
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 --quiet --no-kernel -p "VoiceControlApp" | head -50

# EXCLUDE UI NOISE - Remove UIKitCore spam, keep app activity
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 --quiet --no-kernel -e "UIKitCore|backboardd|CommCenter|mDNSResponder" | head -100

# VERBOSE (for deep debugging) - All VoiceControlApp activity including UIKit
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 | grep -E "(VoiceControlApp|🔵|🟢)" | head -200

# ERROR HUNTING - App crashes and exceptions only
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 --quiet --no-kernel | grep -E "(error|Error|crash|Crash|exception|Exception)" | head -50

# LIVE CAPTURE - Background capture with custom duration (when buffer insufficient)
idevicesyslog -u 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14 --quiet --no-kernel & sleep $DURATION && kill $!
```

**Key idevicesyslog Flags for Speed:**
- `--quiet` / `-q`: Excludes noisy system processes
- `--no-kernel` / `-K`: Removes kernel message spam  
- `-m STRING`: Only messages containing string (faster than grep)
- `-p PROCESS`: Only specific process logs
- `-e PROCESS`: Exclude specific processes at source
- `archive --start-time $LAUNCH_TIME`: Only logs from current app session

**Buffer-Based Log Workflow:**
1. **Build & Deploy**: Claude launches app to iPhone
2. **Manual Testing**: You test freely - no logging interference 
3. **Request Logs**: Say "grab logs" to get recent buffer:
   - "grab logs" → MINIMAL (100 lines, clean)
   - "grab verbose logs" → VERBOSE (200 lines, includes UIKit)
   - "grab error logs" → ERROR HUNTING (crashes only)
   - "grab minimal logs" → ULTRA MINIMAL (50 lines, app-only)
4. **Analysis**: Claude analyzes your past testing activity from iOS buffer
5. **Iterate**: Build → Test → Grab → Analyze → Repeat

**How It Works:**
- iOS keeps recent logs in memory buffer (~5-10 minutes)
- When Claude connects, iOS dumps buffer first, then live logs
- `head -N` limits output to recent activity only
- No timeouts, no live capture needed during testing
- Perfect for rapid test-debug cycles

**Benefits:**
- 🎯 **Perfect timing**: Only logs from your actual test session
- ⚡ **Zero overhead**: No continuous streaming during testing
- 🔧 **Agile verbosity**: Choose detail level when you need logs
- 🚀 **Fast iteration**: No timeouts or interruptions

**Compatibility Notes:**
- Works with Xcode 16/26 beta and benefits from enhanced build caching
- ios-deploy supports iOS < 17 (use xcrun devicectl for iOS 17+)
- xcbeautify formats logs but doesn't capture them (use idevicesyslog for actual capture)

## Anti-Patterns to Avoid

- L Don't create minimal context prompts - context is everything - the PRP must be comprehensive and self-contained, reference relevant documentation and examples.
- L Don't skip validation steps - they're critical for one-pass success - The better The AI is at running the validation loop, the more likely it is to succeed.
- L Don't ignore the structured PRP format - it's battle-tested
- L Don't create new patterns when existing templates work
- L Don't hardcode values that should be config
- L Don't catch all exceptions - be specific

## Working with This Framework

### When Creating new PRPs

1. **Context Process**: New PRPs must consist of context sections, Context is King!
2.

### When Executing PRPs

1. **Load PRP**: Read and understand all context and requirements
2. **ULTRATHINK**: Create comprehensive plan, break down into todos, use subagents, batch tool etc check prps/ai_docs/
3. **Execute**: Implement following the blueprint
4. **Validate**: Run each validation command, fix failures
5. **Complete**: Ensure all checklist items done

### Command Usage

- Read the .claude/commands directory
- Access via `/` prefix in Claude Code
- Commands are self-documenting with argument placeholders
- Use parallel creation commands for rapid development
- Leverage existing review and refactoring commands

## Project Structure Understanding

```
PRPs-agentic-eng/
.claude/
  commands/           # 28+ Claude Code commands
  settings.local.json # Tool permissions
PRPs/
  templates/          # PRP templates with validation
  scripts/           # PRP runner and utilities
  ai_docs/           # Curated Claude Code documentation
   *.md               # Active and example PRPs
 claude_md_files/        # Framework-specific CLAUDE.md examples
 pyproject.toml         # Python package configuration
```

Remember: This framework is about **one-pass implementation success through comprehensive context and validation**. Every PRP should contain the exact context for an AI agent to successfully implement working code in a single pass.
