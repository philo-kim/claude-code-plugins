# Aggregate Design Rules

## Core Concept

An Aggregate is a cluster of domain objects that can be treated as a single unit. The Aggregate has a root entity (Aggregate Root) that controls all access to objects within the boundary.

> "A cluster of associated objects that we treat as a unit for the purpose of data changes."
> — Eric Evans

## Vernon's Four Rules of Aggregate Design

Vaughn Vernon distilled aggregate design into four essential rules:

### Rule 1: Protect Business Invariants Inside Aggregate Boundaries

**Principle**: The aggregate is responsible for maintaining consistency of business rules.

**Detection criteria**:
- Invariant checks should be INSIDE the aggregate
- External services should NOT validate aggregate state
- Aggregate methods should reject invalid operations

**Violation example**:
```typescript
// ❌ Invariant checked outside aggregate
class OrderService {
  addItem(order: Order, item: OrderItem): void {
    // Validation outside aggregate
    if (order.items.length >= 100) {
      throw new Error('Too many items');
    }
    order.items.push(item);
  }
}

// ✅ Invariant protected inside aggregate
class Order {
  private static readonly MAX_ITEMS = 100;

  addItem(item: OrderItem): void {
    if (this.items.length >= Order.MAX_ITEMS) {
      throw new TooManyItemsException(this.id);
    }
    this.items.push(item);
  }
}
```

### Rule 2: Design Small Aggregates

**Principle**: Keep aggregates as small as possible while still protecting invariants.

**Statistics**:
- ~70% of aggregates should contain only the root entity
- Large aggregates indicate possible design problems

**Size thresholds**:
| Metric | Acceptable | Warning | Critical |
|--------|------------|---------|----------|
| Entities in aggregate | 1-2 | 3-4 | 5+ |
| Root class lines | <300 | 300-500 | >500 |
| Methods in root | <15 | 15-25 | >25 |

**Why small**:
- Reduces contention in concurrent systems
- Improves performance
- Simplifies reasoning about invariants
- Easier to test

**Violation example**:
```typescript
// ❌ Too large - Order contains too much
class Order {
  id: OrderId;
  items: OrderItem[];           // Could be separate
  customer: Customer;           // Should be reference
  payment: Payment;             // Should be separate aggregate
  shipping: ShippingInfo;       // Should be separate aggregate
  invoice: Invoice;             // Should be separate aggregate
  reviews: Review[];            // Should be separate aggregate
}

// ✅ Small aggregate - Order focuses on ordering
class Order {
  private id: OrderId;
  private customerId: CustomerId;  // Reference by ID
  private items: OrderItem[];      // Part of Order invariants
  private status: OrderStatus;
}
```

### Rule 3: Reference Other Aggregates by Identity Only

**Principle**: Don't hold direct object references to other aggregates.

**Why**:
- Prevents accidental modification of other aggregates
- Enables eventual consistency
- Reduces memory footprint
- Clear transaction boundaries

**Detection**:
```typescript
// ❌ Direct object reference
class Order {
  customer: Customer;        // Holds entire Customer object
  payment: Payment;          // Holds entire Payment object
}

// ✅ Identity reference only
class Order {
  customerId: CustomerId;    // Just the ID
  paymentId?: PaymentId;     // Just the ID
}
```

**When to load related aggregate**:
```typescript
class OrderApplicationService {
  async processOrder(orderId: string): Promise<void> {
    const order = await this.orderRepo.findById(OrderId.from(orderId));

    // Load related aggregate when needed
    const customer = await this.customerRepo.findById(order.customerId);

    // Don't modify customer in same transaction
    // Use events instead
  }
}
```

### Rule 4: Update Other Aggregates Using Eventual Consistency

**Principle**: Use domain events to update related aggregates.

**Why**:
- Single aggregate per transaction
- Decouples aggregates
- Enables scalability
- Matches real business processes

**Pattern**:
```typescript
// Order emits event
class Order {
  complete(): void {
    this.status = OrderStatus.COMPLETED;
    this.addDomainEvent(new OrderCompleted(this.id, this.items));
  }
}

// Inventory updated via event handler
class OrderCompletedHandler {
  async handle(event: OrderCompleted): Promise<void> {
    for (const item of event.items) {
      const inventory = await this.inventoryRepo.findBySku(item.sku);
      inventory.deduct(item.quantity);
      await this.inventoryRepo.save(inventory);
    }
  }
}
```

## Extended Rules

### Rule 5: Make Aggregates Functionally Cohesive

**Principle**: Group entities that truly belong together based on invariants.

**Questions to ask**:
- Do these entities share invariants?
- Must they change together atomically?
- Does the business require immediate consistency?

### Rule 6: Avoid Aggregate References from Entities

**Principle**: Entities within an aggregate should not reference external aggregates.

```typescript
// ❌ Entity references external aggregate
class OrderItem {
  product: Product;  // References Product aggregate
}

// ✅ Entity uses ID reference
class OrderItem {
  productId: ProductId;
  productName: string;     // Snapshot of data at order time
  productPrice: Money;     // Snapshot of price at order time
}
```

### Rule 7: Document Your Invariants

**Principle**: Each aggregate should have documented business rules.

```typescript
/**
 * Order Aggregate
 *
 * Invariants:
 * 1. Order must have at least one item
 * 2. Order total must equal sum of item totals
 * 3. Order cannot be modified after shipping
 * 4. Order can only be cancelled if status is PENDING
 * 5. Maximum 100 items per order
 */
class Order {
  // ...
}
```

## Detection Checklist

| Check | Pass | Fail |
|-------|------|------|
| Invariants enforced inside | Methods validate before change | Service validates |
| Size is appropriate | 1-3 entities | 4+ entities |
| References by ID | Uses `CustomerId` | Uses `Customer` object |
| Single aggregate per transaction | Uses events | Modifies multiple aggregates |
| Cohesive entities | Share invariants | Unrelated data grouped |

## Anti-Patterns

### 1. Mega Aggregate
Everything in one aggregate for "convenience"

### 2. Anemic Aggregate
Root has no behavior, just holds entities

### 3. Cross-Aggregate Transaction
One service method modifies multiple aggregates

### 4. Reference Spaghetti
Aggregates holding references to each other

## References

- [Vaughn Vernon - Effective Aggregate Design](https://www.dddcommunity.org/library/vernon_2011/)
- [Vaughn Vernon - Implementing Domain-Driven Design](https://www.oreilly.com/library/view/implementing-domain-driven-design/9780133039900/)
- [James Hickey - DDD Aggregates: Consistency Boundary](https://www.jamesmichaelhickey.com/consistency-boundary/)
