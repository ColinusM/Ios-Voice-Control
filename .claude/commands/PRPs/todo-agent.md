# Todo Agent Generator

## Feature: $ARGUMENTS

Generate validated todo list for PRP research phase and create specialized research agents to execute those todos efficiently.

## Phase 1: Todo List Generation & Validation

### 1. Analyze Topic & Generate Research Todos
```
Topic: $ARGUMENTS

Generate comprehensive todo list for PRP research phase covering:
- Codebase analysis tasks (search for similar features/patterns)
- External research tasks (documentation, examples, best practices)
- Architecture analysis tasks (existing conventions, test patterns)
- Domain-specific research tasks (libraries, frameworks, tools)
```

### 2. Present Todo List to User
```
Generated Todo List for PRP Research:

1. [ ] Analyze codebase for [specific patterns related to topic]
2. [ ] Research external documentation for [relevant libraries/frameworks]
3. [ ] Find implementation examples for [topic-specific features]
4. [ ] Identify existing test patterns for [validation approach]
5. [ ] Map architecture patterns for [topic integration]
6. [ ] Research best practices and pitfalls for [topic domain]

Is this todo list correct? Please review and modify as needed.
```

**STOP HERE** - Wait for user validation/corrections before proceeding.

## Phase 2: Agent Gap Analysis & Creation

### 3. Analyze Validated Todos for Agent Requirements
For each validated todo, identify required research agent type:
- **Codebase Analysis**: `{domain}-codebase-analyst.md`
- **External Research**: `{domain}-external-researcher.md` 
- **Architecture Mapping**: `{domain}-architecture-mapper.md`
- **Documentation Research**: `{domain}-docs-researcher.md`
- **Implementation Examples**: `{domain}-examples-researcher.md`
- **Best Practices Research**: `{domain}-practices-researcher.md`

### 4. Check Existing Agent Inventory
```bash
# Scan for existing specialized agents in .claude/agents/ directory
find .claude/agents/ -name "*{domain}*" 2>/dev/null
find .claude/agents/ -name "*codebase*" -o -name "*researcher*" -o -name "*mapper*" 2>/dev/null

# Report findings
echo "Existing agents found: [list]"
echo "Missing agents needed: [list]"
```

### 5. Create Missing Research Agents

For each missing agent, create minimal skeleton using compound intelligence template in `.claude/agents/` directory:

#### Agent Creation Pattern:
```markdown
---
name: {domain}-{type}-{researcher/analyst/mapper}
description: Specialized research agent for {specific research type} related to {domain}.
tools: [Read, Write, Edit, Grep, Bash, MultiEdit, Glob, WebSearch, WebFetch]
---

# {Domain} {Type} Research Agent

## Purpose
Specialized research agent for {specific research type} related to {domain}.

## Core Expertise
- {Domain-specific knowledge areas}
- {Research methodology for this type}
- {Common patterns and sources}

## Context Optimization
- 70% {domain} + {research type} expertise
- 20% Research methodology
- 10% Coordination and handoff

## Research Focus Areas
- [List 3-5 key areas this agent specializes in]

## Reliable Sources (Initial)
- [2-3 known reliable sources for this domain/type]

## Knowledge Accumulation Strategy
- Pattern discovery and validation
- Source reliability tracking
- Methodology optimization
- Anti-pattern identification

## Output Format
- Research findings with confidence ratings (1-10)
- Source URLs with reliability assessment
- Discovered patterns with implementation examples
- Failed approaches to avoid

## Handoff Protocol
Updates knowledge base with discovered patterns and validated sources.
```

### 6. Initialize Agent Knowledge Bases
For each created agent, initialize basic knowledge structure:
```yaml
domain: {domain}
research_type: {type}
created_date: {current_date}
session_count: 0
patterns_discovered: 0
reliable_sources: []
failed_approaches: []
methodology_version: "1.0"
```

## Phase 3: Handoff Preparation

### 7. Generate Session 2 Command
```
🤖 Research agents created successfully!

Created agents:
- .claude/agents/{domain}-codebase-analyst.md
- .claude/agents/{domain}-external-researcher.md  
- .claude/agents/{domain}-architecture-mapper.md
- [additional agents as needed]

⚠️ RESTART REQUIRED: Restart Claude Code CLI to load new agents.

📋 Next Session Command:
/prp-base-create-agent "{validated_todo_1}|{validated_todo_2}|{validated_todo_3}|..."

🚀 Research will be 5x faster with specialized agents in next session.
```

## Quality Gates

### Agent Creation Validation
- [ ] All validated todos have corresponding specialized agents
- [ ] Agent templates properly customized for domain
- [ ] Knowledge base structure initialized
- [ ] Agent files saved in `.claude/agents/` directory (NOT .claude/commands/PRPs/)

### Handoff Validation  
- [ ] User has exact command for next session
- [ ] Todo list preserved from user validation
- [ ] Agent assignments mapped to specific todos
- [ ] Clear restart instructions provided

## Success Criteria

- **Complete Agent Coverage**: Every validated todo has a specialized research agent
- **Minimal Agent Structure**: Agents created as skeletons, will self-develop through research
- **Handoff Continuity**: Exact validated todos preserved for Session 2 execution
- **User Clarity**: Clear instructions for CLI restart and next session command

## Implementation Notes

- Keep agent creation minimal - just enough structure for specialized research
- Focus on domain expertise and research methodology optimization
- Agents will accumulate knowledge and improve methodology through actual research work
- Preserve exact user-validated todo list for Session 2 execution continuity

---

**Output**: Specialized research agents ready for lightning-fast PRP research execution in next session.