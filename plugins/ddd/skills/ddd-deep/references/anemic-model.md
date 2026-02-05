# Anemic Domain Model Detection

## Definition

An Anemic Domain Model is a domain model where domain objects contain little or no business logic. The objects are essentially data containers (DTOs) with getters and setters, while all business logic resides in service classes.

> "The fundamental horror of this anti-pattern is that it's so contrary to the basic idea of object-oriented design; which is to combine data and process together."
> — Martin Fowler

## Why It's Problematic

1. **Violates encapsulation** - Data and behavior are separated
2. **Leads to procedural code** - Despite using objects
3. **Duplicates logic** - Same rules implemented in multiple services
4. **Loses invariant protection** - Objects can be put in invalid states
5. **Makes refactoring harder** - Logic scattered across services

## Detection Criteria

### Primary Indicators

| Indicator | Detection Method | Severity |
|-----------|------------------|----------|
| No business methods | Count methods excluding getters/setters | High |
| All public fields | Check field visibility | High |
| All fields have setters | Check for setter methods | High |
| No validation in class | Search for validation logic | Medium |
| No domain events | Check for event emission | Medium |

### Code Patterns to Detect

**Anemic class characteristics**:
```typescript
// ANEMIC - Red flags
class Order {
  // ❌ All fields exposed
  public id: string;
  public items: OrderItem[];
  public status: string;
  public total: number;

  // ❌ Only getters/setters
  getId(): string { return this.id; }
  setId(id: string): void { this.id = id; }
  getItems(): OrderItem[] { return this.items; }
  setItems(items: OrderItem[]): void { this.items = items; }
  getStatus(): string { return this.status; }
  setStatus(status: string): void { this.status = status; }
  getTotal(): number { return this.total; }
  setTotal(total: number): void { this.total = total; }

  // ❌ No business methods
  // ❌ No validation
  // ❌ No invariant enforcement
}
```

**Corresponding Transaction Script**:
```typescript
// Transaction Script - Logic separated from data
class OrderService {
  addItem(order: Order, item: OrderItem): void {
    // ❌ Logic that should be in Order
    order.getItems().push(item);
    order.setTotal(this.calculateTotal(order));
  }

  cancel(order: Order): void {
    // ❌ Validation outside the domain object
    if (order.getStatus() !== 'PENDING') {
      throw new Error('Cannot cancel');
    }
    order.setStatus('CANCELLED');
  }

  calculateTotal(order: Order): number {
    return order.getItems().reduce((sum, item) => sum + item.price, 0);
  }
}
```

### Metrics

| Metric | Anemic Threshold | Healthy Threshold |
|--------|------------------|-------------------|
| Business methods | 0-1 | 3+ |
| Getter/Setter ratio | >80% | <30% |
| Public fields | Any | None |
| Validation methods | 0 | 1+ |
| Domain events raised | 0 | Per state change |

## Rich Domain Model Characteristics

**Healthy domain class**:
```typescript
// RICH - Domain logic encapsulated
class Order {
  // ✅ Private fields
  private readonly id: OrderId;
  private items: OrderItem[];
  private status: OrderStatus;

  // ✅ Factory method with validation
  static create(customerId: CustomerId, items: OrderItem[]): Order {
    if (items.length === 0) {
      throw new EmptyOrderException();
    }
    const order = new Order(OrderId.generate(), customerId, items);
    order.addDomainEvent(new OrderCreated(order.id));
    return order;
  }

  // ✅ Business method with invariant enforcement
  addItem(item: OrderItem): void {
    this.ensureCanModify();
    this.items.push(item);
    this.addDomainEvent(new OrderItemAdded(this.id, item.id));
  }

  // ✅ Behavior encapsulated
  cancel(reason: string): void {
    if (!this.canCancel()) {
      throw new OrderCannotBeCancelledException(this.id);
    }
    this.status = OrderStatus.CANCELLED;
    this.addDomainEvent(new OrderCancelled(this.id, reason));
  }

  // ✅ Computed property instead of stored data
  get total(): Money {
    return this.items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.zero()
    );
  }

  // ✅ Private validation
  private canCancel(): boolean {
    return this.status === OrderStatus.PENDING;
  }

  private ensureCanModify(): void {
    if (this.status !== OrderStatus.PENDING) {
      throw new OrderNotModifiableException(this.id);
    }
  }
}
```

## Detection Algorithm

```
For each domain class:
  1. Count total methods
  2. Count getter methods (getName, getId, etc.)
  3. Count setter methods (setName, setId, etc.)
  4. Count business methods = total - getters - setters - constructors
  5. Check if any field is public or has public setter
  6. Search for validation/guard clauses
  7. Check for domain event emission

  If business_methods < 2 AND (has_public_setters OR getter_setter_ratio > 0.8):
    Flag as ANEMIC
    Severity: CRITICAL if related Service has >10 methods manipulating this class
```

## Related Patterns

- **Transaction Script** - Where logic goes when domain is anemic
- **God Class** - Service that accumulates too much anemic logic
- **Feature Envy** - Service methods that use other class's data heavily

## References

- [Martin Fowler - Anemic Domain Model](https://martinfowler.com/bliki/AnemicDomainModel.html)
- [Eric Evans - Domain-Driven Design](https://www.domainlanguage.com/ddd/)
- [Vladimir Khorikov - Anemic Domain Model vs Rich Domain Model](https://enterprisecraftsmanship.com/posts/anemic-domain-model-vs-rich-domain-model/)
