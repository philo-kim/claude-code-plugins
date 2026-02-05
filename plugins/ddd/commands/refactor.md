# /ddd refactor

Get refactoring guides for DDD improvements.

## Purpose

This command provides **guidance** for refactoring code to follow DDD principles. It does NOT automatically modify code - it shows the path forward and can assist you through the refactoring process.

## Usage

```
/ddd refactor <type> [target]
```

Types:
- `anemic <class>` - Convert Anemic Domain Model to Rich Model
- `split <service>` - Break up God Class / Transaction Script
- `extract-vo <class>` - Extract Value Objects from class
- `add-event <aggregate>` - Add Domain Events to aggregate
- `fix-layer <class>` - Fix layer architecture violations
- `extract-aggregate <class>` - Extract new aggregate from existing one

## Refactoring Guides

### `/ddd refactor anemic <class>`

Convert an Anemic Domain Model to a Rich Domain Model.

**Analysis Phase**:
```markdown
## Anemic Model Analysis: Order

### Current State
- **File**: src/order/Order.ts
- **Business Methods**: 0
- **Getter/Setters**: 12
- **Fields**: id, items, status, customerId, total, createdAt, updatedAt

### Related Logic (found in services)

| Service | Method | Logic | Should Move To |
|---------|--------|-------|----------------|
| OrderService | addItem() | Adds item, recalculates total | Order |
| OrderService | removeItem() | Removes item, recalculates total | Order |
| OrderService | cancel() | Validates status, sets cancelled | Order |
| OrderService | calculateTotal() | Sums item prices | Order |
| OrderValidator | validate() | Checks order validity | Order |
```

**Refactoring Guide**:
```markdown
### Step 1: Identify Invariants

Business rules that Order must enforce:
1. Order cannot be modified after shipping
2. Total must equal sum of items
3. Order must have at least one item
4. Status transitions follow specific rules

### Step 2: Move Behavior to Domain Object

**Before** (Anemic):
\`\`\`typescript
// Order.ts - data only
class Order {
  id: string;
  items: OrderItem[];
  status: OrderStatus;
  total: number;
}

// OrderService.ts - logic here
class OrderService {
  addItem(order: Order, item: OrderItem) {
    order.items.push(item);
    order.total = this.calculateTotal(order);
  }

  cancel(order: Order) {
    if (order.status !== 'PENDING') {
      throw new Error('Cannot cancel');
    }
    order.status = 'CANCELLED';
  }
}
\`\`\`

**After** (Rich Domain Model):
\`\`\`typescript
// Order.ts - behavior lives here
class Order {
  private readonly id: OrderId;
  private items: OrderItem[];
  private status: OrderStatus;

  // Constructor enforces invariants
  private constructor(id: OrderId, items: OrderItem[]) {
    if (items.length === 0) {
      throw new EmptyOrderException();
    }
    this.id = id;
    this.items = items;
    this.status = OrderStatus.PENDING;
  }

  // Factory method
  static create(items: OrderItem[]): Order {
    return new Order(OrderId.generate(), items);
  }

  // Behavior encapsulated
  addItem(item: OrderItem): void {
    this.ensureCanModify();
    this.items.push(item);
    // Emit event
    this.addDomainEvent(new OrderItemAdded(this.id, item.id));
  }

  cancel(): void {
    if (!this.canCancel()) {
      throw new OrderCannotBeCancelledException(this.id);
    }
    this.status = OrderStatus.CANCELLED;
    this.addDomainEvent(new OrderCancelled(this.id));
  }

  // Computed property
  get total(): Money {
    return this.items.reduce(
      (sum, item) => sum.add(item.price),
      Money.zero()
    );
  }

  // Private helpers
  private canCancel(): boolean {
    return this.status === OrderStatus.PENDING;
  }

  private ensureCanModify(): void {
    if (this.status !== OrderStatus.PENDING) {
      throw new OrderNotModifiableException(this.id);
    }
  }
}
\`\`\`

### Step 3: Update Service Layer

**After** (Thin Application Service):
\`\`\`typescript
// OrderApplicationService.ts - orchestration only
class OrderApplicationService {
  constructor(
    private orderRepository: OrderRepository,
    private eventPublisher: DomainEventPublisher
  ) {}

  async addItem(orderId: string, itemDto: ItemDto): Promise<void> {
    const order = await this.orderRepository.findById(OrderId.from(orderId));
    const item = OrderItem.create(itemDto);

    order.addItem(item);  // Domain logic in Order

    await this.orderRepository.save(order);
    await this.eventPublisher.publish(order.pullDomainEvents());
  }
}
\`\`\`

### Step 4: Impact Assessment

**Files to Modify**:
- `src/order/Order.ts` - Add business methods
- `src/order/OrderService.ts` - Remove domain logic
- `src/order/OrderItem.ts` - Ensure immutability

**Tests to Update**:
- `Order.test.ts` - Add behavior tests
- `OrderService.test.ts` - Update to test orchestration

### Would you like to proceed?

I can guide you through each step interactively.
```

---

### `/ddd refactor split <service>`

Break up a God Class / Transaction Script.

**Analysis Phase**:
```markdown
## Transaction Script Analysis: OrderService

### Current State
- **File**: src/services/OrderService.ts
- **Lines**: 847
- **Methods**: 32
- **Dependencies**: 8 repositories, 5 external services

### Method Groupings (by cohesion)

| Group | Methods | Suggested Destination |
|-------|---------|----------------------|
| Order Lifecycle | create, cancel, complete | Order aggregate |
| Payment | processPayment, refund, validatePayment | PaymentService or Order |
| Shipping | calculateShipping, scheduleDelivery | ShippingService |
| Notification | sendConfirmation, sendShippedEmail | NotificationService |
| Reporting | getOrderStats, generateReport | OrderQueryService |
```

**Refactoring Guide**:
```markdown
### Recommended Split

\`\`\`
OrderService (847 lines)
         │
         ├──> Order aggregate (domain logic)
         │    - addItem, removeItem, cancel
         │    - status transitions
         │    - invariant validation
         │
         ├──> OrderApplicationService (orchestration)
         │    - createOrder, processOrder
         │    - coordinate across aggregates
         │
         ├──> PaymentApplicationService
         │    - processPayment, handleRefund
         │
         ├──> ShippingApplicationService
         │    - calculateShipping, scheduleDelivery
         │
         ├──> NotificationService (infrastructure)
         │    - sendConfirmation, sendShippedEmail
         │
         └──> OrderQueryService (CQRS read side)
              - getOrderStats, generateReport
\`\`\`

### Step-by-Step Approach

1. **Extract domain logic to aggregates first**
   - Move validation, state changes to Order
   - Keep services as thin orchestrators

2. **Identify bounded context boundaries**
   - Payment might be separate context
   - Shipping might be separate context

3. **Use Domain Events for cross-concern**
   - OrderCreated → triggers notification
   - OrderPaid → triggers shipping

### Example Extraction

**Before**:
\`\`\`typescript
class OrderService {
  async createOrder(dto: CreateOrderDto) {
    // Validation
    this.validateItems(dto.items);
    this.validateCustomer(dto.customerId);

    // Creation
    const order = new Order();
    order.items = dto.items;
    order.customerId = dto.customerId;
    order.status = 'PENDING';
    order.total = this.calculateTotal(dto.items);

    await this.orderRepo.save(order);

    // Side effects
    await this.emailService.sendConfirmation(order);
    await this.inventoryService.reserve(order.items);
    await this.analyticsService.track('order_created', order);

    return order;
  }
}
\`\`\`

**After**:
\`\`\`typescript
// Order.ts (domain)
class Order {
  static create(customerId: CustomerId, items: OrderItem[]): Order {
    const order = new Order(OrderId.generate(), customerId, items);
    order.addDomainEvent(new OrderCreated(order.id, customerId, items));
    return order;
  }
}

// OrderApplicationService.ts (application)
class OrderApplicationService {
  async createOrder(dto: CreateOrderDto): Promise<OrderId> {
    const items = dto.items.map(i => OrderItem.create(i));
    const order = Order.create(CustomerId.from(dto.customerId), items);

    await this.orderRepo.save(order);
    await this.eventPublisher.publish(order.pullDomainEvents());

    return order.id;
  }
}

// Event handlers (infrastructure)
class OrderCreatedHandler {
  async handle(event: OrderCreated) {
    await this.emailService.sendConfirmation(event);
  }
}

class InventoryReservationHandler {
  async handle(event: OrderCreated) {
    await this.inventoryService.reserve(event.items);
  }
}
\`\`\`
```

---

### `/ddd refactor extract-vo <class>`

Extract Value Objects from a class.

**Analysis**:
```markdown
## Value Object Extraction: Order

### Candidates for Value Objects

| Field(s) | Suggested VO | Reason |
|----------|--------------|--------|
| total, currency | Money | Represents monetary value |
| street, city, zip, country | Address | Cohesive address concept |
| email | Email | Has validation rules |
| phone | PhoneNumber | Has formatting rules |
| quantity, unit | Quantity | Quantity with unit |

### Extraction Guide

**Before**:
\`\`\`typescript
class Order {
  totalAmount: number;
  currency: string;
  shippingStreet: string;
  shippingCity: string;
  shippingZip: string;
  shippingCountry: string;
}
\`\`\`

**After**:
\`\`\`typescript
class Money {
  private constructor(
    readonly amount: number,
    readonly currency: Currency
  ) {
    if (amount < 0) throw new InvalidMoneyException();
  }

  static of(amount: number, currency: Currency): Money {
    return new Money(amount, currency);
  }

  add(other: Money): Money {
    this.ensureSameCurrency(other);
    return Money.of(this.amount + other.amount, this.currency);
  }

  equals(other: Money): boolean {
    return this.amount === other.amount &&
           this.currency === other.currency;
  }
}

class Address {
  private constructor(
    readonly street: string,
    readonly city: string,
    readonly zip: string,
    readonly country: Country
  ) {}

  static create(street: string, city: string, zip: string, country: Country): Address {
    // Validation
    return new Address(street, city, zip, country);
  }
}

class Order {
  private total: Money;
  private shippingAddress: Address;
}
\`\`\`
```

---

### `/ddd refactor add-event <aggregate>`

Add Domain Events to an aggregate.

**Analysis**:
```markdown
## Domain Event Analysis: Order

### State-Changing Methods Without Events

| Method | State Change | Suggested Event |
|--------|--------------|-----------------|
| create() | New order | OrderCreated |
| addItem() | Items modified | OrderItemAdded |
| removeItem() | Items modified | OrderItemRemoved |
| cancel() | Status → Cancelled | OrderCancelled |
| ship() | Status → Shipped | OrderShipped |
| complete() | Status → Completed | OrderCompleted |

### Implementation Guide

\`\`\`typescript
// Domain Events
class OrderCreated implements DomainEvent {
  constructor(
    readonly orderId: OrderId,
    readonly customerId: CustomerId,
    readonly items: OrderItemSnapshot[],
    readonly occurredAt: Date = new Date()
  ) {}
}

class OrderCancelled implements DomainEvent {
  constructor(
    readonly orderId: OrderId,
    readonly reason: string,
    readonly occurredAt: Date = new Date()
  ) {}
}

// Aggregate with events
class Order extends AggregateRoot {
  cancel(reason: string): void {
    if (!this.canCancel()) {
      throw new OrderCannotBeCancelledException(this.id);
    }
    this.status = OrderStatus.CANCELLED;

    // Record event
    this.addDomainEvent(new OrderCancelled(this.id, reason));
  }
}

// Base class
abstract class AggregateRoot {
  private domainEvents: DomainEvent[] = [];

  protected addDomainEvent(event: DomainEvent): void {
    this.domainEvents.push(event);
  }

  pullDomainEvents(): DomainEvent[] {
    const events = [...this.domainEvents];
    this.domainEvents = [];
    return events;
  }
}
\`\`\`
```

---

### `/ddd refactor fix-layer <class>`

Fix layer architecture violations.

**Analysis**:
```markdown
## Layer Violation Analysis: Order.ts

### Violations Found

| Line | Import | Issue |
|------|--------|-------|
| 2 | typeorm | ORM in domain |
| 5 | @nestjs/common | Framework in domain |
| 8 | axios | HTTP client in domain |

### Fix Strategy

**Current** (polluted domain):
\`\`\`typescript
import { Entity, Column } from 'typeorm';
import { Injectable } from '@nestjs/common';

@Entity()
@Injectable()
class Order {
  @Column()
  id: string;

  @Column('json')
  items: OrderItem[];
}
\`\`\`

**After** (clean domain):
\`\`\`typescript
// src/domain/order/Order.ts - Pure domain
class Order {
  private readonly id: OrderId;
  private items: OrderItem[];

  // Pure business logic, no framework
}

// src/infrastructure/persistence/OrderEntity.ts - ORM mapping
import { Entity, Column } from 'typeorm';

@Entity('orders')
class OrderEntity {
  @PrimaryColumn()
  id: string;

  @Column('json')
  items: any;
}

// src/infrastructure/persistence/OrderMapper.ts
class OrderMapper {
  toDomain(entity: OrderEntity): Order {
    return Order.reconstitute(
      OrderId.from(entity.id),
      entity.items.map(i => OrderItem.reconstitute(i))
    );
  }

  toEntity(order: Order): OrderEntity {
    const entity = new OrderEntity();
    entity.id = order.id.value;
    entity.items = order.items.map(i => i.toSnapshot());
    return entity;
  }
}
\`\`\`
```

## Interactive Mode

When you run a refactor command, I'll:

1. **Analyze** the current state
2. **Present** the refactoring plan
3. **Ask** if you want to proceed
4. **Guide** you through each step
5. **Verify** after each change

This ensures you understand and control every change.
