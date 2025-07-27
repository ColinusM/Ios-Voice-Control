# PRP Base Create with Specialized Agents

## Feature: $ARGUMENTS (Validated Todo List from Session 1)

Execute PRP research phase using specialized research agents for lightning-fast, expert-level research and comprehensive PRP generation.

**Input Format**: Pipe-separated validated todos from `/todo-agent` session
Example: `"Analyze iOS codebase|Research Firebase patterns|Find SwiftUI examples|Map MVVM architecture"`

## Phase 1: Agent Assignment & Research Execution

### 1. Parse Validated Todos
```bash
# Split todo list and assign to specialized agents
IFS='|' read -ra TODOS <<< "$ARGUMENTS"
for todo in "${TODOS[@]}"; do
    echo "Todo: $todo"
    # Determine agent type based on todo content
done
```

### 2. Agent Assignment Logic
Based on todo content, route to appropriate specialized agent:

**Codebase Analysis Todos** → `codebase-analysis-agent`
- Keywords: "analyze codebase", "search code", "find patterns", "existing features"
- Agent: Specialized in project code architecture and pattern discovery

**External Research Todos** → `external-research-agent`  
- Keywords: "research documentation", "find examples", "library docs", "framework guides"
- Agent: Expert in external source research and validation

**Architecture Mapping Todos** → `architecture-mapping-agent`
- Keywords: "map architecture", "integration patterns", "design patterns", "structure analysis"
- Agent: Specialized in translating between architectural patterns

**Best Practices Todos** → `practices-research-agent`
- Keywords: "best practices", "common pitfalls", "gotchas", "anti-patterns"
- Agent: Expert in domain-specific practices and failure patterns

**Implementation Examples Todos** → `examples-research-agent`
- Keywords: "implementation examples", "code samples", "GitHub examples", "real-world usage"
- Agent: Specialized in finding and validating practical implementation examples

### 3. Parallel Research Execution

Execute research using specialized agents with batch tool coordination:

```
Research Phase Execution:

For each validated todo:
1. Route to appropriate specialized agent
2. Agent leverages pre-loaded domain expertise
3. Agent focuses on incremental research (not rediscovery)
4. Agent updates knowledge base with new findings
5. Agent provides expert-level insights with confidence ratings
```

## Phase 2: Deep Research with Specialized Agents

### 1. Codebase Analysis (Enhanced)
**Agent**: `codebase-analysis-agent`
- **Pre-loaded Knowledge**: Existing project patterns, MVVM structures, common files
- **Research Focus**: New patterns specific to current PRP topic
- **Output**: 
  - Relevant file references with line numbers
  - Existing pattern matches and deviations needed
  - Integration points and dependency requirements
  - Test pattern recommendations

### 2. External Research (Accelerated)
**Agent**: `external-research-agent`
- **Pre-loaded Knowledge**: Validated source list, framework documentation structure
- **Research Focus**: Latest updates, topic-specific advanced patterns
- **Output**:
  - Documentation URLs with specific sections
  - Library/framework version considerations
  - Configuration requirements and gotchas
  - Implementation prerequisites

### 3. Architecture Mapping (Expert-Level)
**Agent**: `architecture-mapping-agent`  
- **Pre-loaded Knowledge**: Common architectural translations, pattern mappings
- **Research Focus**: Complex integration patterns, advanced architectures
- **Output**:
  - Detailed integration strategy
  - Component interaction patterns
  - State management approach
  - Error handling architecture

### 4. Implementation Examples (Curated)
**Agent**: `examples-research-agent`
- **Pre-loaded Knowledge**: Validated example repositories, trusted code sources
- **Research Focus**: Advanced examples, edge case handling
- **Output**:
  - Real-world implementation snippets
  - Production-ready code patterns
  - Edge case handling examples
  - Performance optimization patterns

### 5. Best Practices Research (Refined)
**Agent**: `practices-research-agent`
- **Pre-loaded Knowledge**: Common pitfalls, anti-patterns, known issues
- **Research Focus**: Latest best practices, emerging patterns
- **Output**:
  - Updated best practices with reasoning
  - Pitfall avoidance strategies
  - Performance and security considerations
  - Maintenance and scalability patterns

## Phase 3: Knowledge Integration & PRP Generation

### 1. Consolidate Research Findings
```
Research Integration:
- Combine findings from all specialized agents
- Cross-validate recommendations across agents
- Identify conflicts and resolve with expert judgment
- Create comprehensive context for PRP
```

### 2. Enhanced Context Generation
Based on specialized agent research, generate rich context including:

**Critical Context (Enhanced by Agents)**:
- **Documentation**: URLs with agent-validated specific sections
- **Code Examples**: Agent-discovered real snippets from codebase and external sources
- **Gotchas**: Agent-identified library quirks, version issues, integration pitfalls
- **Patterns**: Agent-mapped existing approaches and recommended adaptations
- **Best Practices**: Agent-researched common pitfalls and proven solutions

### 3. Implementation Blueprint (Expert-Guided)
Using agent research, create detailed blueprint:
- **Approach**: Agent-recommended pseudocode with pattern justification
- **File References**: Agent-identified real files for pattern following
- **Error Handling**: Agent-researched comprehensive error strategy
- **Task Breakdown**: Agent-optimized task order with dependency mapping

### 4. Advanced Validation Gates
Agents contribute domain-specific validation approaches:
```bash
# Agent-recommended validation gates
{domain}-specific-linting
{domain}-unit-test-patterns  
{domain}-integration-test-strategy
{domain}-performance-validation
{domain}-security-checks
```

## Phase 4: Ultrathink & Agent-Enhanced PRP Generation

### CRITICAL ULTRATHINK PHASE
**Pre-PRP Ultrathink Session with Agent Intelligence**:
```
ULTRATHINK: Agent-Informed PRP Strategy & Approach Planning

Agent Research Summary:
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

Cross-Agent Integration Analysis:
- Multi-agent validation results and consensus areas
- Conflicting recommendations resolution with expert arbitration
- Research gap identification and mitigation strategies
- Implementation complexity assessment with agent confidence scoring

Agent-Informed PRP Strategy:
- Expert-guided detailed implementation approach
- Agent-researched risk mitigation strategies
- Multi-agent validated success criteria definition
- Compound intelligence-backed one-pass implementation feasibility assessment
```

### PRP Document Generation
Using `PRPs/templates/prp_base_agent.md` template with agent-enhanced content:

**Agent-Enhanced Sections**:
- **Agent Research Summary**: Comprehensive findings from all specialized research agents
- **Agent-Validated Context**: Multi-agent validated documentation and references with confidence ratings
- **Agent-Guided Implementation**: Expert-recommended architecture patterns and task sequencing
- **Agent-Enhanced Pseudocode**: Research-backed implementation patterns with critical insights
- **Agent-Mapped Integration**: Specialized agent-discovered integration points and dependencies
- **Agent-Designed Validation**: Multi-level validation strategy based on agent research
- **Agent Learning Updates**: Knowledge base updates for compound intelligence growth

## Phase 5: Quality Assurance & Agent Learning

### 1. PRP Quality Validation
- [ ] All agent research integrated comprehensively
- [ ] Cross-agent findings validated and conflicts resolved
- [ ] Implementation path clear and executable
- [ ] Validation gates comprehensive and testable
- [ ] Context rich enough for one-pass implementation

### 2. Agent Knowledge Base Updates
Each agent updates their knowledge base with session discoveries:
- New patterns discovered and validated
- Source reliability updates
- Methodology improvements
- Failed approaches to avoid in future

### 3. Confidence Scoring
Rate PRP confidence (1-10) based on:
- Depth of agent research coverage
- Quality of cross-validation between agents
- Comprehensiveness of implementation strategy
- Robustness of validation gates

## Output

**Generated PRP**: `PRPs/{feature-name}.md`
- Expert-level research depth from specialized agents
- Comprehensive context for one-pass implementation
- Agent-validated patterns and approaches
- Enhanced validation strategy

**Agent Learning**: Updated knowledge bases for future 10x speed improvements

## Success Metrics

- **Research Speed**: 5x+ faster than general-purpose agents
- **Research Depth**: Expert-level insights from domain specialists  
- **Context Quality**: Rich, validated information for implementation success
- **PRP Confidence**: 8+ confidence rating for one-pass implementation
- **Agent Growth**: Measurable knowledge base expansion for compound intelligence

---

**Result**: Lightning-fast, expert-level PRP creation with specialized agent research and compound intelligence accumulation.