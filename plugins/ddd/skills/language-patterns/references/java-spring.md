# Java Spring DDD Patterns

Implementation patterns for Domain-Driven Design in Java Spring Boot projects.

## Project Structure

```
src/main/java/com/example/
├── domain/                           # Pure domain layer
│   ├── order/
│   │   ├── Order.java               # Aggregate root
│   │   ├── OrderItem.java           # Entity
│   │   ├── OrderId.java             # Value object (identity)
│   │   ├── OrderStatus.java         # Value object (enum)
│   │   ├── OrderRepository.java     # Repository interface
│   │   └── events/
│   │       ├── OrderCreated.java
│   │       └── OrderCancelled.java
│   └── shared/
│       ├── AggregateRoot.java
│       ├── Entity.java
│       ├── ValueObject.java
│       └── DomainEvent.java
│
├── application/                      # Application services
│   └── order/
│       ├── CreateOrderUseCase.java
│       └── dto/
│           └── CreateOrderCommand.java
│
└── infrastructure/                   # Technical implementations
    ├── persistence/
    │   ├── JpaOrderRepository.java
    │   └── entity/
    │       └── OrderJpaEntity.java
    └── config/
        └── DomainConfig.java
```

## Core Building Blocks

### Aggregate Root

```java
// domain/order/Order.java
package com.example.domain.order;

import com.example.domain.shared.AggregateRoot;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Order extends AggregateRoot<OrderId> {

    private final CustomerId customerId;
    private final List<OrderItem> items;
    private OrderStatus status;

    private Order(OrderId id, CustomerId customerId, List<OrderItem> items) {
        super(id);
        this.customerId = customerId;
        this.items = new ArrayList<>(items);
        this.status = OrderStatus.PENDING;
    }

    // Factory method
    public static Order create(CustomerId customerId, List<OrderItem> items) {
        if (items == null || items.isEmpty()) {
            throw new EmptyOrderException();
        }

        Order order = new Order(OrderId.generate(), customerId, items);
        order.registerEvent(new OrderCreated(order.getId(), customerId, items));
        return order;
    }

    // Reconstitute from persistence
    public static Order reconstitute(
            OrderId id,
            CustomerId customerId,
            List<OrderItem> items,
            OrderStatus status) {
        Order order = new Order(id, customerId, items);
        order.status = status;
        return order;
    }

    // Business methods
    public void addItem(OrderItem item) {
        ensureCanModify();
        this.items.add(item);
        registerEvent(new OrderItemAdded(getId(), item));
    }

    public void cancel(String reason) {
        if (!canCancel()) {
            throw new OrderCannotBeCancelledException(getId(), status);
        }
        this.status = OrderStatus.CANCELLED;
        registerEvent(new OrderCancelled(getId(), reason));
    }

    // Computed property
    public Money getTotal() {
        return items.stream()
            .map(OrderItem::getSubtotal)
            .reduce(Money.ZERO, Money::add);
    }

    // Query methods
    public boolean canCancel() {
        return status == OrderStatus.PENDING;
    }

    public List<OrderItem> getItems() {
        return Collections.unmodifiableList(items);
    }

    public CustomerId getCustomerId() {
        return customerId;
    }

    public OrderStatus getStatus() {
        return status;
    }

    // Private invariant enforcement
    private void ensureCanModify() {
        if (status != OrderStatus.PENDING) {
            throw new OrderNotModifiableException(getId());
        }
    }
}
```

### Base Aggregate Root

```java
// domain/shared/AggregateRoot.java
package com.example.domain.shared;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public abstract class AggregateRoot<ID> extends Entity<ID> {

    private final List<DomainEvent> domainEvents = new ArrayList<>();

    protected AggregateRoot(ID id) {
        super(id);
    }

    protected void registerEvent(DomainEvent event) {
        domainEvents.add(event);
    }

    public List<DomainEvent> pullDomainEvents() {
        List<DomainEvent> events = new ArrayList<>(domainEvents);
        domainEvents.clear();
        return events;
    }

    public List<DomainEvent> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }
}
```

### Value Object (with Java Records)

```java
// Java 16+ Record-based Value Object
// domain/shared/Money.java
package com.example.domain.shared;

public record Money(long amountInCents, String currency) {

    public static final Money ZERO = new Money(0, "USD");

    public Money {
        if (amountInCents < 0) {
            throw new InvalidMoneyException(amountInCents);
        }
        if (currency == null || currency.isBlank()) {
            throw new InvalidCurrencyException();
        }
    }

    public static Money of(long amountInCents, String currency) {
        return new Money(amountInCents, currency);
    }

    public static Money dollars(double amount) {
        return new Money((long) (amount * 100), "USD");
    }

    public Money add(Money other) {
        ensureSameCurrency(other);
        return new Money(this.amountInCents + other.amountInCents, this.currency);
    }

    public Money subtract(Money other) {
        ensureSameCurrency(other);
        long result = this.amountInCents - other.amountInCents;
        if (result < 0) {
            throw new InsufficientFundsException();
        }
        return new Money(result, this.currency);
    }

    private void ensureSameCurrency(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new CurrencyMismatchException(this.currency, other.currency);
        }
    }
}
```

### Value Object (Pre-Java 16)

```java
// domain/shared/Money.java (Pre-Java 16)
package com.example.domain.shared;

import java.util.Objects;

public final class Money {

    public static final Money ZERO = new Money(0, "USD");

    private final long amountInCents;
    private final String currency;

    private Money(long amountInCents, String currency) {
        if (amountInCents < 0) {
            throw new InvalidMoneyException(amountInCents);
        }
        this.amountInCents = amountInCents;
        this.currency = Objects.requireNonNull(currency);
    }

    public static Money of(long amountInCents, String currency) {
        return new Money(amountInCents, currency);
    }

    public long getAmountInCents() {
        return amountInCents;
    }

    public String getCurrency() {
        return currency;
    }

    public Money add(Money other) {
        ensureSameCurrency(other);
        return new Money(this.amountInCents + other.amountInCents, this.currency);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Money money = (Money) o;
        return amountInCents == money.amountInCents &&
               Objects.equals(currency, money.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amountInCents, currency);
    }
}
```

### Identity Value Object

```java
// domain/order/OrderId.java
package com.example.domain.order;

import java.util.Objects;
import java.util.UUID;

public final class OrderId {

    private final String value;

    private OrderId(String value) {
        this.value = Objects.requireNonNull(value);
    }

    public static OrderId generate() {
        return new OrderId(UUID.randomUUID().toString());
    }

    public static OrderId from(String value) {
        try {
            UUID.fromString(value);
        } catch (IllegalArgumentException e) {
            throw new InvalidOrderIdException(value);
        }
        return new OrderId(value);
    }

    public String getValue() {
        return value;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OrderId orderId = (OrderId) o;
        return Objects.equals(value, orderId.value);
    }

    @Override
    public int hashCode() {
        return Objects.hash(value);
    }

    @Override
    public String toString() {
        return value;
    }
}
```

### Domain Event

```java
// domain/shared/DomainEvent.java
package com.example.domain.shared;

import java.time.Instant;

public interface DomainEvent {
    String getEventId();
    Instant getOccurredAt();
    String getAggregateId();
}

// domain/order/events/OrderCreated.java
package com.example.domain.order.events;

import com.example.domain.shared.DomainEvent;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record OrderCreated(
    String eventId,
    Instant occurredAt,
    OrderId orderId,
    CustomerId customerId,
    List<OrderItemSnapshot> items
) implements DomainEvent {

    public OrderCreated(OrderId orderId, CustomerId customerId, List<OrderItem> items) {
        this(
            UUID.randomUUID().toString(),
            Instant.now(),
            orderId,
            customerId,
            items.stream().map(OrderItemSnapshot::from).toList()
        );
    }

    @Override
    public String getAggregateId() {
        return orderId.getValue();
    }
}
```

### Repository Interface

```java
// domain/order/OrderRepository.java
package com.example.domain.order;

import java.util.List;
import java.util.Optional;

public interface OrderRepository {
    Optional<Order> findById(OrderId id);
    List<Order> findByCustomer(CustomerId customerId);
    List<Order> findPending();
    void save(Order order);
    void delete(Order order);
}
```

### Repository Implementation (JPA)

```java
// infrastructure/persistence/JpaOrderRepository.java
package com.example.infrastructure.persistence;

import com.example.domain.order.*;
import org.springframework.stereotype.Repository;
import javax.persistence.EntityManager;
import java.util.Optional;

@Repository
public class JpaOrderRepository implements OrderRepository {

    private final EntityManager entityManager;
    private final OrderMapper mapper;

    public JpaOrderRepository(EntityManager entityManager, OrderMapper mapper) {
        this.entityManager = entityManager;
        this.mapper = mapper;
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        OrderJpaEntity entity = entityManager.find(OrderJpaEntity.class, id.getValue());
        return Optional.ofNullable(entity).map(mapper::toDomain);
    }

    @Override
    public void save(Order order) {
        OrderJpaEntity entity = mapper.toEntity(order);
        entityManager.merge(entity);
    }

    // ... other methods
}
```

## Spring Integration

### Clean Domain with Spring

```java
// ❌ Avoid: Spring annotations in domain
package com.example.domain.order;

import org.springframework.stereotype.Service;  // ❌ Framework in domain
import org.springframework.transaction.annotation.Transactional;

@Service  // ❌ Bad
@Transactional
public class OrderService {
    // ...
}

// ✅ Correct: Spring only in application/infrastructure
// domain/order/Order.java - Pure, no annotations
public class Order {
    // Pure domain logic
}

// application/order/CreateOrderUseCase.java
package com.example.application.order;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service  // ✅ OK in application layer
public class CreateOrderUseCase {

    private final OrderRepository orderRepository;
    private final DomainEventPublisher eventPublisher;

    public CreateOrderUseCase(OrderRepository orderRepository,
                              DomainEventPublisher eventPublisher) {
        this.orderRepository = orderRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public OrderId execute(CreateOrderCommand command) {
        Order order = Order.create(
            CustomerId.from(command.customerId()),
            command.items().stream()
                .map(OrderItem::create)
                .toList()
        );

        orderRepository.save(order);
        eventPublisher.publish(order.pullDomainEvents());

        return order.getId();
    }
}
```

### JPA Entity (Separate from Domain)

```java
// infrastructure/persistence/entity/OrderJpaEntity.java
package com.example.infrastructure.persistence.entity;

import javax.persistence.*;
import java.util.List;

@Entity
@Table(name = "orders")
public class OrderJpaEntity {

    @Id
    private String id;

    @Column(name = "customer_id")
    private String customerId;

    @Enumerated(EnumType.STRING)
    private String status;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "order_id")
    private List<OrderItemJpaEntity> items;

    // Getters, setters for JPA
}
```

## Common Pitfalls

### 1. JPA Annotations in Domain
```java
// ❌ Bad
@Entity
@Table(name = "orders")
public class Order {
    @Id
    private String id;
}

// ✅ Good - Domain is pure
public class Order extends AggregateRoot<OrderId> {
    // No JPA annotations
}
```

### 2. Spring Dependency Injection in Domain
```java
// ❌ Bad
public class Order {
    @Autowired
    private OrderRepository repository;  // DI in domain
}

// ✅ Good - Dependencies passed to application service
public class CreateOrderUseCase {
    private final OrderRepository repository;
}
```

### 3. Anemic with Lombok
```java
// ❌ Bad - Lombok makes anemic model easy
@Data
@Entity
public class Order {
    private String id;
    private List<OrderItem> items;
    private String status;
    // All getters/setters generated, no business logic
}

// ✅ Good - Encapsulated with business methods
public class Order {
    private final OrderId id;
    private List<OrderItem> items;
    private OrderStatus status;

    public void addItem(OrderItem item) {
        ensureCanModify();
        items.add(item);
    }
}
```

## Detection Patterns

| Pattern | Detection |
|---------|-----------|
| Aggregate Root | Extends `AggregateRoot`, has business methods |
| Value Object | Record type, or final class with `equals`/`hashCode` |
| Domain Event | Implements `DomainEvent`, record with event data |
| Repository | Interface with `findBy*`, `save` methods |
| Anemic Model | `@Entity` with only getters/setters, `@Data` annotation |
| Layer Violation | `@Entity`, `@Service`, `@Autowired` in domain package |
