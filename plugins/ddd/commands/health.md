# /ddd health

Deep DDD health check - the core monitoring capability of this plugin.

## Purpose

Perform comprehensive DDD health analysis that goes beyond surface-level checks. Detects anti-patterns like Anemic Domain Models, Transaction Scripts, layer violations, and more.

## Prerequisites

- `.ddd.yaml` must exist (run `/ddd analyze` first)
- `shared/glossary.yaml` should exist for naming consistency checks

## Usage

```
/ddd health [options]
```

Options:
- `--full`: Run all checks (default)
- `--quick`: Run critical checks only
- `--focus <area>`: Focus on specific area (anemic|aggregate|layer|event|context|naming)
- `--since <date>`: Compare with previous health report

## Deep Health Checks

### 1. Anemic Domain Model Detection

**What it detects**: Domain objects that are just data containers without behavior.

**Detection criteria**:
- Class has only getters/setters, no business methods
- All fields are public or have setters
- No validation logic in the class
- No domain events raised
- Business logic exists in separate "Service" classes

**Severity**: 🔴 Critical

**Example detection**:
```
❌ Anemic Model: Order (src/domain/Order.ts)
   - Business methods: 0
   - Getters/Setters: 12
   - Related service with logic: OrderService (src/services/OrderService.ts)
   - Recommendation: Move business logic from OrderService into Order
```

### 2. Transaction Script Detection

**What it detects**: Services that contain all business logic, treating domain objects as data.

**Detection criteria**:
- Service class with many methods (>15)
- Service class with many lines (>300)
- Service directly manipulates multiple entities
- Domain objects are passed around and mutated
- Single service handling unrelated operations

**Severity**: 🔴 Critical

**Example detection**:
```
❌ Transaction Script: OrderService (src/services/OrderService.ts)
   - Lines: 847
   - Methods: 32
   - Manipulates: Order, OrderItem, Customer, Payment
   - Signs of God Class: handles ordering, payment, notification
   - Recommendation: /ddd refactor split OrderService
```

### 3. Aggregate Health Analysis

**What it detects**: Aggregate design violations based on Vernon's rules.

**Checks**:

#### 3.1 Aggregate Size
- Entities per aggregate (threshold: 3)
- Lines of code in aggregate root (threshold: 500)
- Reference: "About 70% of aggregates have only the root"

```
⚠️ Large Aggregate: Order
   - Contains 5 entities (threshold: 3)
   - Entities: Order, OrderItem, Discount, ShippingInfo, PaymentInfo
   - Consider: Extract ShippingInfo and PaymentInfo as separate aggregates
```

#### 3.2 Aggregate Boundary Violations
- Direct reference to other aggregate's internal entities
- Bypassing aggregate root to access internals
- External modification of aggregate state

```
❌ Boundary Violation: PaymentService.ts:45
   - Directly accesses: order.items[0].price
   - Should access through: Order aggregate root
```

#### 3.3 Identity Reference
- References other aggregates by object instead of ID

```
⚠️ Object Reference: Order.customer
   - References: Customer object directly
   - Should reference: customerId (identity only)
```

### 4. Layer Architecture Violations

**What it detects**: Domain layer dependency on infrastructure.

**Checks**:
- Domain imports from infrastructure packages
- Framework annotations in domain classes
- Direct use of HTTP, database, or external service code in domain

**Severity**: 🔴 Critical

**Example detection**:
```
❌ Layer Violation: Order.ts:3
   - Domain class imports: typeorm
   - Import: import { Entity, Column } from 'typeorm'
   - Impact: Domain depends on infrastructure
   - Fix: Use plain domain class, map in infrastructure layer

❌ Layer Violation: PaymentService.ts:8
   - Domain class imports: axios
   - Import: import axios from 'axios'
   - Impact: External HTTP call in domain
   - Fix: Define port interface, implement adapter in infrastructure
```

### 5. Domain Event Coverage

**What it detects**: State changes that should emit events but don't.

**Metrics**:
- Event coverage = (methods with events / state-changing methods) × 100
- Target: >50% for core aggregates

**Checks**:
- State-changing methods without domain events
- Events without handlers
- Missing events for important state transitions

```
⚠️ Low Event Coverage: Order aggregate
   - State-changing methods: 12
   - Methods emitting events: 2
   - Coverage: 17%
   - Missing events for: cancel(), updateQuantity(), applyDiscount()
```

### 6. Bounded Context Isolation

**What it detects**: Context boundary violations.

**Checks**:
- Direct imports across context boundaries
- Shared mutable state between contexts
- Missing Anti-Corruption Layer for external integrations

```
❌ Context Leak: OrderContext -> PaymentContext
   - File: src/order/OrderService.ts:23
   - Imports: src/payment/PaymentProcessor.ts
   - Issue: Direct dependency across context boundary
   - Fix: Use events or define ACL interface
```

### 7. Naming Consistency (Ubiquitous Language)

**What it detects**: Inconsistent terminology between code and glossary.

**Checks**:
- Class/method names vs glossary terms
- Abbreviations and synonyms usage
- Technical terms replacing domain terms

```
⚠️ Naming Inconsistency
   - Code: CustomerInfo (src/models/CustomerInfo.ts)
   - Glossary: Customer
   - Also found: User, Member (synonyms in use)
   - Recommendation: Standardize to "Customer" everywhere
```

## Output Format

```markdown
## DDD Health Report

**Overall Score**: 58/100 (↓7 from last check)
**Date**: [timestamp]
**Baseline**: [baseline-date or 'First run']

### Summary

| Category | Score | Issues |
|----------|-------|--------|
| Anemic Model | 🔴 20/100 | 3 critical |
| Transaction Script | 🔴 30/100 | 2 critical |
| Aggregate Health | 🟡 65/100 | 4 warnings |
| Layer Architecture | 🔴 40/100 | 2 critical |
| Domain Events | 🟡 55/100 | 3 warnings |
| Context Isolation | 🟢 80/100 | 1 warning |
| Naming Consistency | 🟡 70/100 | 5 warnings |

### 🔴 Critical Issues (Immediate Action Required)

| Location | Issue | Description |
|----------|-------|-------------|
| `Order.ts` | Anemic Model | 0 business methods, 12 getters/setters |
| `OrderService.ts` | Transaction Script | 847 lines, 32 methods |
| `Order.ts:3` | Layer Violation | Imports `typeorm` in domain |
| `PaymentService.ts:8` | Layer Violation | Imports `axios` in domain |

### 🟡 Warnings (Improvement Recommended)

| Location | Issue | Description |
|----------|-------|-------------|
| `Order` aggregate | Size | 5 entities (recommended: ≤3) |
| Domain Events | Coverage | 17% (recommended: ≥50%) |
| `CustomerInfo` | Naming | Glossary defines "Customer" |

### Trend Analysis

- New violations since last check: +4
- Resolved since last check: -1
- Trend: ⬇️ Degrading

### Recommended Actions

1. `/ddd refactor anemic Order` - Convert Anemic Model to Rich Model
2. `/ddd refactor split OrderService` - Break up God Class
3. `/ddd refactor fix-layer Order` - Remove infrastructure dependency
4. `/ddd glossary sync` - Update naming consistency

### Health History

| Date | Score | Critical | Warnings |
|------|-------|----------|----------|
| [today] | 58 | 5 | 9 |
| [last week] | 65 | 3 | 7 |
| [baseline] | 70 | 2 | 5 |
```

## Configuration

Health check thresholds in `.ddd.yaml`:

```yaml
health:
  thresholds:
    # Aggregate rules
    aggregate_max_entities: 3
    aggregate_root_max_lines: 500

    # Transaction Script detection
    service_max_lines: 300
    service_max_methods: 15

    # Event coverage
    event_coverage_min: 50  # percentage

    # Anemic model
    min_business_methods: 1

  ignore:
    - "**/test/**"
    - "**/migrations/**"
    - "**/generated/**"

  # Custom rules
  custom_checks:
    - name: "No raw SQL in domain"
      pattern: "SELECT|INSERT|UPDATE|DELETE"
      paths: ["src/domain/**"]
      severity: critical
```

## Saving Reports

Health reports are saved to `shared/health-reports/[date].md` for trend tracking.

## Integration

Run health checks:
- Manually: `/ddd health`
- In CI: Add to pipeline to fail on critical issues
- Periodically: Track degradation over time
