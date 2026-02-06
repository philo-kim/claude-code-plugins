---
name: Debt Indicators
description: When analyzing code quality, detecting technical debt, measuring complexity, or evaluating dependency health
version: 1.0.0
---

# Debt Indicators

Knowledge base for detecting technical debt, code quality issues, and dependency risks.

## When to Use

- "code quality", "technical debt", "complexity"
- "code smells", "hotspot", "churn"
- "dependency risk", "license check", "bundle size"
- "TODO tracking", "dead code"

## Key Principles

1. **Hotspots Matter Most** — High complexity + high change frequency = highest risk
2. **Trends Over Absolutes** — A score going down is worse than a low stable score
3. **Debt Is Invisible** — If you don't measure it, it grows silently
4. **Dependencies Are Code You Didn't Write** — But you still own the risk

## Detection Capabilities

| Category | What We Detect | Reference |
|----------|---------------|-----------|
| Complexity Hotspots | Files with high churn AND high complexity | [complexity-hotspots.md](references/complexity-hotspots.md) |
| Code Smells | Long functions, deep nesting, copy-paste, parameter overload | [code-smells.md](references/code-smells.md) |
| Dependency Risks | Unmaintained packages, license conflicts, duplicates, bundle bloat | [dependency-risks.md](references/dependency-risks.md) |

## Scoring Model

```
Debt Score = 100 - (Critical × 15) - (Warning × 3)

Critical issues (-15 each):
  - Function > 200 lines
  - Cyclomatic complexity > 40
  - File changed 50+ times with complexity > 30
  - GPL dependency in commercial project
  - Dependency with known critical vulnerability

Warning issues (-3 each):
  - Function > 50 lines
  - Cyclomatic complexity > 20
  - TODO older than 30 days
  - Dependency not updated in 18+ months
  - Duplicate library purpose
```

## Language Support

| Language | Complexity Analysis | Dependency Analysis | Churn Analysis |
|----------|-------------------|-------------------|----------------|
| JavaScript/TypeScript | Function length, nesting, cyclomatic | package.json, bundle size | git log |
| Python | Function length, nesting, cognitive | requirements.txt, pyproject.toml | git log |
| Java | Method length, class size, cyclomatic | pom.xml, build.gradle | git log |
| Kotlin | Function length, class size | build.gradle.kts | git log |
| Swift | Function length, class size | Package.swift, Podfile | git log |
| Go | Function length, cyclomatic | go.mod | git log |
| Ruby | Method length, class size, ABC | Gemfile | git log |
