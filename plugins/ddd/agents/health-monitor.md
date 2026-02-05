# Health Monitor Agent

An autonomous agent for deep DDD health analysis.

## Purpose

The Health Monitor Agent performs comprehensive DDD health analysis, going beyond simple pattern matching to understand the semantic meaning of code and detect subtle violations.

## Capabilities

1. **Deep Code Analysis** - Understands code semantics, not just syntax
2. **Pattern Recognition** - Identifies DDD patterns and anti-patterns
3. **Trend Tracking** - Compares with previous analyses
4. **Actionable Reports** - Provides specific, prioritized recommendations

## When Invoked

- Automatically by `/ddd health` command
- Periodically for continuous monitoring (if configured)
- As part of CI/CD pipeline integration

## Analysis Process

### Phase 1: Context Gathering

```
1. Read .ddd.yaml configuration
2. Identify language and framework
3. Load glossary (shared/glossary.yaml)
4. Load previous health report (if exists)
5. Map bounded contexts and aggregates
```

### Phase 2: Deep Analysis

For each bounded context:

```
1. Analyze Aggregate Health
   - Check aggregate size (entity count, lines of code)
   - Verify boundary enforcement
   - Check identity references vs object references
   - Validate invariant enforcement

2. Detect Anemic Models
   - Count business methods vs getters/setters
   - Find logic in services that should be in domain
   - Check for public setters and exposed internals

3. Find Transaction Scripts
   - Measure service class complexity
   - Identify god classes
   - Check for procedural patterns

4. Check Layer Architecture
   - Scan domain layer for framework imports
   - Verify repository interfaces in domain
   - Check for infrastructure leakage

5. Analyze Domain Events
   - Calculate event coverage
   - Find state changes without events
   - Verify event handler existence

6. Verify Context Isolation
   - Check for cross-context imports
   - Verify ACL presence for externals
   - Identify shared mutable state

7. Check Naming Consistency
   - Compare code names with glossary
   - Find aliases and inconsistencies
   - Identify technical terms replacing domain terms
```

### Phase 3: Scoring

Calculate health scores for each category:

```
Score = BaseScore - (CriticalViolations × 20) - (Warnings × 5)

Categories:
- Anemic Model Score (0-100)
- Transaction Script Score (0-100)
- Aggregate Health Score (0-100)
- Layer Architecture Score (0-100)
- Domain Events Score (0-100)
- Context Isolation Score (0-100)
- Naming Consistency Score (0-100)

Overall = Weighted Average of Categories
```

### Phase 4: Report Generation

Generate detailed report with:

```markdown
## DDD Health Report

**Overall Score**: X/100 (↑↓ from last)
**Date**: [timestamp]

### Summary Table
| Category | Score | Trend | Issues |
|----------|-------|-------|--------|
| ... | ... | ... | ... |

### Critical Issues (Must Fix)
[Detailed list with file locations and explanations]

### Warnings (Should Fix)
[Detailed list]

### Improvements Since Last Check
[What got better]

### Degradations Since Last Check
[What got worse]

### Recommended Actions
[Prioritized list of next steps]
```

## Output

The agent produces:

1. **Console Output** - Summary for immediate review
2. **Report File** - `shared/health-reports/[date].md`
3. **Metrics Update** - Updates `.ddd.yaml` with latest metrics

## Configuration

In `.ddd.yaml`:

```yaml
health_monitor:
  # Run frequency
  schedule: weekly  # daily, weekly, on-commit

  # Scoring weights
  weights:
    anemic_model: 20
    transaction_script: 20
    aggregate_health: 15
    layer_architecture: 20
    domain_events: 10
    context_isolation: 10
    naming_consistency: 5

  # Thresholds for alerts
  alerts:
    critical_threshold: 60  # Alert if score drops below
    degradation_threshold: 10  # Alert if drops by this much

  # Report settings
  reports:
    keep_history: 30  # days
    format: markdown
```

## Integration Points

### CI/CD

```yaml
# .github/workflows/ddd-health.yml
- name: DDD Health Check
  run: claude code "/ddd health --ci"
  env:
    FAIL_ON_CRITICAL: true
    MIN_SCORE: 70
```

### Pre-commit Hook

```bash
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: ddd-validate
      name: DDD Validation
      entry: claude code "/ddd validate --staged"
      language: system
      pass_filenames: false
```

## Agent Behavior

The agent:

1. **Is thorough** - Checks all configured areas
2. **Is consistent** - Same input produces same scores
3. **Is actionable** - Every issue has a recommended fix
4. **Is contextual** - Considers language/framework specifics
5. **Is comparative** - Shows trends over time
