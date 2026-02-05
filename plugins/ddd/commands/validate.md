# /ddd validate

Validate DDD principles compliance for specific code changes or files.

## Purpose

While `/ddd health` provides comprehensive analysis, `/ddd validate` performs targeted validation on specific files or changes. Ideal for:
- Pre-commit checks
- Code review assistance
- Validating new code follows DDD patterns

## Usage

```
/ddd validate [target] [options]
```

Targets:
- `<file>` - Validate a specific file
- `<directory>` - Validate all files in directory
- `--staged` - Validate git staged changes
- `--changed` - Validate uncommitted changes

Options:
- `--strict` - Fail on warnings too
- `--fix-suggestions` - Include fix suggestions

## Validation Rules

### Rule 1: Aggregate Invariants

Validate that aggregate roots enforce business rules.

```markdown
✅ PASS: Order.addItem() validates inventory before adding
❌ FAIL: Order.setStatus() allows invalid state transitions
   - File: src/order/Order.ts:45
   - Issue: No validation before setting status
   - Rule: Aggregate must enforce invariants
```

### Rule 2: Entity Identity

Validate that entities have proper identity.

```markdown
✅ PASS: Order has OrderId value object for identity
❌ FAIL: OrderItem uses primitive string for id
   - File: src/order/OrderItem.ts:5
   - Issue: id is primitive string, not typed identity
   - Rule: Entities should have typed identities
```

### Rule 3: Value Object Immutability

Validate that value objects are immutable.

```markdown
✅ PASS: Money class has no setters, all fields readonly
❌ FAIL: Address has mutable street field
   - File: src/shared/Address.ts:8
   - Issue: street field can be modified after creation
   - Rule: Value objects must be immutable
```

### Rule 4: Repository Interface Location

Validate repository interfaces are in domain layer.

```markdown
✅ PASS: OrderRepository interface in src/domain/order/
❌ FAIL: PaymentRepository interface in src/infrastructure/
   - File: src/infrastructure/PaymentRepository.ts
   - Issue: Repository interface in infrastructure layer
   - Rule: Repository interfaces belong in domain layer
```

### Rule 5: Domain Service Statelessness

Validate domain services have no state.

```markdown
✅ PASS: PricingService has no instance fields
❌ FAIL: OrderDomainService has cached state
   - File: src/domain/OrderDomainService.ts:10
   - Issue: Instance field 'cachedRates' holds state
   - Rule: Domain services should be stateless
```

### Rule 6: Aggregate Reference by Identity

Validate aggregates reference each other by ID only.

```markdown
✅ PASS: Order.customerId references Customer by ID
❌ FAIL: Order.payment holds Payment object directly
   - File: src/order/Order.ts:15
   - Issue: Direct object reference to Payment aggregate
   - Rule: Reference other aggregates by identity only
```

### Rule 7: Single Aggregate per Transaction

Validate transactions modify only one aggregate.

```markdown
✅ PASS: CreateOrderHandler modifies only Order aggregate
❌ FAIL: OrderService.process() modifies Order and Inventory
   - File: src/services/OrderService.ts:89
   - Issue: Single method modifies multiple aggregates
   - Rule: One aggregate per transaction (use events for others)
```

### Rule 8: Domain Event Structure

Validate domain events follow conventions.

```markdown
✅ PASS: OrderCreated is past-tense, contains aggregate ID
❌ FAIL: CreateOrder is present-tense
   - File: src/events/CreateOrder.ts
   - Issue: Event name should be past-tense (OrderCreated)
   - Rule: Domain events represent facts that happened
```

### Rule 9: Anti-Corruption Layer Presence

Validate external integrations have ACL.

```markdown
✅ PASS: PaymentGatewayAdapter wraps external payment API
❌ FAIL: ShippingService directly calls external API
   - File: src/services/ShippingService.ts:34
   - Issue: Direct HTTP call to external shipping API
   - Rule: External systems require Anti-Corruption Layer
```

### Rule 10: No Framework in Domain

Validate domain is free of framework dependencies.

```markdown
✅ PASS: Order.ts has no framework imports
❌ FAIL: Customer.ts imports NestJS decorator
   - File: src/domain/Customer.ts:2
   - Issue: @Injectable() from NestJS in domain
   - Rule: Domain layer must be framework-agnostic
```

## Output Format

### Single File Validation

```markdown
## Validation: src/order/Order.ts

**Result**: ⚠️ 2 issues found

### Passed (8)
✅ Aggregate invariants enforced
✅ Entity has typed identity
✅ No framework dependencies
✅ Repository interface location correct
✅ References by identity
✅ Domain events are past-tense
✅ No direct external calls
✅ Stateless services

### Failed (2)

#### ❌ Value Object Immutability
- **Location**: Line 23
- **Issue**: `shippingAddress` field is mutable
- **Suggestion**: Make field readonly, use `withAddress()` method

#### ⚠️ Single Aggregate Transaction
- **Location**: Line 89
- **Issue**: `process()` method updates inventory
- **Suggestion**: Emit `OrderProcessed` event, handle inventory separately
```

### Staged Changes Validation

```
/ddd validate --staged
```

```markdown
## Validation: Staged Changes

**Files Changed**: 5
**Result**: ❌ 3 violations

### src/order/Order.ts (modified)
✅ All rules pass

### src/order/OrderService.ts (modified)
❌ Transaction Script pattern detected
   - Added method increases service to 320 lines
   - Consider extracting to domain object

### src/payment/Payment.ts (new)
❌ Missing typed identity
   - Uses primitive string for id
⚠️ No domain events
   - State changes should emit events

### Recommendation
Fix violations before committing. Run:
- `/ddd refactor anemic Payment`
- `/ddd refactor split OrderService`
```

## CI Integration

Add to your CI pipeline:

```yaml
# .github/workflows/ddd-validate.yml
name: DDD Validation

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: DDD Validation
        run: |
          # Run validation on changed files
          claude code "/ddd validate --changed --strict"
```

## Configuration

In `.ddd.yaml`:

```yaml
validation:
  # Enable/disable specific rules
  rules:
    aggregate_invariants: true
    entity_identity: true
    value_object_immutability: true
    repository_location: true
    domain_service_stateless: true
    reference_by_identity: true
    single_aggregate_transaction: true
    domain_event_structure: true
    anti_corruption_layer: true
    no_framework_in_domain: true

  # Treat warnings as errors
  strict: false

  # Paths to validate
  paths:
    - src/domain/**
    - src/application/**

  # Paths to ignore
  ignore:
    - src/domain/**/*.test.ts
    - src/domain/**/*.spec.ts
```

## Comparison with /ddd health

| Aspect | /ddd validate | /ddd health |
|--------|---------------|-------------|
| Scope | Specific files/changes | Entire codebase |
| Speed | Fast | Comprehensive |
| Use Case | Pre-commit, code review | Periodic analysis |
| Output | Pass/Fail per rule | Scores and trends |
| CI | Recommended | Optional |
