# Common DDD Anti-Patterns

A catalog of frequently encountered DDD violations and how to detect them.

## 1. Anemic Domain Model

**Description**: Domain objects are mere data containers; all logic in services.

**See**: [anemic-model.md](anemic-model.md) for detailed detection criteria.

**Quick detection**:
- Entity has 0-1 business methods
- All fields have public setters
- Corresponding service has 10+ methods manipulating the entity

---

## 2. Transaction Script

**Description**: Procedural code organized by transactions, not domain concepts.

**Detection**:
```typescript
// ❌ Transaction Script
class OrderService {
  async processOrder(orderId: string): Promise<void> {
    // Step 1: Validate
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new Error('Order not found');
    if (order.status !== 'PENDING') throw new Error('Invalid status');

    // Step 2: Calculate
    let total = 0;
    for (const item of order.items) {
      const product = await this.productRepo.findById(item.productId);
      total += product.price * item.quantity;
    }

    // Step 3: Update inventory
    for (const item of order.items) {
      await this.inventoryRepo.deduct(item.productId, item.quantity);
    }

    // Step 4: Process payment
    await this.paymentService.charge(order.customerId, total);

    // Step 5: Update status
    order.status = 'COMPLETED';
    await this.orderRepo.save(order);

    // Step 6: Send notification
    await this.emailService.send(order.customerId, 'Order completed');
  }
}
```

**Signs**:
- Long methods with numbered steps
- Entity state directly manipulated
- Multiple repository calls in sequence
- Service method > 50 lines

**Fix**: Move logic to aggregates, use domain events

---

## 3. God Class / Big Ball of Mud

**Description**: A class that does too much, knows too much, controls too much.

**Detection metrics**:
| Metric | Warning | Critical |
|--------|---------|----------|
| Lines of code | >300 | >500 |
| Methods | >15 | >25 |
| Dependencies | >5 | >10 |
| Cyclomatic complexity | >10 | >20 |

**Signs**:
- Class name ends in "Manager", "Handler", "Processor", "Helper"
- Methods with unrelated responsibilities
- Comments separating "sections" of the class

---

## 4. Shotgun Surgery

**Description**: A single change requires modifying many classes.

**Detection**:
- Adding a field requires changes in 5+ files
- Business rule change touches multiple services
- Copy-paste code across classes

**Example**:
```typescript
// Change "email" to "primaryEmail" requires:
// - User.ts
// - UserDTO.ts
// - UserEntity.ts
// - UserMapper.ts
// - UserValidator.ts
// - UserController.ts
// - CreateUserRequest.ts
// - UpdateUserRequest.ts
```

**Fix**: Consolidate related logic in domain object

---

## 5. Feature Envy

**Description**: A method that uses another class's data more than its own.

**Detection**:
```typescript
// ❌ Feature Envy - OrderPrinter knows too much about Order
class OrderPrinter {
  print(order: Order): string {
    return `
      Order: ${order.getId()}
      Customer: ${order.getCustomer().getName()}
      Items: ${order.getItems().map(i =>
        `${i.getProduct().getName()} x ${i.getQuantity()} @ ${i.getPrice()}`
      ).join('\n')}
      Total: ${order.getItems().reduce((sum, i) =>
        sum + i.getQuantity() * i.getPrice(), 0)}
    `;
  }
}

// ✅ Logic belongs in Order
class Order {
  toString(): string {
    return `
      Order: ${this.id}
      Customer: ${this.customerName}
      Items: ${this.formatItems()}
      Total: ${this.total}
    `;
  }
}
```

---

## 6. Primitive Obsession

**Description**: Using primitives instead of small domain objects.

**Detection**:
```typescript
// ❌ Primitives everywhere
class User {
  email: string;        // Should be Email value object
  phone: string;        // Should be PhoneNumber value object
  money: number;        // Should be Money value object
  currency: string;     // Should be part of Money
  zipCode: string;      // Should be part of Address
  street: string;       // Should be part of Address
}

// ✅ Value objects
class User {
  email: Email;
  phone: PhoneNumber;
  balance: Money;
  address: Address;
}
```

**Signs**:
- Validation logic repeated for same primitive type
- Multiple related primitives passed together
- String/number used for identities

---

## 7. Leaky Abstraction

**Description**: Implementation details leak through abstractions.

**Detection**:
```typescript
// ❌ Repository exposes ORM details
interface OrderRepository {
  // ORM-specific method names
  findOneOrFail(id: string): Promise<Order>;
  createQueryBuilder(): QueryBuilder;

  // SQL concepts exposed
  findByWhereClause(where: string): Promise<Order[]>;
}

// ✅ Domain-focused interface
interface OrderRepository {
  findById(id: OrderId): Promise<Order | null>;
  findPendingOrders(): Promise<Order[]>;
  findByCustomer(customerId: CustomerId): Promise<Order[]>;
  save(order: Order): Promise<void>;
}
```

---

## 8. Cargo Cult DDD

**Description**: Using DDD patterns without understanding their purpose.

**Signs**:
- Folder named "DDD" or "Domain"
- Classes named `OrderAggregate`, `CustomerEntity`, `MoneyValueObject`
- Aggregate with no invariants
- Value object with setters
- Repository for non-aggregate

**Detection**:
```typescript
// ❌ Cargo cult - names suggest DDD but no actual DDD
class OrderAggregate {  // "Aggregate" in name
  id: string;
  items: OrderItemEntity[];  // "Entity" in name

  // But no business logic, no invariant enforcement
}

class MoneyValueObject {  // "ValueObject" in name
  amount: number;
  setAmount(a: number) { this.amount = a; }  // But it's mutable!
}
```

---

## 9. Smart UI Anti-Pattern

**Description**: Business logic embedded in UI layer.

**Detection**:
```typescript
// ❌ Business logic in React component
function OrderForm({ order }) {
  const handleSubmit = () => {
    // Business rules in UI
    if (order.items.length === 0) {
      alert('Order must have items');
      return;
    }

    const total = order.items.reduce((sum, i) => sum + i.price * i.qty, 0);

    if (total < 10) {
      alert('Minimum order is $10');
      return;
    }

    // Direct API call with business logic
    if (order.customer.isVIP) {
      total *= 0.9;  // 10% VIP discount
    }

    api.createOrder({ ...order, total });
  };
}
```

**Fix**: Move logic to domain layer

---

## 10. Database-Driven Design

**Description**: Domain model mirrors database schema exactly.

**Detection**:
- Entity has same fields as database table
- Relationships follow foreign keys, not business concepts
- Domain objects have auto-generated IDs (int, serial)
- No behavior, only what ORM requires

```typescript
// ❌ Database-driven
@Entity()
class Order {
  @PrimaryGeneratedColumn()
  id: number;  // Auto-increment, not domain ID

  @ManyToOne(() => Customer)
  customer: Customer;  // ORM relationship, not domain reference

  @Column()
  created_at: Date;  // Database column, not domain concept
}
```

---

## 11. Distributed Monolith

**Description**: Microservices that are tightly coupled, worse than a monolith.

**Signs**:
- Synchronous calls between services
- Shared database across services
- Services can't deploy independently
- Cascading failures

**Fix**: Proper bounded contexts, event-driven communication

---

## 12. CRUD Thinking

**Description**: Modeling everything as Create/Read/Update/Delete operations.

**Detection**:
```typescript
// ❌ CRUD operations
class OrderService {
  createOrder(data: OrderData): Order;
  getOrder(id: string): Order;
  updateOrder(id: string, data: Partial<OrderData>): Order;
  deleteOrder(id: string): void;
}

// ✅ Domain operations
class OrderApplicationService {
  placeOrder(command: PlaceOrderCommand): OrderId;
  addItemToOrder(command: AddItemCommand): void;
  cancelOrder(command: CancelOrderCommand): void;
  shipOrder(command: ShipOrderCommand): void;
}
```

---

## Anti-Pattern Detection Summary

| Anti-Pattern | Key Detection Signal |
|--------------|---------------------|
| Anemic Model | Entity with 0 business methods |
| Transaction Script | Service method > 50 lines with steps |
| God Class | Class > 500 lines or > 25 methods |
| Shotgun Surgery | Change touches > 5 files |
| Feature Envy | Method chains other object's getters |
| Primitive Obsession | Repeated validation for primitives |
| Leaky Abstraction | ORM/SQL in repository interface |
| Cargo Cult | DDD names without DDD behavior |
| Smart UI | Business logic in components |
| Database-Driven | Entity = Table structure |
| Distributed Monolith | Sync calls between services |
| CRUD Thinking | Services named Create/Update/Delete |

## References

- [Martin Fowler - Anemic Domain Model](https://martinfowler.com/bliki/AnemicDomainModel.html)
- [SourceMaking - Anti-Patterns](https://sourcemaking.com/antipatterns)
- [DZone - 10 Things to Avoid in DDD](https://dzone.com/articles/10-things-to-avoid-in-domain-driven-design)
