# Bounded Contexts

## Definition

A Bounded Context is a boundary within which a particular domain model is defined and applicable. The same term can have different meanings in different contexts.

> "A Bounded Context delimits the applicability of a particular model so that team members have a clear and shared understanding of what has to be consistent and how it relates to other Contexts."
> — Eric Evans

## Why Bounded Contexts Matter

1. **Clarity** - Terms have precise meaning within context
2. **Autonomy** - Teams can work independently
3. **Scalability** - Contexts can scale separately
4. **Maintainability** - Changes are isolated

## Context Identification

### Signs of Different Contexts

| Indicator | Example |
|-----------|---------|
| Different definitions | "Customer" means buyer vs. account |
| Different lifecycles | Order lifecycle vs. Inventory lifecycle |
| Different teams | Sales team vs. Warehouse team |
| Different data focus | Customer demographics vs. Purchase history |

### Example: E-Commerce Contexts

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Sales Context  │  │ Inventory Ctx   │  │ Shipping Ctx    │
│                 │  │                 │  │                 │
│ • Customer      │  │ • Product       │  │ • Shipment      │
│ • Order         │  │ • Stock         │  │ • Carrier       │
│ • Cart          │  │ • Warehouse     │  │ • Tracking      │
│ • Price         │  │ • Location      │  │ • Address       │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └──────────Events────┴────────Events──────┘
```

**Same term, different meaning**:
- `Product` in Sales: name, price, description
- `Product` in Inventory: SKU, quantity, location
- `Product` in Shipping: weight, dimensions

## Context Mapping Patterns

### 1. Shared Kernel

Two contexts share a subset of the domain model.

```
┌─────────────┐     ┌─────────────┐
│  Context A  │     │  Context B  │
│             │     │             │
│    ┌────────┴─────┴────────┐   │
│    │    Shared Kernel      │   │
│    │  (common types,       │   │
│    │   shared rules)       │   │
│    └────────┬─────┬────────┘   │
│             │     │             │
└─────────────┘     └─────────────┘
```

**When to use**: Teams with close collaboration, shared codebase
**Risk**: Changes affect both contexts

### 2. Customer-Supplier

Upstream context provides what downstream needs.

```
┌─────────────┐          ┌─────────────┐
│  Supplier   │──────────│  Customer   │
│  (upstream) │  feeds   │ (downstream)│
└─────────────┘          └─────────────┘
```

**When to use**: Clear dependency direction
**Example**: Order Context (customer) depends on Product Context (supplier)

### 3. Conformist

Downstream context conforms to upstream model.

```
┌─────────────┐          ┌─────────────┐
│  Upstream   │══════════│  Conformist │
│   (owns)    │ dictates │  (follows)  │
└─────────────┘          └─────────────┘
```

**When to use**: Can't influence upstream, accept their model
**Example**: Integrating with external payment provider's model

### 4. Anti-Corruption Layer (ACL)

Translation layer protecting domain from external models.

```
┌─────────────┐    ┌─────┐    ┌─────────────┐
│  External   │────│ ACL │────│  Our Domain │
│   System    │    │     │    │             │
└─────────────┘    └─────┘    └─────────────┘
```

**When to use**: External systems, legacy integration
**Implementation**:
```typescript
// External model (we don't control)
interface ExternalOrder {
  order_id: string;
  cust_ref: string;
  line_items: Array<{sku: string, qty: number}>;
}

// Anti-Corruption Layer
class OrderTranslator {
  toDomain(external: ExternalOrder): Order {
    return Order.reconstitute(
      OrderId.from(external.order_id),
      CustomerId.from(external.cust_ref),
      external.line_items.map(li =>
        OrderItem.create(Sku.from(li.sku), Quantity.of(li.qty))
      )
    );
  }
}
```

### 5. Open Host Service (OHS)

Context provides a well-defined protocol for others.

```
                    ┌─────────────┐
                    │   Context   │
                    │             │
┌──────┐           │  ┌───────┐  │
│Client│───────────│──│  API  │  │
└──────┘           │  └───────┘  │
┌──────┐           │             │
│Client│───────────│             │
└──────┘           └─────────────┘
```

**When to use**: Multiple consumers of your context
**Implementation**: REST API, gRPC, GraphQL

### 6. Published Language

Shared language for integration (e.g., industry standards).

**Examples**:
- JSON Schema for data exchange
- OpenAPI specifications
- Industry protocols (HL7 for healthcare)

## Detection: Context Violations

### 1. Context Leak

**Detection**: Direct imports across context boundaries

```typescript
// ❌ Violation: Sales context imports from Inventory
// src/sales/OrderService.ts
import { InventoryItem } from '../inventory/InventoryItem';

class OrderService {
  async createOrder(items: InventoryItem[]): Promise<Order> {
    // Direct use of another context's types
  }
}
```

**Fix**: Use events or ACL
```typescript
// ✅ Sales context uses its own types
import { OrderItem } from './OrderItem';

class OrderService {
  async createOrder(items: OrderItem[]): Promise<Order> {
    // OrderCreated event triggers inventory reservation
  }
}
```

### 2. Shared Mutable State

**Detection**: Multiple contexts modify same database table

```
┌─────────────┐          ┌─────────────┐
│  Context A  │──writes──│  Shared DB  │──writes──│  Context B  │
└─────────────┘          └─────────────┘          └─────────────┘
```

**Fix**: Each context owns its data

### 3. Missing ACL for External Systems

**Detection**: Direct use of external system models in domain

```typescript
// ❌ External model used directly
import { StripeCustomer } from 'stripe';

class CustomerService {
  async getCustomer(id: string): Promise<StripeCustomer> {
    return this.stripe.customers.retrieve(id);
  }
}
```

**Fix**: Translate at boundary
```typescript
// ✅ Translated to domain model
class CustomerService {
  async getCustomer(id: string): Promise<Customer> {
    const stripeCustomer = await this.stripe.customers.retrieve(id);
    return this.translator.toDomain(stripeCustomer);
  }
}
```

## Context Map Documentation

```markdown
# Context Map

## Contexts

### OrderContext
- **Responsibility**: Managing customer orders
- **Team**: Order Team
- **Key Aggregates**: Order, Cart

### InventoryContext
- **Responsibility**: Stock management
- **Team**: Warehouse Team
- **Key Aggregates**: Stock, Warehouse

## Relationships

### OrderContext → InventoryContext
- **Pattern**: Customer-Supplier
- **Communication**: Domain Events
- **Events**: OrderCreated, OrderCancelled

### OrderContext → PaymentGateway (External)
- **Pattern**: Anti-Corruption Layer
- **Implementation**: PaymentGatewayAdapter
- **Translation**: StripeCharge → Payment
```

## Detection Checklist

| Check | Pass | Fail |
|-------|------|------|
| No direct imports | Events/ACL used | Direct class imports |
| Clear boundaries | Explicit context folders | Mixed code |
| Own data | Context owns tables | Shared tables |
| Documented relationships | Context map exists | Implicit coupling |
| External ACL | Adapters for externals | Direct SDK usage |

## References

- [Eric Evans - Domain-Driven Design Reference](https://www.domainlanguage.com/ddd/reference/)
- [Context Mapper - Context Mapping DSL](https://contextmapper.org/)
- [Vaughn Vernon - Strategic Design](https://www.informit.com/articles/article.aspx?p=2020371)
