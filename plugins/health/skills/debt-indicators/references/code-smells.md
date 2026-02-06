# Code Smells

## Detection Patterns

### 1. Long Functions

**Threshold**: > 50 lines (warning), > 200 lines (critical)

**Detection**: Count lines between function declaration and closing brace, excluding blank lines and comments.

**Why it matters**: Long functions do too many things. They're hard to test, hard to name, and hard to change without breaking something.

### 2. Deep Nesting

**Threshold**: > 4 levels (warning), > 6 levels (critical)

```javascript
// 6 levels deep — critical
function process(data) {
  if (data) {                          // 1
    for (const item of data) {         // 2
      if (item.active) {               // 3
        try {                          // 4
          if (item.type === 'A') {     // 5
            for (const sub of item) {  // 6
            }
          }
        } catch (e) { }
      }
    }
  }
}
```

**Detection**: Track indentation depth or brace nesting in control flow statements.

### 3. Too Many Parameters

**Threshold**: > 4 parameters (warning), > 7 (critical)

```javascript
// 7 parameters — critical
function createUser(name, email, age, role, team, department, location) { }

// Better: use an object
function createUser(options: CreateUserOptions) { }
```

**Detection**: Count parameters in function/method declarations.

### 4. Copy-Paste Clusters

**Detection strategy**: Find blocks of 6+ lines that appear in multiple locations with minor variations.

```
Duplication: 15 lines repeated in 3 locations
  - src/services/OrderService.ts:45-60
  - src/services/PaymentService.ts:78-93
  - src/services/ShippingService.ts:23-38
  Suggestion: Extract to shared utility
```

### 5. God Classes

**Threshold**: > 500 lines (warning), > 1000 lines (critical)

**Additional signals**:
- > 15 methods
- > 10 dependencies (imports/injections)
- Methods that don't use `this` (should be standalone functions)
- Handles unrelated responsibilities

### 6. Dead Code

**Patterns**:
- Exported functions/classes with zero imports
- Unreachable code after return/throw
- Commented-out code blocks (> 5 lines)
- Unused variables/imports (from linter output)

### 7. Magic Numbers / Strings

```javascript
// Smell
if (user.role === 3) { }
setTimeout(fn, 86400000)

// Clean
if (user.role === ROLE.ADMIN) { }
setTimeout(fn, ONE_DAY_MS)
```

**Detection**: Find numeric literals (not 0, 1, -1) and string literals in conditional expressions.

## Severity Classification

| Smell | Warning Threshold | Critical Threshold |
|-------|------------------|-------------------|
| Long function | > 50 lines | > 200 lines |
| Deep nesting | > 4 levels | > 6 levels |
| Many parameters | > 4 | > 7 |
| God class | > 500 lines | > 1000 lines |
| Copy-paste | 2 locations | 3+ locations |
| Dead code | Commented blocks | Unreachable code |
