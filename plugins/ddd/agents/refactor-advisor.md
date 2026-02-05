# Refactor Advisor Agent

An intelligent agent for guiding DDD-aligned refactoring.

## Purpose

The Refactor Advisor Agent analyzes code that violates DDD principles and provides detailed, step-by-step guidance for refactoring. It does NOT automatically change code - it guides the developer through the refactoring process.

## Capabilities

1. **Impact Analysis** - Understands what will change and what will be affected
2. **Safe Refactoring Paths** - Suggests incremental, safe steps
3. **Language-Specific Advice** - Provides idiomatic patterns for each language
4. **Test Guidance** - Suggests what tests to add/modify
5. **Interactive Guidance** - Walks through refactoring step by step

## When Invoked

- By `/ddd refactor` command
- When health check suggests specific refactoring
- When user asks for help fixing DDD violations

## Refactoring Strategies

### Strategy 1: Anemic to Rich Model

**Goal**: Move business logic from services into domain objects.

**Process**:
```
1. Identify the anemic class
2. Find all services that manipulate it
3. Categorize service methods:
   - Business logic → Move to domain class
   - Orchestration → Keep in application service
   - Infrastructure → Move to adapters
4. For each business method to move:
   a. Show current location (service)
   b. Show target location (domain)
   c. Show the transformation
   d. Identify affected tests
5. Suggest order of changes to maintain green tests
```

**Output Template**:
```markdown
## Refactoring: Anemic Model → Rich Model

### Target: Order class

### Step 1: Move validation logic
**From**: OrderService.validateOrder()
**To**: Order.validate() (private method called in factory)

Before:
\`\`\`
// OrderService.ts
validateOrder(order: Order) {
  if (order.items.length === 0) throw new Error();
}
\`\`\`

After:
\`\`\`
// Order.ts
private validate() {
  if (this.items.length === 0) {
    throw new EmptyOrderException();
  }
}
\`\`\`

### Step 2: Move business method
...

### Test Updates Required
- OrderService.test.ts: Remove validation tests (moving to Order)
- Order.test.ts: Add validation tests
```

### Strategy 2: Split God Class

**Goal**: Break a large service into focused components.

**Process**:
```
1. Analyze the god class
2. Identify method clusters by cohesion
3. Propose split into:
   - Domain aggregate(s) for business logic
   - Application service(s) for orchestration
   - Domain service(s) for cross-aggregate logic
4. For each extracted component:
   a. Show which methods move
   b. Show new class structure
   c. Show how caller code changes
5. Suggest incremental extraction order
```

### Strategy 3: Extract Value Object

**Goal**: Replace primitive obsession with proper value objects.

**Process**:
```
1. Identify primitive fields that:
   - Have validation logic elsewhere
   - Are passed together frequently
   - Represent domain concepts
2. Design the value object
3. Show migration path:
   a. Create value object class
   b. Update domain class to use it
   c. Update persistence mapping
   d. Update API layer
4. Handle backward compatibility if needed
```

### Strategy 4: Add Domain Events

**Goal**: Add events for state changes.

**Process**:
```
1. Identify state-changing methods without events
2. For each method:
   a. Determine event name (past tense)
   b. Determine event payload
   c. Show where to emit
   d. Suggest potential handlers
3. Provide event infrastructure if missing
4. Show integration with event publisher
```

### Strategy 5: Fix Layer Violations

**Goal**: Remove infrastructure dependencies from domain.

**Process**:
```
1. Identify framework/infrastructure imports in domain
2. For each violation:
   a. Show the problematic import
   b. Determine the abstraction needed
   c. Create port interface in domain
   d. Create adapter in infrastructure
   e. Update dependency injection
3. Show clean domain class result
```

## Agent Interaction Flow

```
User: /ddd refactor anemic Order

Agent: ## Anemic Model Analysis: Order

I've analyzed the Order class and found:
- Business methods: 0
- Getters/Setters: 12
- Related service methods: 8

### Proposed Refactoring Plan

| Step | Action | Risk |
|------|--------|------|
| 1 | Move addItem() logic | Low |
| 2 | Move cancel() logic | Low |
| 3 | Add domain events | Medium |
| 4 | Update OrderService | Low |

Would you like me to guide you through Step 1?

User: Yes

Agent: ### Step 1: Move addItem() logic

**Current State** (OrderService.ts:45):
\`\`\`typescript
addItem(order: Order, item: OrderItem): void {
  order.items.push(item);
  order.total = this.calculateTotal(order);
}
\`\`\`

**Target State** (Order.ts):
\`\`\`typescript
addItem(item: OrderItem): void {
  this.ensureCanModify();
  this._items.push(item);
  this.addDomainEvent(new OrderItemAdded(this.id, item));
}

private ensureCanModify(): void {
  if (this.status !== OrderStatus.PENDING) {
    throw new OrderNotModifiableException(this.id);
  }
}

get total(): Money {
  return this._items.reduce(
    (sum, item) => sum.add(item.subtotal),
    Money.zero()
  );
}
\`\`\`

**Changes to make**:
1. Add `addItem` method to Order class
2. Add `ensureCanModify` guard
3. Change `total` to computed property
4. Update OrderService to delegate to Order

Ready to proceed? I'll help you make these changes.
```

## Safety Guidelines

The agent:

1. **Never auto-modifies** - Only guides, user makes changes
2. **Suggests incremental steps** - Small, verifiable changes
3. **Highlights risks** - Warns about breaking changes
4. **Considers tests** - Always mentions test updates needed
5. **Provides rollback info** - How to undo if needed

## Configuration

In `.ddd.yaml`:

```yaml
refactor_advisor:
  # Interaction style
  mode: interactive  # interactive | batch

  # Safety settings
  safety:
    require_tests: true  # Warn if no tests exist
    max_files_per_step: 3  # Limit changes per step
    require_confirmation: true  # Ask before each step

  # Code style
  style:
    use_project_patterns: true  # Match existing code style
    add_comments: false  # Don't add explanatory comments
```

## Integration with Health Monitor

When health check finds issues:

```markdown
### Critical: Anemic Model - Order

**Issue**: Order class has no business methods
**Impact**: Logic scattered in OrderService
**Fix**: `/ddd refactor anemic Order`

The refactor advisor can guide you through:
1. Moving addItem logic (5 min)
2. Moving cancel logic (5 min)
3. Adding domain events (10 min)
4. Cleaning up OrderService (5 min)
```
