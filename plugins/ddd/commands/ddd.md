---
description: Smart DDD governance - analyzes domain model health and validates changes
argument-hint: [--quick | --focus <area> | --since <date>]
---

# /ddd — Smart DDD Governance

One command. AI analyzes your domain model, tells you what needs attention, and fixes what you approve.

## Core Principles

- **Use TodoWrite**: Create a checklist of all analysis and fix tasks. Update as you progress.
- **Agent delegation**: Use health-monitor agent for analysis, refactor-advisor agent for fixes.
- **Ask before fixing**: Always show the report first. Only fix after user approval.
- **Never stop after analysis**: If critical issues are found and the user approves, proceed to fix them.

## Options

- (no args): Smart mode — analyze everything relevant, then offer to fix
- `--quick`: Critical issues only
- `--focus <area>`: Focus on one area: `anemic`, `aggregate`, `layer`, `event`, `context`, `naming`
- `--since <date>`: Compare with specific previous scan
- `--ci`: Machine-readable output for CI/CD (analysis only, no fixes)

---

## Phase 1: Context Gathering

**Goal**: Understand the project's DDD landscape

**Actions**:
1. Create TodoWrite checklist with all phases
2. Read `.ddd.yaml` configuration
   - If missing → suggest `/ddd analyze` and stop
3. Identify language and framework
4. Load glossary (`shared/glossary.yaml`)
5. Load previous health report (`shared/health-reports/*.md`)
6. Detect changes via git diff / git log since last check
7. Map bounded contexts and aggregates from config

---

## Phase 2: Smart Analysis

**Goal**: Deep analysis across all DDD categories

Launch **health-monitor agent** for analysis:

| Category | Weight | What It Detects |
|----------|--------|----------------|
| Anemic Model | 20% | Domain objects without behavior, all logic in services |
| Transaction Script | 20% | God classes (>300 lines, >15 methods), procedural services |
| Aggregate Health | 15% | Oversized aggregates, boundary violations, object references |
| Layer Architecture | 20% | Framework imports in domain, infrastructure leakage |
| Domain Events | 10% | Low event coverage, missing handlers, state changes without events |
| Context Isolation | 10% | Cross-context imports, shared mutable state, missing ACL |
| Naming Consistency | 5% | Code terms vs glossary, aliases in use, unknown terms |

**Scoring**:
```
Category Score = 100 - (Critical x 20) - (Warning x 5)
Overall Score = Weighted average of all categories
```

### Validation (on changed files)

For files changed since last check, validate 10 DDD rules:

1. **Aggregate Invariants** — Business rules enforced in aggregate
2. **Entity Identity** — Typed identity, not primitive strings
3. **Value Object Immutability** — No setters, no mutation
4. **Repository Interface Location** — Interfaces in domain layer
5. **Domain Service Statelessness** — No instance state
6. **Reference by Identity** — Aggregates reference by ID only
7. **Single Aggregate Transaction** — One aggregate per transaction
8. **Domain Event Structure** — Past-tense naming, contains aggregate ID
9. **Anti-Corruption Layer** — External systems wrapped with ACL
10. **No Framework in Domain** — Domain free of framework imports

### Glossary Consistency

- Compare code names against glossary terms
- Flag aliases still in use
- Detect new terms not yet in glossary

---

## Phase 3: Report

Present the full report to the user:

```markdown
## DDD Health: 58/100 (change from last)

| Category | Score | Trend | Top Issue |
|----------|-------|-------|-----------|
| Anemic Model | score | trend | issue |
| Transaction Script | score | trend | issue |
| ... | ... | ... | ... |

### Critical Issues
| # | Category | Location | Issue |
|---|----------|----------|-------|

### Validation Results (Changed Files)
| File | Status | Issues |
|------|--------|--------|

### Glossary
| Type | Count | Details |
|------|-------|---------|

### Auto-Fixable Issues
| # | Issue | Fix | Estimated Impact |
|---|-------|-----|-----------------|
| 1 | Layer violation: Order.ts imports typeorm | Extract ORM entity + mapper | +8 points |
| 2 | Missing domain events on Order state changes | Add OrderCreated, OrderCancelled events | +5 points |
| 3 | Glossary alias: "User" should be "Customer" | Rename across codebase | +3 points |
```

**CRITICAL**: After the report, always ask:

> "Auto-fixable issues found. Fix them now?"
> - Fix all auto-fixable issues
> - Choose which to fix
> - Skip (report only)

---

## Phase 4: Execute Fixes

**CRITICAL**: Only proceed after user approval from Phase 3.

Launch **refactor-advisor agent** with the approved fix list. The agent will:

### Fixable Issue Types

| Issue Type | What the Agent Does |
|------------|-------------------|
| **Layer violation** | Create port interface in domain, move framework code to adapter, update imports |
| **Missing domain events** | Create event classes (past-tense named), add emit calls to state-changing methods |
| **Glossary aliases** | Rename classes/methods/variables to match glossary terms |
| **Missing value objects** | Extract primitive groups into value object classes |
| **Anemic model** | Move business methods from service to domain entity (with before/after preview) |
| **Missing typed identity** | Create ID value object, replace primitive string IDs |

### Fix Execution Pattern

For each approved fix:
1. Show before/after preview
2. Create/modify the files
3. Update related tests if they exist
4. Mark TodoWrite item complete

### Safety Rules

- **Backup first**: Create `.ddd-backup/` before modifying
- **Incremental**: One fix at a time, verify before next
- **Tests**: If test files exist for modified code, update them too
- **Confirm complex fixes**: For fixes touching 5+ files, ask user again

---

## Phase 5: Summary

After all fixes (or if user chose report-only):

```markdown
# DDD Governance Complete

## Analysis
- Score: X/100 (trend)
- Critical: N issues
- Warnings: N issues

## Fixed (if applicable)
- [list each fix applied with file paths]
- Expected score improvement: +N points

## Remaining
- [issues not fixed, with recommended actions]

## Next Run
Run `/ddd` again after making manual changes to track improvement.
```

Save report to `shared/health-reports/[date].md`.

---

## Configuration (.ddd.yaml)

Run `/ddd analyze` to generate initial configuration. Key settings:

- `health.thresholds` — Customize detection thresholds
- `health.weights` — Adjust category importance
- `health.ignore` — Exclude paths from analysis
- `validation.rules` — Enable/disable specific rules
- `glossary.enforce_terms` — Require glossary terms in code
- `bounded_contexts` — Define your contexts and aggregates

## CI/CD Integration

```yaml
# .github/workflows/ddd.yml
- name: DDD Check
  run: claude "/ddd --ci"
  env:
    DDD_MIN_SCORE: 60
    DDD_FAIL_ON_CRITICAL: true
```
