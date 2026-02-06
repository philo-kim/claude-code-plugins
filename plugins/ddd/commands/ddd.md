# /ddd — Smart DDD Governance

One command. AI analyzes your domain model and tells you what needs attention.

## How It Works

`/ddd` reads your project, detects changes since the last check, and runs all relevant DDD analyses. Health checks, validation, glossary consistency, and refactoring suggestions — all in one pass.

## Default Behavior (No Arguments)

```
1. Check for .ddd.yaml (suggest /ddd analyze if missing)
2. Load glossary (shared/glossary.yaml)
3. Load previous health report
4. Detect changed files since last check
5. Run applicable analyses
6. Generate unified report with scores and guidance
```

## Options

- (no args): Smart mode — analyze everything relevant
- `--quick`: Critical issues only
- `--focus <area>`: Focus on one area: `anemic`, `aggregate`, `layer`, `event`, `context`, `naming`
- `--since <date>`: Compare with specific previous scan
- `--ci`: Machine-readable output for CI/CD

---

## Phase 1: Context Gathering

```
1. Read .ddd.yaml configuration
   - If missing → suggest /ddd analyze and exit
2. Identify language and framework
3. Load glossary (shared/glossary.yaml)
4. Load previous health report (shared/health-reports/*.md)
5. Detect changes:
   - git diff for uncommitted changes
   - git log since last health check
6. Map bounded contexts and aggregates from config
```

## Phase 2: Smart Analysis

Run all checks, weighted by what changed.

### Health Check (7 Categories)

Invoke **health-monitor agent** for deep analysis:

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
Category Score = 100 - (Critical × 20) - (Warning × 5)
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

- Compare code names (classes, methods, variables) against glossary terms
- Flag aliases still in use (e.g., `User` should be `Customer`)
- Detect new terms not yet in glossary
- Track terminology drift over time

### Refactoring Suggestions

For critical issues found, automatically suggest refactoring guides:

| Issue | Suggested Refactoring |
|-------|----------------------|
| Anemic Model detected | Convert to Rich Domain Model (move logic from service to entity) |
| Transaction Script / God Class | Split by responsibility (extract domain logic + application service) |
| Primitive fields that belong together | Extract Value Objects (Money, Address, Email) |
| State changes without events | Add Domain Events (OrderCreated, OrderCancelled) |
| Framework in domain | Fix layer (extract ORM entity, add mapper) |
| Oversized aggregate | Extract child aggregate (separate bounded responsibility) |

Each suggestion includes:
- Before/after code examples in your language
- Step-by-step migration path
- Impact assessment (files to modify, tests to update)
- "Would you like me to guide you through this refactoring?"

## Phase 3: Report

```markdown
## DDD Health: 58/100 (↓7)

| Category | Score | Trend | Top Issue |
|----------|-------|-------|-----------|
| Anemic Model | 🔴 20 | ↓ | Order: 0 business methods |
| Transaction Script | 🔴 30 | ↓ | OrderService: 847 lines |
| Aggregate Health | 🟡 65 | → | Order: 5 entities (limit: 3) |
| Layer Architecture | 🔴 40 | ↓ | Order.ts imports typeorm |
| Domain Events | 🟡 55 | → | 17% coverage (target: 50%) |
| Context Isolation | 🟢 80 | ↑ | 1 cross-context import |
| Naming Consistency | 🟡 70 | → | "User" should be "Customer" |

### Critical Issues

| # | Category | Location | Issue |
|---|----------|----------|-------|
| 1 | Anemic | Order.ts | 0 business methods, 12 getters |
| 2 | Script | OrderService.ts | 847 lines, 32 methods |
| 3 | Layer | Order.ts:3 | imports typeorm |
| 4 | Layer | PaymentService.ts:8 | imports axios |

### Validation Results (Changed Files)

| File | Status | Issues |
|------|--------|--------|
| src/order/Order.ts | ❌ 2 violations | Immutability, single transaction |
| src/payment/Payment.ts | ❌ 1 violation | Missing typed identity |
| src/order/OrderItem.ts | ✅ All pass | — |

### Glossary

| Type | Count | Details |
|------|-------|---------|
| Aliases in use | 3 | User→Customer, Member→Customer, LineItem→OrderItem |
| New terms found | 2 | Shipment, Invoice (not in glossary) |
| Terms needing review | 1 | OrderItem |

### Recommended Actions

1. **Enrich Order model** — Move business logic from OrderService into Order
   → Before: 0 methods / After: ~6 methods (addItem, cancel, ship, etc.)
   → Expected score impact: +15 points

2. **Split OrderService** — Break 847-line God Class into focused services
   → Extract: domain logic → Order, payments → PaymentService
   → Expected score impact: +10 points

3. **Fix layer violations** — Remove typeorm/axios from domain
   → Create OrderEntity + OrderMapper in infrastructure
   → Expected score impact: +8 points

Would you like me to guide you through any of these refactorings?

### Trend

| Date | Score | Critical | Warnings |
|------|-------|----------|----------|
| Today | 58 | 5 | 9 |
| Last week | 65 | 3 | 7 |
| Baseline | 70 | 2 | 5 |
| Trend | ⬇️ Degrading | | |
```

## Configuration (.ddd.yaml)

Run `/ddd analyze` to generate initial configuration. Key settings:

- `health.thresholds` — Customize detection thresholds
- `health.weights` — Adjust category importance
- `health.ignore` — Exclude paths from analysis
- `validation.rules` — Enable/disable specific rules
- `glossary.enforce_terms` — Require glossary terms in code
- `bounded_contexts` — Define your contexts and aggregates

## Reports

Reports saved to `shared/health-reports/[date].md` for trend tracking.

## CI/CD Integration

```yaml
# .github/workflows/ddd.yml
- name: DDD Check
  run: claude "/ddd --ci"
  env:
    DDD_MIN_SCORE: 60
    DDD_FAIL_ON_CRITICAL: true
```
