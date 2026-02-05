# Domain Events

## Definition

A Domain Event represents something significant that happened in the domain. It captures the fact that something occurred, along with all the data necessary to describe what happened.

> "Domain Events are a way of capturing the things that happen in a system that domain experts care about."
> — Eric Evans

## Characteristics

| Property | Description |
|----------|-------------|
| **Immutable** | Once created, cannot be changed |
| **Past tense** | Named as something that happened |
| **Contains data** | Includes relevant state snapshot |
| **Timestamped** | When the event occurred |
| **Identity** | Unique event ID for tracking |

## Event Structure

```typescript
interface DomainEvent {
  readonly eventId: string;
  readonly occurredAt: Date;
  readonly aggregateId: string;
  readonly aggregateType: string;
}

class OrderCreated implements DomainEvent {
  readonly eventId: string;
  readonly occurredAt: Date;
  readonly aggregateId: string;
  readonly aggregateType = 'Order';

  constructor(
    readonly orderId: OrderId,
    readonly customerId: CustomerId,
    readonly items: OrderItemSnapshot[],
    readonly totalAmount: Money
  ) {
    this.eventId = uuid();
    this.occurredAt = new Date();
    this.aggregateId = orderId.value;
  }
}
```

## Naming Conventions

### Correct (Past Tense)
- `OrderCreated`
- `OrderCancelled`
- `PaymentReceived`
- `ItemAddedToCart`
- `CustomerAddressChanged`
- `InventoryReserved`

### Incorrect
- ❌ `CreateOrder` (command, not event)
- ❌ `OrderCreation` (noun, not past tense)
- ❌ `OrderEvent` (too generic)
- ❌ `HandleOrder` (verb, not fact)

## Event Coverage Analysis

### What to Measure

**Event Coverage** = (State-changing methods with events / Total state-changing methods) × 100

### Target Thresholds

| Coverage | Assessment |
|----------|------------|
| 0-25% | Critical - Most changes invisible |
| 25-50% | Low - Key changes missing events |
| 50-75% | Acceptable - Core events present |
| 75-100% | Good - Comprehensive eventing |

### Identifying State-Changing Methods

Methods that:
- Modify aggregate state
- Change entity values
- Transition status/state
- Add/remove from collections

```typescript
class Order {
  // State-changing - SHOULD emit event
  addItem(item: OrderItem): void {
    this.items.push(item);
    // ✅ Should emit OrderItemAdded
  }

  // State-changing - SHOULD emit event
  cancel(reason: string): void {
    this.status = OrderStatus.CANCELLED;
    // ✅ Should emit OrderCancelled
  }

  // NOT state-changing - No event needed
  get total(): Money {
    return this.calculateTotal();
  }

  // NOT state-changing - No event needed
  canCancel(): boolean {
    return this.status === OrderStatus.PENDING;
  }
}
```

## Event Emission Patterns

### Pattern 1: Collect and Dispatch

```typescript
abstract class AggregateRoot {
  private _domainEvents: DomainEvent[] = [];

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  pullDomainEvents(): DomainEvent[] {
    const events = [...this._domainEvents];
    this._domainEvents = [];
    return events;
  }
}

class Order extends AggregateRoot {
  cancel(reason: string): void {
    if (!this.canCancel()) {
      throw new CannotCancelException(this.id);
    }
    this.status = OrderStatus.CANCELLED;
    this.addDomainEvent(new OrderCancelled(this.id, reason));
  }
}

// Application service dispatches
class OrderApplicationService {
  async cancelOrder(orderId: string, reason: string): Promise<void> {
    const order = await this.orderRepo.findById(orderId);
    order.cancel(reason);

    await this.orderRepo.save(order);
    await this.eventPublisher.publish(order.pullDomainEvents());
  }
}
```

### Pattern 2: Event Sourcing

```typescript
class Order extends EventSourcedAggregate {
  cancel(reason: string): void {
    if (!this.canCancel()) {
      throw new CannotCancelException(this.id);
    }
    // State change happens through event
    this.apply(new OrderCancelled(this.id, reason));
  }

  // Event handler updates state
  protected onOrderCancelled(event: OrderCancelled): void {
    this.status = OrderStatus.CANCELLED;
  }
}
```

## Event Handler Patterns

### Eventual Consistency Across Aggregates

```typescript
// Order emits event
class Order {
  complete(): void {
    this.status = OrderStatus.COMPLETED;
    this.addDomainEvent(new OrderCompleted(this.id, this.items));
  }
}

// Handler updates Inventory aggregate
class InventoryDeductionHandler {
  async handle(event: OrderCompleted): Promise<void> {
    for (const item of event.items) {
      const stock = await this.inventoryRepo.findBySku(item.sku);
      stock.deduct(item.quantity);
      await this.inventoryRepo.save(stock);
    }
  }
}
```

### Cross-Context Communication

```typescript
// OrderContext emits
class OrderCompleted implements DomainEvent {
  // Contains only data needed by other contexts
  constructor(
    readonly orderId: string,
    readonly customerId: string,
    readonly totalAmount: number
  ) {}
}

// PaymentContext handles
class OrderCompletedPaymentHandler {
  async handle(event: OrderCompleted): Promise<void> {
    await this.billingService.createInvoice(
      event.customerId,
      event.totalAmount
    );
  }
}

// NotificationContext handles
class OrderCompletedNotificationHandler {
  async handle(event: OrderCompleted): Promise<void> {
    await this.emailService.sendOrderConfirmation(event.orderId);
  }
}
```

## Detection: Missing Events

### Signs of Missing Events

1. **State changes without events**
   ```typescript
   // ❌ No event for significant state change
   approve(): void {
     this.status = Status.APPROVED;
     // Missing: ApprovalGranted event
   }
   ```

2. **Cross-aggregate calls without events**
   ```typescript
   // ❌ Direct call instead of event
   completeOrder(): void {
     this.status = 'COMPLETED';
     this.inventoryService.deduct(this.items);  // Should be event
   }
   ```

3. **Audit requirements without events**
   - If business needs audit trail, events should capture changes

4. **Integration needs without events**
   - External systems need to know about changes

## Anti-Patterns

### 1. CRUD Events
```typescript
// ❌ Too generic, no business meaning
class OrderUpdated { }

// ✅ Specific business meaning
class OrderShipped { }
class OrderCancelled { }
class OrderItemQuantityChanged { }
```

### 2. Missing Event Data
```typescript
// ❌ Not enough context
class OrderCancelled {
  constructor(readonly orderId: string) {}
}

// ✅ Contains relevant snapshot
class OrderCancelled {
  constructor(
    readonly orderId: string,
    readonly customerId: string,
    readonly items: OrderItemSnapshot[],
    readonly totalAmount: Money,
    readonly reason: string,
    readonly cancelledAt: Date
  ) {}
}
```

### 3. Mutable Events
```typescript
// ❌ Event can be modified
class OrderCreated {
  orderId: string;  // Mutable
  setOrderId(id: string) { this.orderId = id; }
}

// ✅ Immutable
class OrderCreated {
  readonly orderId: string;
  constructor(orderId: string) {
    this.orderId = orderId;
  }
}
```

## References

- [Martin Fowler - Domain Event](https://martinfowler.com/eaaDev/DomainEvent.html)
- [Udi Dahan - Domain Events](https://udidahan.com/2009/06/14/domain-events-salvation/)
- [Greg Young - Event Sourcing](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf)
