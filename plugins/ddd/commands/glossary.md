# /ddd glossary

Manage the Ubiquitous Language glossary - the foundation of DDD.

## Purpose

The glossary maintains the shared vocabulary between developers and domain experts. This command helps manage, review, and enforce consistent terminology across the codebase.

## Prerequisites

- `shared/glossary.yaml` should exist (created by `/ddd analyze`)

## Usage

```
/ddd glossary [subcommand] [options]
```

Subcommands:
- `(none)` - Display current glossary
- `review` - Show terms needing review
- `check` - Check code for naming inconsistencies
- `add <term>` - Add a new term
- `update <term>` - Update an existing term
- `sync` - Synchronize glossary with codebase

## Glossary File Format

```yaml
# shared/glossary.yaml

domain: E-Commerce
language: en
last_updated: 2024-01-15

terms:
  Order:
    definition: "A customer's request to purchase products"
    context: OrderContext
    found_in:
      - src/order/Order.ts
      - src/order/OrderService.ts
    aliases: []
    status: approved  # approved | needs_review | deprecated

  Customer:
    definition: "A person or entity that purchases products"
    context: CustomerContext
    found_in:
      - src/customer/Customer.ts
    aliases:
      - User       # found in legacy code
      - Member     # found in subscription module
    status: approved
    notes: "Standardize all 'User' and 'Member' references to 'Customer'"

  OrderItem:
    definition: "A single product entry within an order"
    context: OrderContext
    found_in:
      - src/order/OrderItem.ts
    aliases:
      - LineItem
    status: needs_review
    notes: "Verify with product team if 'LineItem' should be deprecated"
```

## Subcommands

### `/ddd glossary`

Display the current glossary in a readable format.

**Output**:
```markdown
## Domain Glossary: E-Commerce

**Total Terms**: 42
**Approved**: 35
**Needs Review**: 5
**Deprecated**: 2

### Order Context

| Term | Definition | Status |
|------|------------|--------|
| **Order** | A customer's request to purchase products | ✅ Approved |
| **OrderItem** | A single product entry within an order | ⚠️ Review |
| **OrderStatus** | The current state of an order | ✅ Approved |

### Customer Context

| Term | Definition | Status |
|------|------------|--------|
| **Customer** | A person or entity that purchases | ✅ Approved |
| **Address** | Customer's delivery location | ✅ Approved |

### Aliases in Use (Require Attention)
- `User` → should be `Customer` (3 occurrences)
- `Member` → should be `Customer` (1 occurrence)
- `LineItem` → should be `OrderItem` (2 occurrences)
```

### `/ddd glossary review`

Show only terms that need human review.

**Output**:
```markdown
## Terms Requiring Review

### 1. OrderItem
- **Current Definition**: A single product entry within an order
- **Found in**: src/order/OrderItem.ts
- **Aliases Found**: LineItem
- **Issue**: Unclear if LineItem should be deprecated

**Actions**:
- [ ] Confirm definition with domain expert
- [ ] Decide on alias deprecation
- [ ] Update status to 'approved'

### 2. Payment
- **Current Definition**: (auto-extracted, needs refinement)
- **Found in**: src/payment/Payment.ts
- **Aliases Found**: Transaction
- **Issue**: Definition needs domain expert input

**Actions**:
- [ ] Define clear distinction from Transaction
- [ ] Verify scope with payment team
```

### `/ddd glossary check`

Check codebase for naming inconsistencies against the glossary.

**Process**:
1. Scan all domain code files
2. Extract class names, method names, variable names
3. Compare against glossary terms and aliases
4. Report inconsistencies

**Output**:
```markdown
## Naming Consistency Check

**Files Scanned**: 124
**Inconsistencies Found**: 8

### Alias Usage (Should Be Standardized)

| File | Current | Should Be | Line |
|------|---------|-----------|------|
| src/legacy/UserService.ts | `User` | `Customer` | 12 |
| src/legacy/UserService.ts | `User` | `Customer` | 45 |
| src/subscription/Member.ts | `Member` | `Customer` | 1 |
| src/order/LineItem.ts | `LineItem` | `OrderItem` | 1 |

### Unknown Terms (Not in Glossary)

| File | Term | Suggested Action |
|------|------|------------------|
| src/fulfillment/Shipment.ts | `Shipment` | Add to glossary |
| src/pricing/Discount.ts | `Discount` | Add to glossary |
| src/inventory/SKU.ts | `SKU` | Add to glossary |

### Recommendations

1. Add 3 new terms to glossary: Shipment, Discount, SKU
2. Rename 4 files using deprecated aliases
3. Update variable names in 4 locations
```

### `/ddd glossary add <term>`

Add a new term to the glossary interactively.

**Process**:
```markdown
## Adding New Term: Shipment

Please provide the following information:

1. **Definition**: [Enter definition]
2. **Context**: [Select or enter bounded context]
3. **Known Aliases**: [Enter any aliases, comma-separated]
4. **Notes**: [Optional notes]

---

✅ Added "Shipment" to glossary

```yaml
Shipment:
  definition: "The physical delivery of products to a customer"
  context: FulfillmentContext
  aliases: []
  status: needs_review
  found_in: []
```

→ Run `/ddd glossary check` to find occurrences in code
```

### `/ddd glossary update <term>`

Update an existing term.

**Output**:
```markdown
## Updating Term: Customer

Current definition:
> A person or entity that purchases products

Current aliases: User, Member
Current status: approved

What would you like to update?
1. Definition
2. Aliases
3. Status
4. Context
5. Notes

---

✅ Updated "Customer"

Changes:
- Definition: Updated to include B2B customers
- Notes: Added migration plan for User/Member references
```

### `/ddd glossary sync`

Synchronize glossary with current codebase state.

**Process**:
1. Re-scan codebase for domain terms
2. Update `found_in` locations for existing terms
3. Detect new potential terms
4. Mark removed terms

**Output**:
```markdown
## Glossary Sync Results

### Updated Locations
- `Order`: Added src/reporting/OrderReport.ts
- `Customer`: Removed src/legacy/OldCustomer.ts (file deleted)

### New Terms Detected
| Term | Occurrences | Suggested Context |
|------|-------------|-------------------|
| `Invoice` | 5 files | BillingContext |
| `Warehouse` | 3 files | InventoryContext |

### Terms No Longer Found
| Term | Last Found In | Action |
|------|---------------|--------|
| `OldCustomer` | (deleted) | Mark deprecated? |

### Recommendations
- Add 2 new terms: Invoice, Warehouse
- Review deprecated term: OldCustomer
```

## Best Practices

1. **Review glossary weekly** with domain experts
2. **Keep definitions business-focused**, not technical
3. **Document aliases** to track legacy terminology
4. **Use status field** to track review state
5. **Run `/ddd glossary check`** before code reviews

## Integration with Health Checks

The glossary is used by `/ddd health` for:
- Naming consistency scoring
- Detecting terminology drift
- Measuring ubiquitous language adoption
