# Layer Architecture and Domain Independence

## Core Principle

The domain layer must be independent of all technical concerns. It should contain only business logic and be expressible in pure programming language constructs without framework dependencies.

> "The domain layer is the heart of business software."
> — Eric Evans

## Layer Responsibilities

### Domain Layer
**Purpose**: Pure business logic and rules

**Contains**:
- Entities and Aggregate Roots
- Value Objects
- Domain Events
- Domain Services
- Repository Interfaces (not implementations)
- Factory interfaces

**Must NOT contain**:
- Framework annotations
- Database concerns (ORM, SQL)
- HTTP concerns (controllers, DTOs)
- External service calls
- Logging frameworks
- Serialization logic

### Application Layer
**Purpose**: Orchestrates domain objects to perform use cases

**Contains**:
- Application Services (use case handlers)
- Command/Query handlers
- DTOs for input/output
- Transaction management
- Event publishing

### Infrastructure Layer
**Purpose**: Technical implementations

**Contains**:
- Repository implementations
- ORM entities and mapping
- External service adapters
- Message queue handlers
- Framework configuration

## Dependency Rule

```
Presentation → Application → Domain ← Infrastructure
                    ↓
              Infrastructure

Domain depends on NOTHING
Infrastructure depends on Domain (implements interfaces)
Application depends on Domain
Presentation depends on Application
```

## Detection Criteria

### Framework Annotations in Domain

**Violation**: Framework decorators/annotations in domain classes

```typescript
// ❌ VIOLATION - NestJS in domain
import { Injectable } from '@nestjs/common';

@Injectable()
class OrderService {
  // ...
}

// ❌ VIOLATION - TypeORM in domain
import { Entity, Column } from 'typeorm';

@Entity()
class Order {
  @Column()
  id: string;
}

// ❌ VIOLATION - Spring in domain
@Service
@Transactional
public class OrderService {
  // ...
}
```

**Correct approach**:
```typescript
// ✅ Domain - Pure class
class Order {
  private readonly id: OrderId;
  private items: OrderItem[];

  // Pure business logic
}

// ✅ Infrastructure - ORM mapping separate
@Entity('orders')
class OrderEntity {
  @PrimaryColumn()
  id: string;

  @Column('json')
  items: OrderItemData[];
}

// ✅ Infrastructure - Mapper
class OrderMapper {
  toDomain(entity: OrderEntity): Order { ... }
  toEntity(order: Order): OrderEntity { ... }
}
```

### Infrastructure Imports in Domain

**Common violations**:
```typescript
// ❌ HTTP client in domain
import axios from 'axios';

// ❌ ORM in domain
import { Repository } from 'typeorm';

// ❌ Message queue in domain
import { RabbitMQ } from 'amqplib';

// ❌ Logging framework in domain
import { Logger } from 'winston';

// ❌ Serialization in domain
import { Expose } from 'class-transformer';
```

**Correct approach - Use Ports**:
```typescript
// ✅ Domain - Define port (interface)
interface PaymentGateway {
  processPayment(amount: Money, method: PaymentMethod): Promise<PaymentResult>;
}

interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

// ✅ Infrastructure - Implement adapter
class StripePaymentAdapter implements PaymentGateway {
  constructor(private stripe: Stripe) {}

  async processPayment(amount: Money, method: PaymentMethod): Promise<PaymentResult> {
    const result = await this.stripe.charges.create({...});
    return this.toPaymentResult(result);
  }
}
```

### Database Logic in Domain

**Violation**:
```typescript
// ❌ SQL in domain
class OrderRepository {
  async findPendingOrders(): Promise<Order[]> {
    return this.db.query('SELECT * FROM orders WHERE status = ?', ['PENDING']);
  }
}

// ❌ ORM queries in domain
class OrderService {
  async findWithItems(orderId: string): Promise<Order> {
    return this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['items', 'customer']
    });
  }
}
```

**Correct approach**:
```typescript
// ✅ Domain - Pure interface
interface OrderRepository {
  findPendingOrders(): Promise<Order[]>;
  findById(id: OrderId): Promise<Order | null>;
}

// ✅ Infrastructure - Implementation with ORM
class TypeOrmOrderRepository implements OrderRepository {
  async findPendingOrders(): Promise<Order[]> {
    const entities = await this.ormRepo.find({
      where: { status: 'PENDING' }
    });
    return entities.map(e => this.mapper.toDomain(e));
  }
}
```

## Hexagonal Architecture (Ports & Adapters)

```
                    ┌─────────────────────────────────────────┐
                    │              Application                │
                    │  ┌─────────────────────────────────┐   │
    Primary         │  │           Domain               │   │        Secondary
    Adapters        │  │                                 │   │        Adapters
   ┌────────┐      │  │  ┌───────────────────────┐     │   │      ┌────────┐
   │  HTTP  │──────┼──┼─→│    Aggregate Roots    │←────┼───┼──────│Database│
   │  CLI   │      │  │  │    Domain Services    │     │   │      │  Queue │
   │  gRPC  │      │  │  │    Domain Events      │     │   │      │External│
   └────────┘      │  │  └───────────────────────┘     │   │      └────────┘
                    │  │           ↑     ↑              │   │
   Driving          │  │      Ports│     │Ports        │   │      Driven
   (Primary)        │  └───────────┼─────┼─────────────┘   │      (Secondary)
                    │              │     │                  │
                    └──────────────┼─────┼──────────────────┘
                              Interfaces define contracts
```

## Detection Checklist

| Check | Pass Criteria | Fail Criteria |
|-------|---------------|---------------|
| No framework imports | Only language primitives | Framework decorators present |
| Repository is interface | Interface in domain, impl in infra | Concrete class with ORM |
| No HTTP concepts | No Request/Response types | Controller logic in domain |
| No serialization | No JSON annotations | @Expose, @Type decorators |
| No database concepts | No SQL, no ORM methods | Direct query methods |
| No external calls | Uses port interface | Direct HTTP/gRPC calls |

## Benefits of Clean Domain

1. **Testability** - Domain logic tested without infrastructure
2. **Flexibility** - Switch databases/frameworks without domain changes
3. **Clarity** - Business rules clearly visible
4. **Longevity** - Domain survives technology changes

## Common Refactoring Patterns

### Extract Port
```typescript
// Before: Direct dependency
class OrderService {
  constructor(private stripe: Stripe) {}

  async pay(order: Order): Promise<void> {
    await this.stripe.charges.create({...});
  }
}

// After: Port abstraction
interface PaymentGateway {
  charge(amount: Money): Promise<PaymentId>;
}

class OrderService {
  constructor(private paymentGateway: PaymentGateway) {}

  async pay(order: Order): Promise<void> {
    await this.paymentGateway.charge(order.total);
  }
}
```

### Separate ORM Entity
```typescript
// Before: Domain class is ORM entity
@Entity()
class Order {
  @PrimaryColumn() id: string;
  @Column() status: string;
  businessMethod() { ... }
}

// After: Separated
// Domain
class Order {
  private id: OrderId;
  private status: OrderStatus;
  businessMethod() { ... }
}

// Infrastructure
@Entity('orders')
class OrderEntity {
  @PrimaryColumn() id: string;
  @Column() status: string;
}
```

## References

- [Alistair Cockburn - Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Robert C. Martin - Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Eric Evans - Domain-Driven Design Reference](https://www.domainlanguage.com/ddd/reference/)
