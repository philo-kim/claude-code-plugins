# TypeScript DDD Patterns

Implementation patterns for Domain-Driven Design in TypeScript projects.

## Project Structure

```
src/
├── domain/                    # Pure domain layer
│   ├── order/
│   │   ├── Order.ts          # Aggregate root
│   │   ├── OrderItem.ts      # Entity
│   │   ├── OrderId.ts        # Value object (identity)
│   │   ├── OrderStatus.ts    # Value object (enum)
│   │   ├── OrderRepository.ts # Repository interface
│   │   └── events/
│   │       ├── OrderCreated.ts
│   │       └── OrderCancelled.ts
│   └── shared/
│       ├── Entity.ts         # Base entity
│       ├── AggregateRoot.ts  # Base aggregate
│       ├── ValueObject.ts    # Base value object
│       └── DomainEvent.ts    # Event interface
│
├── application/              # Application services
│   └── order/
│       ├── CreateOrderHandler.ts
│       └── dto/
│           └── CreateOrderDto.ts
│
└── infrastructure/           # Technical implementations
    ├── persistence/
    │   ├── TypeOrmOrderRepository.ts
    │   └── entities/
    │       └── OrderEntity.ts
    └── adapters/
        └── StripePaymentAdapter.ts
```

## Core Building Blocks

### Aggregate Root

```typescript
// domain/order/Order.ts
import { AggregateRoot } from '../shared/AggregateRoot';
import { OrderId } from './OrderId';
import { OrderItem } from './OrderItem';
import { OrderStatus } from './OrderStatus';
import { Money } from '../shared/Money';
import { OrderCreated } from './events/OrderCreated';
import { OrderCancelled } from './events/OrderCancelled';

export class Order extends AggregateRoot<OrderId> {
  private items: OrderItem[];
  private status: OrderStatus;
  private readonly customerId: CustomerId;

  private constructor(
    id: OrderId,
    customerId: CustomerId,
    items: OrderItem[]
  ) {
    super(id);
    this.customerId = customerId;
    this.items = items;
    this.status = OrderStatus.PENDING;
  }

  // Factory method
  static create(customerId: CustomerId, items: OrderItem[]): Order {
    if (items.length === 0) {
      throw new EmptyOrderException();
    }

    const order = new Order(OrderId.generate(), customerId, items);
    order.addDomainEvent(new OrderCreated(order.id, customerId, items));
    return order;
  }

  // Reconstitute from persistence (no events)
  static reconstitute(
    id: OrderId,
    customerId: CustomerId,
    items: OrderItem[],
    status: OrderStatus
  ): Order {
    const order = new Order(id, customerId, items);
    order.status = status;
    return order;
  }

  // Business methods
  addItem(item: OrderItem): void {
    this.ensureCanModify();
    this.items.push(item);
    this.addDomainEvent(new OrderItemAdded(this.id, item));
  }

  cancel(reason: string): void {
    if (!this.canCancel()) {
      throw new OrderCannotBeCancelledException(this.id, this.status);
    }
    this.status = OrderStatus.CANCELLED;
    this.addDomainEvent(new OrderCancelled(this.id, reason));
  }

  // Computed property
  get total(): Money {
    return this.items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.zero()
    );
  }

  // Query methods
  canCancel(): boolean {
    return this.status === OrderStatus.PENDING;
  }

  // Private invariant enforcement
  private ensureCanModify(): void {
    if (this.status !== OrderStatus.PENDING) {
      throw new OrderNotModifiableException(this.id);
    }
  }
}
```

### Base Aggregate Root

```typescript
// domain/shared/AggregateRoot.ts
import { Entity } from './Entity';
import { DomainEvent } from './DomainEvent';

export abstract class AggregateRoot<TId> extends Entity<TId> {
  private _domainEvents: DomainEvent[] = [];

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  pullDomainEvents(): DomainEvent[] {
    const events = [...this._domainEvents];
    this._domainEvents = [];
    return events;
  }

  get domainEvents(): readonly DomainEvent[] {
    return this._domainEvents;
  }
}
```

### Value Object

```typescript
// domain/shared/ValueObject.ts
export abstract class ValueObject<T> {
  protected readonly props: T;

  protected constructor(props: T) {
    this.props = Object.freeze(props);
  }

  equals(other: ValueObject<T>): boolean {
    if (other === null || other === undefined) {
      return false;
    }
    return JSON.stringify(this.props) === JSON.stringify(other.props);
  }
}

// domain/shared/Money.ts
interface MoneyProps {
  amount: number;
  currency: string;
}

export class Money extends ValueObject<MoneyProps> {
  private constructor(props: MoneyProps) {
    super(props);
  }

  static of(amount: number, currency: string = 'USD'): Money {
    if (amount < 0) {
      throw new InvalidMoneyException(amount);
    }
    return new Money({ amount, currency });
  }

  static zero(currency: string = 'USD'): Money {
    return new Money({ amount: 0, currency });
  }

  get amount(): number {
    return this.props.amount;
  }

  get currency(): string {
    return this.props.currency;
  }

  add(other: Money): Money {
    this.ensureSameCurrency(other);
    return Money.of(this.amount + other.amount, this.currency);
  }

  subtract(other: Money): Money {
    this.ensureSameCurrency(other);
    const result = this.amount - other.amount;
    if (result < 0) {
      throw new InsufficientFundsException();
    }
    return Money.of(result, this.currency);
  }

  private ensureSameCurrency(other: Money): void {
    if (this.currency !== other.currency) {
      throw new CurrencyMismatchException(this.currency, other.currency);
    }
  }
}
```

### Identity Value Object

```typescript
// domain/order/OrderId.ts
import { v4 as uuid, validate } from 'uuid';

export class OrderId {
  private constructor(private readonly _value: string) {}

  static generate(): OrderId {
    return new OrderId(uuid());
  }

  static from(value: string): OrderId {
    if (!validate(value)) {
      throw new InvalidOrderIdException(value);
    }
    return new OrderId(value);
  }

  get value(): string {
    return this._value;
  }

  equals(other: OrderId): boolean {
    return this._value === other._value;
  }

  toString(): string {
    return this._value;
  }
}
```

### Domain Event

```typescript
// domain/shared/DomainEvent.ts
export interface DomainEvent {
  readonly eventId: string;
  readonly occurredAt: Date;
  readonly aggregateId: string;
}

// domain/order/events/OrderCreated.ts
import { v4 as uuid } from 'uuid';

export class OrderCreated implements DomainEvent {
  readonly eventId: string;
  readonly occurredAt: Date;
  readonly aggregateId: string;

  constructor(
    readonly orderId: OrderId,
    readonly customerId: CustomerId,
    readonly items: OrderItemSnapshot[]
  ) {
    this.eventId = uuid();
    this.occurredAt = new Date();
    this.aggregateId = orderId.value;
  }
}
```

### Repository Interface

```typescript
// domain/order/OrderRepository.ts
export interface OrderRepository {
  findById(id: OrderId): Promise<Order | null>;
  findByCustomer(customerId: CustomerId): Promise<Order[]>;
  findPending(): Promise<Order[]>;
  save(order: Order): Promise<void>;
  delete(order: Order): Promise<void>;
}
```

### Repository Implementation

```typescript
// infrastructure/persistence/TypeOrmOrderRepository.ts
import { Repository } from 'typeorm';
import { OrderRepository } from '../../domain/order/OrderRepository';
import { Order } from '../../domain/order/Order';
import { OrderEntity } from './entities/OrderEntity';
import { OrderMapper } from './OrderMapper';

export class TypeOrmOrderRepository implements OrderRepository {
  constructor(
    private readonly ormRepo: Repository<OrderEntity>,
    private readonly mapper: OrderMapper
  ) {}

  async findById(id: OrderId): Promise<Order | null> {
    const entity = await this.ormRepo.findOne({
      where: { id: id.value },
      relations: ['items']
    });

    if (!entity) return null;
    return this.mapper.toDomain(entity);
  }

  async save(order: Order): Promise<void> {
    const entity = this.mapper.toEntity(order);
    await this.ormRepo.save(entity);
  }

  // ... other methods
}
```

## NestJS Integration

### Clean Domain with NestJS

```typescript
// ❌ Avoid: NestJS decorators in domain
import { Injectable } from '@nestjs/common';

@Injectable()  // ❌ Framework in domain
export class OrderService {
  // ...
}

// ✅ Correct: Framework only in infrastructure/application
// domain/order/Order.ts - Pure, no decorators
export class Order {
  // Pure domain logic
}

// application/order/CreateOrderHandler.ts
import { Injectable } from '@nestjs/common';

@Injectable()  // ✅ OK in application layer
export class CreateOrderHandler {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly eventPublisher: DomainEventPublisher
  ) {}

  async execute(command: CreateOrderCommand): Promise<OrderId> {
    const order = Order.create(
      CustomerId.from(command.customerId),
      command.items.map(i => OrderItem.create(i))
    );

    await this.orderRepository.save(order);
    await this.eventPublisher.publish(order.pullDomainEvents());

    return order.id;
  }
}
```

### Module Structure

```typescript
// infrastructure/order/order.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [TypeOrmModule.forFeature([OrderEntity])],
  providers: [
    CreateOrderHandler,
    {
      provide: 'OrderRepository',
      useClass: TypeOrmOrderRepository,
    },
  ],
  exports: [CreateOrderHandler],
})
export class OrderModule {}
```

## Common Pitfalls

### 1. Decorators in Domain
```typescript
// ❌ Bad
@Entity()
@Injectable()
export class Order { }

// ✅ Good
export class Order { }  // Pure
```

### 2. Exposing Internals
```typescript
// ❌ Bad
class Order {
  public items: OrderItem[];  // Can be modified externally
}

// ✅ Good
class Order {
  private items: OrderItem[];

  getItems(): readonly OrderItem[] {
    return [...this.items];
  }
}
```

### 3. Anemic Validation
```typescript
// ❌ Bad - Validation outside domain
class OrderService {
  createOrder(dto: CreateOrderDto) {
    if (dto.items.length === 0) throw new Error();
    // ...
  }
}

// ✅ Good - Validation inside domain
class Order {
  static create(customerId: CustomerId, items: OrderItem[]): Order {
    if (items.length === 0) throw new EmptyOrderException();
    // ...
  }
}
```

## Detection Patterns

| Pattern | Detection |
|---------|-----------|
| Aggregate Root | Class with `extends AggregateRoot` or contains entities |
| Value Object | Class with `extends ValueObject` or immutable with equals |
| Domain Event | Class implementing `DomainEvent` or ending in `Event` |
| Repository | Interface with `findBy*`, `save`, `delete` methods |
| Anemic Model | Class with only getters/setters, no business methods |
| Layer Violation | Import from `@nestjs`, `typeorm` in domain folder |
