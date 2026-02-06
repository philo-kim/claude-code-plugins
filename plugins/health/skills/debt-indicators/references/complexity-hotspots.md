# Complexity Hotspots

## Concept

A hotspot is a file that is both **complex** and **frequently changed**. These files carry the highest risk because:
- Complexity makes bugs likely
- Frequent changes mean bugs have many chances to be introduced
- The combination means: high probability of defects, hard to fix

## Detection Method

### Step 1: Git Churn Analysis

```bash
# Get change frequency per file (last 6 months)
git log --since="6 months ago" --name-only --pretty=format: | \
  sort | uniq -c | sort -rn | head -20
```

Output example:
```
  47 src/services/OrderService.ts
  35 src/controllers/ApiController.ts
  28 src/utils/helpers.ts
  22 src/models/User.ts
```

### Step 2: Complexity Analysis

For each high-churn file, measure:

**Cyclomatic Complexity** — Number of independent paths through code
```
if/else    → +1
switch case → +1 per case
for/while   → +1
catch       → +1
&&, ||      → +1
ternary ?:  → +1
```

**Cognitive Complexity** — How hard the code is to understand
```
Nesting increases cost:
  if (a) {           // +1
    if (b) {         // +2 (nested)
      for (...) {    // +3 (double nested)
      }
    }
  }
```

### Step 3: Cross Analysis

```
Risk = Churn × Complexity

| File | Churn | Complexity | Risk Score |
|------|-------|-----------|------------|
| OrderService.ts | 47 | 35 | 1645 (Critical) |
| ApiController.ts | 35 | 22 | 770 (Warning) |
| helpers.ts | 28 | 8 | 224 (OK) |
| User.ts | 22 | 5 | 110 (OK) |
```

## Thresholds

| Risk Score | Level | Action |
|-----------|-------|--------|
| > 1000 | Critical | Refactor immediately |
| 500-1000 | Warning | Plan refactoring |
| 200-500 | Monitor | Watch for degradation |
| < 200 | OK | No action needed |

## What to Report

For each hotspot:
```
Hotspot: src/services/OrderService.ts
  Churn: 47 changes in 6 months
  Complexity: 35 (cyclomatic)
  Longest function: processOrder() — 127 lines
  Test coverage: 23%
  Risk: Critical (1645)
  Suggestion: Break into smaller services by responsibility
```
