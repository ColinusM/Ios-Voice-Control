name: "Agent-Enhanced PRP Template v3 - Specialized Research Integration"
description: |

## Purpose

Template optimized for AI agents implementing features with specialized research agent context and compound intelligence validation loops to achieve working code through expert-guided iterative refinement.

## Core Principles

1. **Agent-Validated Context**: Include ALL necessary documentation, examples, and caveats discovered by specialized research agents
2. **Multi-Agent Validation**: Provide executable tests/lints validated by domain specialist agents
3. **Expert-Dense Information**: Use patterns and insights from compound intelligence research
4. **Progressive Expert Success**: Start with agent-recommended approach, validate with agent-designed tests, enhance with agent insights

---

## Goal

[What needs to be built - be specific about the end state and desires, enhanced with agent research insights]

## Why

- [Business value and user impact - validated by agent research]
- [Integration with existing features - mapped by architecture agents]
- [Problems this solves and for whom - confirmed by domain specialist agents]

## What

[User-visible behavior and technical requirements - refined through agent analysis]

### Success Criteria (Agent-Validated)

- [ ] [Specific measurable outcomes validated by research agents]
- [ ] [Performance criteria recommended by domain specialists]
- [ ] [Integration requirements confirmed by architecture mappers]

## Agent Research Summary

### Research Agent Contributions

```yaml
codebase_analysis_agent:
  findings: [Key patterns discovered in existing codebase]
  recommendations: [Specific files and patterns to follow]
  integration_points: [Existing code to modify or extend]
  test_patterns: [Discovered testing approaches to mirror]

external_research_agent:
  documentation: [Validated external documentation with specific sections]
  libraries: [Framework-specific insights and gotchas]
  examples: [Curated real-world implementation patterns]
  best_practices: [Industry-standard approaches for this domain]

architecture_mapping_agent:
  patterns: [Recommended architectural patterns for integration]
  dependencies: [Required component interactions]
  data_flow: [State management and data flow recommendations]
  error_handling: [Comprehensive error handling strategy]

practices_research_agent:
  best_practices: [Domain-specific best practices with reasoning]
  anti_patterns: [Common pitfalls to avoid with examples]
  performance: [Performance optimization recommendations]
  security: [Security considerations and implementation patterns]

examples_research_agent:
  implementations: [Validated production-ready code examples]
  edge_cases: [Real-world edge case handling patterns]
  testing: [Comprehensive testing examples from reliable sources]
  optimization: [Performance and maintainability optimizations]
```

## All Needed Context (Agent-Enhanced)

### Documentation & References (Agent-Curated High-Quality Sources)

```yaml
# AGENT-VALIDATED MUST READ - Include these in your context window
- url: [Agent-validated official API docs URL]
  why: [Agent-identified specific sections/methods you'll need]
  confidence: [Agent confidence rating 1-10]
  agent_notes: [Critical insights from agent research]

- file: [Agent-discovered path/to/example.py]
  why: [Agent-identified pattern to follow, gotchas to avoid]
  patterns: [Specific patterns agent recommends following]
  modifications: [Agent-recommended adaptations needed]

- doc: [Agent-validated library documentation URL]
  section: [Agent-identified specific section about common pitfalls]
  critical: [Agent-discovered key insight that prevents common errors]
  reliability: [Agent-assessed source reliability rating]

- docfile: [PRPs/ai_docs/agent_research_file.md]
  why: [Agent-researched and curated critical documentation]
  agent_summary: [Agent's key takeaways and recommendations]
```

### Current Codebase Analysis (Agent-Analyzed)

```bash
# Agent-analyzed codebase structure with integration insights
[Agent-generated current tree with identified integration points]
```

### Desired Codebase Architecture (Agent-Recommended)

```bash
# Agent-recommended structure with file responsibilities
[Agent-designed optimal structure based on research findings]
```

### Agent-Discovered Gotchas & Library Insights

```python
# AGENT-CRITICAL: [Agent-researched library-specific requirements]
# Agent Finding: [Specific setup requirements discovered through research]
# Agent Warning: [Performance/security/compatibility issues identified]
# Agent Recommendation: [Proven workarounds and best practices]

# Example from iOS research:
# AGENT-CRITICAL: SwiftUI @Published requires @MainActor for UI updates
# Agent Finding: Firebase Auth token refresh needs proper error handling
# Agent Warning: AssemblyAI streaming requires specific WebSocket configuration
# Agent Recommendation: Use established MVVM pattern from AuthenticationManager
```

## Implementation Blueprint (Agent-Guided)

### Agent-Recommended Architecture

Based on specialized agent research, implement using proven patterns:

```yaml
data_models: [Agent-identified optimal data structure patterns]
state_management: [Agent-recommended state management approach]
error_handling: [Agent-researched comprehensive error strategy]
testing_strategy: [Agent-validated testing patterns from similar features]
performance_patterns: [Agent-discovered optimization techniques]
```

### Agent-Validated Implementation Tasks

```yaml
Task 1: [Agent Priority Order Based on Research]
AGENT_GUIDANCE: [Agent-specific insights for this task]
MODIFY [agent-identified-file]:
  - AGENT_PATTERN: [Agent-discovered existing pattern to follow]
  - AGENT_INTEGRATION: [Agent-mapped integration points]
  - AGENT_TESTS: [Agent-recommended validation approach]

CREATE [agent-recommended-new-file]:
  - AGENT_MIRROR: [Agent-identified similar pattern from: existing-file]
  - AGENT_ADAPTATIONS: [Agent-recommended modifications needed]
  - AGENT_VALIDATIONS: [Agent-designed success criteria]

Task 2: [Agent-Sequenced Next Priority]
...

Task N: [Agent-Ordered Final Integration]
...
```

### Agent-Enhanced Pseudocode

```python
# Agent-Recommended Implementation Pattern
# Based on [agent-name] research findings

async def agent_recommended_approach(param: AgentValidatedType) -> AgentDefinedResult:
    # AGENT-PATTERN: [Agent-discovered input validation pattern]
    validated = agent_recommended_validator(param)  # from [agent-identified-file]
    
    # AGENT-CRITICAL: [Agent-researched library requirement]
    async with agent_discovered_connection_pattern() as conn:
        # AGENT-OPTIMIZATION: [Agent-found performance pattern]
        @agent_recommended_retry_decorator(attempts=3, strategy=agent_researched_backoff)
        async def _inner():
            # AGENT-WARNING: [Agent-identified rate limit/constraint]
            await agent_validated_rate_limiter.acquire()
            return await agent_researched_api_call(validated)
        
        result = await _inner()
    
    # AGENT-STANDARD: [Agent-identified response format pattern]
    return agent_discovered_formatter(result)  # from [agent-mapped-utility-file]
```

### Agent-Mapped Integration Points

```yaml
DATABASE_INTEGRATION: [Agent-researched database patterns]
  migration: [Agent-recommended schema changes]
  indexes: [Agent-identified performance optimizations]
  patterns: [Agent-discovered existing database interaction patterns]

CONFIGURATION_MANAGEMENT: [Agent-validated config patterns]
  settings: [Agent-identified configuration file patterns]
  environment: [Agent-recommended environment variable patterns]
  validation: [Agent-designed configuration validation]

API_INTEGRATION: [Agent-mapped API patterns]
  routing: [Agent-discovered routing patterns to follow]
  middleware: [Agent-identified middleware requirements]
  authentication: [Agent-researched auth integration patterns]

STATE_MANAGEMENT: [Agent-recommended state patterns]
  patterns: [Agent-identified existing state management to mirror]
  updates: [Agent-recommended state update patterns]
  persistence: [Agent-researched data persistence strategies]
```

## Validation Loop (Agent-Enhanced)

### Level 1: Agent-Recommended Syntax & Style

```bash
# Agent-validated linting and type checking patterns
[agent-recommended-linter] [agent-identified-files] --fix
[agent-validated-type-checker] [agent-mapped-files]

# Agent Success Criteria: [Agent-defined expected outcomes]
# Agent Debugging: [Agent-researched common error patterns and solutions]
```

### Level 2: Agent-Designed Unit Tests

```python
# Agent-recommended test patterns based on research
# CREATE [agent-suggested-test-file] with agent-validated test cases:

def test_agent_validated_happy_path():
    """Agent-researched optimal success case"""
    # Agent Pattern: [Agent-discovered testing pattern from similar features]
    result = agent_recommended_function("agent_validated_input")
    assert result.matches_agent_criteria()

def test_agent_identified_edge_cases():
    """Agent-researched edge cases from real-world examples"""
    # Agent Insight: [Agent-discovered edge case from external research]
    with pytest.raises(AgentIdentifiedException):
        agent_recommended_function("agent_researched_edge_case")

def test_agent_researched_error_scenarios():
    """Agent-validated error handling patterns"""
    # Agent Pattern: [Agent-identified error handling approach]
    with mock.patch('agent_discovered_dependency', side_effect=AgentResearchedException):
        result = agent_recommended_function("valid_input")
        assert result.follows_agent_error_pattern()
```

```bash
# Agent-recommended test execution
[agent-validated-test-runner] [agent-suggested-test-files] -v
# Agent Success: [Agent-defined test success criteria]
# Agent Debugging: [Agent-researched test failure diagnosis patterns]
```

### Level 3: Agent-Validated Integration Testing

```bash
# Agent-recommended integration test approach
[agent-discovered-service-start-command]

# Agent-designed integration tests
[agent-researched-test-commands]

# Agent Success Criteria: [Agent-defined integration success patterns]
# Agent Monitoring: [Agent-recommended monitoring and logging patterns]
```

### Level 4: Agent-Enhanced Creative Validation

```bash
# Agent-researched domain-specific validation methods
[agent-recommended-performance-tests]
[agent-designed-security-validation]
[agent-researched-usability-testing]

# Agent-specific validation based on research domain
# [Agent-customized validation methods discovered through research]
```

## Agent-Enhanced Quality Gates

### Agent Validation Checklist

- [ ] Agent-recommended tests pass: `[agent-validated-test-command]`
- [ ] Agent-discovered linting rules satisfied: `[agent-recommended-lint-command]`
- [ ] Agent-researched type safety confirmed: `[agent-validated-type-command]`
- [ ] Agent-designed integration tests successful: `[agent-integration-test-command]`
- [ ] Agent-identified error cases handled: [Agent-specific error scenarios]
- [ ] Agent-recommended performance criteria met: [Agent-defined performance gates]
- [ ] Agent-researched security requirements satisfied: [Agent-security-checklist]

### Agent Learning & Knowledge Update

```yaml
# Update agent knowledge bases with implementation findings
codebase_agent_updates:
  - new_patterns_discovered: [Patterns found during implementation]
  - integration_insights: [Successful integration approaches]
  - failed_approaches: [What didn't work and why]

external_research_agent_updates:
  - source_validation: [Which external sources proved most reliable]
  - documentation_gaps: [Missing information discovered during implementation]
  - best_practice_validation: [Confirmed best practices through implementation]

architecture_agent_updates:
  - pattern_effectiveness: [How well recommended patterns worked]
  - integration_challenges: [Unexpected integration difficulties]
  - optimization_opportunities: [Performance improvements discovered]
```

## Agent-Informed Anti-Patterns

Based on agent research findings:

- ❌ Don't ignore agent-identified performance patterns
- ❌ Don't skip agent-recommended error handling approaches
- ❌ Don't deviate from agent-validated integration patterns without research
- ❌ Don't use deprecated approaches identified by agent research
- ❌ Don't implement without agent-recommended testing strategies
- ❌ Don't ignore agent-discovered security considerations
- ❌ Don't bypass agent-identified validation requirements

## Agent Research Confidence Score

**Overall Confidence**: [X/10] based on:
- Research depth across [N] specialized agents
- Source validation and cross-referencing quality
- Pattern discovery and validation thoroughness
- Implementation approach comprehensiveness
- Error handling and edge case coverage

**Agent Recommendation**: [Agent consensus on implementation approach and expected success probability]

---

**Result**: Expert-level implementation guidance backed by specialized agent research, validated patterns, and compound intelligence for maximum one-pass implementation success.