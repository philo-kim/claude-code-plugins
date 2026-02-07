---
description: Generate characterization tests that lock down your code's behavior at boundaries - safe to refactor, safe to deploy
argument-hint: [--critical | <file-or-dir>]
---

# /safety-net — Characterization Tests for Vibe-Coded Projects

No spec? No tests? No problem. AI reads your code, understands what it does, and generates tests that lock down the behavior — so you can change the code without breaking it.

## Philosophy

Vibe-coded projects have no spec. The code IS the spec. Traditional test generation asks "is this correct?" — but nobody knows what "correct" means for code that was never specified.

Characterization tests ask a different question: **"what does this code do right now?"** They capture the current behavior at system boundaries (API inputs/outputs, DB operations, external calls). When you later change the code, these tests tell you if the behavior changed.

These tests are NOT about proving correctness. They are a **safety net** — they catch unintended behavioral changes when you refactor, restructure, or fix bugs.

### What makes this different from generic test generation:

| Generic AI test gen | safety-net |
|-------------------|------------|
| Tests every function | Tests **boundaries** only |
| Tests implementation details | Tests **observable behavior** |
| Breaks when you refactor | **Survives refactoring** |
| Gives false confidence | Gives **real protection** |
| Unit tests for everything | **Characterization tests** for what matters |

## Core Principles

- **Use TodoWrite**: Track every critical path and test generated. Mark complete after test passes.
- **Agent delegation**: Use path-finder agent for analysis, test-writer agent for generation.
- **Boundary testing only**: Never test internal implementation. Test inputs → outputs at system edges.
- **Critical paths first**: Test the flows that would hurt most if broken.
- **Run all tests**: Every generated test must pass before the command completes.
- **Do not stop until done**: Keep generating tests until every critical path is covered.

## Options

- (no args): Smart mode — find critical paths, generate tests for all of them
- `<file-or-dir>`: Generate tests for a specific file or directory
- `--critical`: Only test the most critical paths (faster, less coverage)

---

## Phase 1: Understand the Application

**Goal**: Read the code and understand what this application does

**Actions**:
1. Create TodoWrite checklist with all phases
2. Detect language, framework, test framework (or choose one if none exists)
3. Read entry points (main files, route definitions, API handlers)
4. Build a mental model: what does this app do for its users?

**CRITICAL**: If no test framework is set up, set it up first:
- JavaScript/TypeScript → install vitest or jest
- Python → ensure pytest exists
- Java/Kotlin → ensure JUnit exists
- Swift → ensure XCTest exists
- Go → built-in testing package

---

## Phase 2: Map Boundaries

**Goal**: Find every system boundary where behavior is observable

Launch **path-finder agent** to identify:

### Boundary Types

**API boundaries** — Where external requests enter the system:
- HTTP endpoints (routes, controllers, handlers)
- GraphQL resolvers
- WebSocket handlers
- CLI commands

**Data boundaries** — Where data is persisted or retrieved:
- Database queries (what goes in, what comes out)
- Cache operations
- File system reads/writes

**External service boundaries** — Where the system talks to others:
- Third-party API calls
- Email/SMS sending
- Payment processing
- Authentication providers

**Business logic boundaries** — Where core transformations happen:
- Input validation (what's accepted, what's rejected)
- Data transformations (what goes in, what comes out)
- State transitions (what triggers what)
- Calculations (given X, returns Y)

### Critical Path Identification

For each boundary, assess impact:
- **Critical**: Failure here = users can't use the app (auth, payment, core feature)
- **Important**: Failure here = degraded experience (search, notifications, settings)
- **Low**: Failure here = minor issue (analytics, logging, cosmetic)

---

## Phase 3: Report

Present the boundary map:

```markdown
## Boundary Map

### Critical Paths (must test)
| # | Path | Type | Boundaries | Input → Output |
|---|------|------|-----------|---------------|
| 1 | User signup | API + DB | POST /auth/signup → users table | email, password → user object |
| 2 | Payment processing | API + External | POST /payments → Stripe API | amount, card → confirmation |
| 3 | Core feature X | API + DB + Logic | GET /feature → transform → response | params → result |

### Important Paths
| # | Path | Type | Boundaries |
|---|------|------|-----------|

### Low Priority (skip unless --full)
| # | Path | Type | Boundaries |
|---|------|------|-----------|

### Test Setup
- Framework: [detected or chosen]
- Test directory: [path]
- Tests to generate: N

Generate safety net? (N tests for M critical paths)
```

---

## Phase 4: Generate Tests

**CRITICAL**: Only proceed after user approval from Phase 3.

Launch **test-writer agent** with the approved boundary list. The agent will:

### For each boundary:

1. **Read the code** that handles this boundary
2. **Understand the behavior**: given this input, what output does the code produce?
3. **Write a characterization test**:
   - Set up the input (request, data, parameters)
   - Call the boundary (API endpoint, function, method)
   - Assert the output matches current behavior
4. **Run the test** — must pass
5. **Mark TodoWrite item complete**

### Test Generation Rules

**DO**:
- Test at the boundary (HTTP request → response, function input → output)
- Test with realistic data (based on what the code actually handles)
- Test error cases (what happens with bad input?)
- Test edge cases visible from the code (nulls, empty strings, boundary values)
- Mock external services (don't call real Stripe, real DB in unit tests)
- Use the project's existing test patterns if any exist

**DO NOT**:
- Test internal implementation (private functions, internal state)
- Test the framework itself (Express routing, React rendering)
- Hard-code timestamps, random values, or environment-specific data
- Create tests that are coupled to file structure (these break on re-arch)
- Generate tests that only assert "no error thrown" (meaningless)

### Test Quality Check

Each test must answer: **"If someone changes this code and the behavior changes, will this test catch it?"**

If the answer is no, the test is useless. Rewrite it.

---

## Phase 5: Run and Verify

**Goal**: All generated tests pass

1. Run the full test suite
2. If any test fails:
   - Read the failure
   - Fix the test (the code is the truth — the test must match)
   - Re-run
3. Repeat until all pass
4. Run once more to confirm no flaky tests

**CRITICAL**: A test that fails on the current code is a bug in the test, not in the code. The code is the source of truth.

---

## Phase 6: Report

```markdown
# Safety Net Complete

## Coverage
- Critical paths tested: X/Y
- Important paths tested: X/Y
- Total tests generated: N
- All passing: Yes/No

## Tests Created
| # | Test File | What It Tests | Boundaries Covered |
|---|-----------|-------------|-------------------|
| 1 | test/auth.test.ts | User signup/login flow | POST /auth/*, users table |
| 2 | test/payments.test.ts | Payment processing | POST /payments, Stripe mock |

## What's Protected
- [list of behaviors now locked down]

## What's NOT Protected (manual tests recommended)
- [behaviors that couldn't be automatically tested]

## Next Steps
- Run `/re-arch` safely — these tests will catch behavioral changes
- Run `/health` — fix issues knowing tests protect your behavior
- Add tests for important paths: `/safety-net src/features/search`
```

---

## Notes

- Tests capture CURRENT behavior, not INTENDED behavior. If a bug exists, the test will lock it in.
- After fixing a bug, update the test to match the new correct behavior.
- These tests are designed to survive `/re-arch` — they test boundaries, not structure.
- Run `/safety-net` before `/re-arch` for maximum safety.
