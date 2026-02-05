# Kotlin DDD Patterns

Implementation patterns for Domain-Driven Design in Kotlin projects.

## Why Kotlin Excels at DDD

1. **Data classes** - Perfect for Value Objects
2. **Null safety** - Enforces domain constraints
3. **Sealed classes** - Great for status/state modeling
4. **Extension functions** - Clean domain extensions
5. **Coroutines** - Async repository operations

## Project Structure

```
src/main/kotlin/com/example/
├── domain/                           # Pure domain layer
│   ├── order/
│   │   ├── Order.kt                 # Aggregate root
│   │   ├── OrderItem.kt             # Entity
│   │   ├── OrderId.kt               # Value object (identity)
│   │   ├── OrderStatus.kt           # Sealed class
│   │   ├── OrderRepository.kt       # Repository interface
│   │   └── events/
│   │       ├── OrderCreated.kt
│   │       └── OrderCancelled.kt
│   └── shared/
│       ├── AggregateRoot.kt
│       ├── Entity.kt
│       ├── ValueObject.kt
│       └── DomainEvent.kt
│
├── application/                      # Application services
│   └── order/
│       ├── CreateOrderHandler.kt
│       └── dto/
│           └── CreateOrderCommand.kt
│
└── infrastructure/                   # Technical implementations
    └── persistence/
        ├── ExposedOrderRepository.kt
        └── entity/
            └── OrderTable.kt
```

## Core Building Blocks

### Aggregate Root

```kotlin
// domain/order/Order.kt
package com.example.domain.order

import com.example.domain.shared.AggregateRoot

class Order private constructor(
    id: OrderId,
    val customerId: CustomerId,
    private val _items: MutableList<OrderItem>,
    private var _status: OrderStatus
) : AggregateRoot<OrderId>(id) {

    val items: List<OrderItem> get() = _items.toList()
    val status: OrderStatus get() = _status

    val total: Money
        get() = _items.fold(Money.ZERO) { acc, item -> acc + item.subtotal }

    companion object {
        fun create(customerId: CustomerId, items: List<OrderItem>): Order {
            require(items.isNotEmpty()) { "Order must have at least one item" }

            return Order(
                id = OrderId.generate(),
                customerId = customerId,
                _items = items.toMutableList(),
                _status = OrderStatus.Pending
            ).also {
                it.registerEvent(OrderCreated(it.id, customerId, items))
            }
        }

        fun reconstitute(
            id: OrderId,
            customerId: CustomerId,
            items: List<OrderItem>,
            status: OrderStatus
        ): Order = Order(id, customerId, items.toMutableList(), status)
    }

    fun addItem(item: OrderItem) {
        ensureCanModify()
        _items.add(item)
        registerEvent(OrderItemAdded(id, item))
    }

    fun cancel(reason: String) {
        check(canCancel()) { "Order cannot be cancelled in status: $status" }
        _status = OrderStatus.Cancelled(reason)
        registerEvent(OrderCancelled(id, reason))
    }

    fun canCancel(): Boolean = status is OrderStatus.Pending

    private fun ensureCanModify() {
        check(status is OrderStatus.Pending) {
            "Order cannot be modified in status: $status"
        }
    }
}
```

### Base Aggregate Root

```kotlin
// domain/shared/AggregateRoot.kt
package com.example.domain.shared

abstract class AggregateRoot<ID>(id: ID) : Entity<ID>(id) {

    private val _domainEvents = mutableListOf<DomainEvent>()
    val domainEvents: List<DomainEvent> get() = _domainEvents.toList()

    protected fun registerEvent(event: DomainEvent) {
        _domainEvents.add(event)
    }

    fun pullDomainEvents(): List<DomainEvent> {
        val events = _domainEvents.toList()
        _domainEvents.clear()
        return events
    }
}
```

### Value Object (Data Class)

```kotlin
// domain/shared/Money.kt
package com.example.domain.shared

data class Money private constructor(
    val amountInCents: Long,
    val currency: String
) {
    init {
        require(amountInCents >= 0) { "Amount cannot be negative" }
        require(currency.isNotBlank()) { "Currency is required" }
    }

    companion object {
        val ZERO = Money(0, "USD")

        fun of(amountInCents: Long, currency: String = "USD") =
            Money(amountInCents, currency)

        fun dollars(amount: Double) =
            Money((amount * 100).toLong(), "USD")
    }

    operator fun plus(other: Money): Money {
        ensureSameCurrency(other)
        return Money(amountInCents + other.amountInCents, currency)
    }

    operator fun minus(other: Money): Money {
        ensureSameCurrency(other)
        val result = amountInCents - other.amountInCents
        require(result >= 0) { "Insufficient funds" }
        return Money(result, currency)
    }

    operator fun times(multiplier: Int): Money =
        Money(amountInCents * multiplier, currency)

    private fun ensureSameCurrency(other: Money) {
        require(currency == other.currency) {
            "Cannot operate on different currencies: $currency vs ${other.currency}"
        }
    }
}
```

### Identity Value Object

```kotlin
// domain/order/OrderId.kt
package com.example.domain.order

import java.util.UUID

@JvmInline
value class OrderId private constructor(val value: String) {

    companion object {
        fun generate(): OrderId = OrderId(UUID.randomUUID().toString())

        fun from(value: String): OrderId {
            require(value.isValidUuid()) { "Invalid OrderId: $value" }
            return OrderId(value)
        }

        private fun String.isValidUuid(): Boolean = try {
            UUID.fromString(this)
            true
        } catch (e: IllegalArgumentException) {
            false
        }
    }

    override fun toString(): String = value
}
```

### Status with Sealed Class

```kotlin
// domain/order/OrderStatus.kt
package com.example.domain.order

sealed class OrderStatus {
    object Pending : OrderStatus()
    object Confirmed : OrderStatus()
    object Shipped : OrderStatus()
    object Delivered : OrderStatus()
    data class Cancelled(val reason: String) : OrderStatus()

    // Pattern matching friendly
    fun canTransitionTo(next: OrderStatus): Boolean = when (this) {
        is Pending -> next is Confirmed || next is Cancelled
        is Confirmed -> next is Shipped || next is Cancelled
        is Shipped -> next is Delivered
        is Delivered -> false
        is Cancelled -> false
    }
}
```

### Domain Event

```kotlin
// domain/shared/DomainEvent.kt
package com.example.domain.shared

import java.time.Instant
import java.util.UUID

interface DomainEvent {
    val eventId: String
    val occurredAt: Instant
    val aggregateId: String
}

// domain/order/events/OrderCreated.kt
package com.example.domain.order.events

import com.example.domain.shared.DomainEvent
import java.time.Instant
import java.util.UUID

data class OrderCreated(
    val orderId: OrderId,
    val customerId: CustomerId,
    val items: List<OrderItemSnapshot>,
    override val eventId: String = UUID.randomUUID().toString(),
    override val occurredAt: Instant = Instant.now()
) : DomainEvent {
    override val aggregateId: String get() = orderId.value
}
```

### Repository Interface

```kotlin
// domain/order/OrderRepository.kt
package com.example.domain.order

interface OrderRepository {
    suspend fun findById(id: OrderId): Order?
    suspend fun findByCustomer(customerId: CustomerId): List<Order>
    suspend fun findPending(): List<Order>
    suspend fun save(order: Order)
    suspend fun delete(order: Order)
}
```

### Repository Implementation (Exposed)

```kotlin
// infrastructure/persistence/ExposedOrderRepository.kt
package com.example.infrastructure.persistence

import com.example.domain.order.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction

class ExposedOrderRepository(
    private val mapper: OrderMapper
) : OrderRepository {

    override suspend fun findById(id: OrderId): Order? =
        newSuspendedTransaction {
            OrderTable
                .select { OrderTable.id eq id.value }
                .singleOrNull()
                ?.let { mapper.toDomain(it) }
        }

    override suspend fun save(order: Order) {
        newSuspendedTransaction {
            val exists = OrderTable.select { OrderTable.id eq order.id.value }.count() > 0
            if (exists) {
                OrderTable.update({ OrderTable.id eq order.id.value }) {
                    mapper.toRow(order, it)
                }
            } else {
                OrderTable.insert { mapper.toRow(order, it) }
            }
        }
    }

    // ... other methods
}
```

## Spring Boot Integration

```kotlin
// application/order/CreateOrderHandler.kt
package com.example.application.order

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class CreateOrderHandler(
    private val orderRepository: OrderRepository,
    private val eventPublisher: DomainEventPublisher
) {
    @Transactional
    suspend fun execute(command: CreateOrderCommand): OrderId {
        val order = Order.create(
            customerId = CustomerId.from(command.customerId),
            items = command.items.map { OrderItem.create(it) }
        )

        orderRepository.save(order)
        eventPublisher.publish(order.pullDomainEvents())

        return order.id
    }
}
```

## Kotlin-Specific Patterns

### Extension Functions for Domain Logic

```kotlin
// domain/order/OrderExtensions.kt

// Rich filtering
fun List<Order>.pendingOnly(): List<Order> =
    filter { it.status is OrderStatus.Pending }

fun List<Order>.totalValue(): Money =
    fold(Money.ZERO) { acc, order -> acc + order.total }

// Domain-specific operations
fun Order.isHighValue(): Boolean = total.amountInCents > 100_000
```

### Result Type for Domain Operations

```kotlin
sealed class OrderResult {
    data class Success(val order: Order) : OrderResult()
    data class NotFound(val id: OrderId) : OrderResult()
    data class InvalidOperation(val message: String) : OrderResult()
}

class OrderService(private val repository: OrderRepository) {
    suspend fun cancel(orderId: OrderId, reason: String): OrderResult {
        val order = repository.findById(orderId)
            ?: return OrderResult.NotFound(orderId)

        return if (order.canCancel()) {
            order.cancel(reason)
            repository.save(order)
            OrderResult.Success(order)
        } else {
            OrderResult.InvalidOperation("Cannot cancel order in status: ${order.status}")
        }
    }
}
```

### Scope Functions for Builders

```kotlin
// Clean aggregate creation
fun createOrder(customerId: CustomerId, block: OrderBuilder.() -> Unit): Order {
    return OrderBuilder(customerId).apply(block).build()
}

class OrderBuilder(private val customerId: CustomerId) {
    private val items = mutableListOf<OrderItem>()

    fun item(productId: ProductId, quantity: Int, price: Money) {
        items.add(OrderItem.create(productId, quantity, price))
    }

    fun build(): Order = Order.create(customerId, items)
}

// Usage
val order = createOrder(customerId) {
    item(ProductId.from("prod-1"), quantity = 2, price = Money.dollars(10.0))
    item(ProductId.from("prod-2"), quantity = 1, price = Money.dollars(25.0))
}
```

## Common Pitfalls

### 1. Data Class Mutability
```kotlin
// ❌ Bad - Mutable data class
data class Order(
    var status: OrderStatus,  // var allows mutation
    val items: MutableList<OrderItem>  // Mutable list exposed
)

// ✅ Good - Controlled mutability
class Order private constructor(
    private var _status: OrderStatus,
    private val _items: MutableList<OrderItem>
) {
    val status: OrderStatus get() = _status
    val items: List<OrderItem> get() = _items.toList()
}
```

### 2. Nullable vs Optional in Domain
```kotlin
// ❌ Inconsistent null handling
interface OrderRepository {
    fun findById(id: OrderId): Order?  // Nullable
    fun findByCustomer(id: CustomerId): Optional<List<Order>>  // Java Optional
}

// ✅ Consistent - Use Kotlin nullable
interface OrderRepository {
    suspend fun findById(id: OrderId): Order?
    suspend fun findByCustomer(id: CustomerId): List<Order>  // Empty list if none
}
```

### 3. Companion Object Abuse
```kotlin
// ❌ Bad - Logic in companion object
class Order {
    companion object {
        fun calculateTotal(items: List<OrderItem>): Money { ... }
        fun validateItems(items: List<OrderItem>): Boolean { ... }
    }
}

// ✅ Good - Logic in instance
class Order {
    val total: Money get() = items.fold(Money.ZERO) { acc, i -> acc + i.subtotal }

    companion object {
        fun create(...): Order { ... }  // Only factory methods
    }
}
```

## Detection Patterns

| Pattern | Detection |
|---------|-----------|
| Aggregate Root | Class extending `AggregateRoot`, has business methods |
| Value Object | `data class` with `val` only, or `@JvmInline value class` |
| Domain Event | `data class` implementing `DomainEvent` |
| Repository | Interface with `suspend` functions |
| Anemic Model | `data class` with `var` fields, no methods |
| Status | `sealed class` with state objects |
| Layer Violation | Framework annotations in domain package |
