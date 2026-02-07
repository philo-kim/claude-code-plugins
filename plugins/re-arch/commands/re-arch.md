---
description: Rearchitect your codebase - AI evaluates structure, identifies problems, restructures with behavior preserved
argument-hint: [--report | <file-or-dir>]
---

# /re-arch — Rearchitect Your Codebase

Code works. Structure doesn't. AI reads everything, understands the architecture, and restructures it — without breaking behavior.

## Philosophy

Vibe-coded projects work but lack intentional structure. Code grows organically: business logic leaks into controllers, one file does five things, dependencies point the wrong way, patterns are inconsistent.

Re-arch doesn't apply a template or enforce a specific architecture. It reads the code, understands what the code does, identifies where the structure makes the code hard to maintain and extend, and fixes the structure — while preserving every behavior.

The test is always: **does the code do the same thing before and after?**

## Core Principles

- **Use TodoWrite**: Track every structural issue and fix. Mark complete only after verified.
- **Agent delegation**: Use arch-scanner agent for analysis, arch-fixer agent for restructuring.
- **Ask before restructuring**: Always show the plan first. Only restructure after user approval.
- **Build verification**: After every restructuring step, run the build. Never leave code in a broken state.
- **Do not stop until done**: Keep restructuring until every approved TodoWrite item is complete.

## Options

- (no args): Smart mode — scan everything, report, restructure what user approves
- `<file-or-dir>`: Focus on a specific file or directory
- `--report`: Analysis only — report problems without fixing

---

## Phase 1: Understand

**Goal**: Read the codebase and understand the current architecture

**Actions**:
1. Create TodoWrite checklist with all phases
2. Detect language, framework, project type
3. List ALL source files (excluding node_modules, build, dist, vendor, etc.)
4. Read files and build a mental model of the architecture:
   - What does each file do?
   - What depends on what? (import graph)
   - Where does business logic live?
   - Where does data access live?
   - Where does presentation logic live?
   - What patterns are used? (and are they consistent?)

**CRITICAL**: Do not apply a predefined architecture checklist. Read the code and understand it first. The problems will be visible from the code itself.

---

## Phase 2: Diagnose

**Goal**: Identify structural problems that make the code hard to maintain

Launch **arch-scanner agent** to analyze the codebase. The agent will find:

### Problem Types

**Responsibility violations** — one file/class doing too many things:
- A controller that also does database queries and business logic
- A "utils" file that's actually 10 unrelated functions
- A component that manages state, fetches data, and renders UI

**Dependency problems** — code depending on things it shouldn't:
- Business logic importing framework-specific code
- Data models importing UI libraries
- Circular dependencies between modules
- Everything depending on everything (no clear layers)

**Inconsistent patterns** — different approaches to the same thing:
- Some features use MVC, others use MVVM, others use nothing
- Some data fetching is in components, some in services, some in hooks
- Some state management uses context, some uses stores, some uses local state

**Coupling** — changes ripple through unrelated code:
- Changing one feature requires modifying 10+ files
- Shared mutable state between unrelated modules
- God objects/services that everything depends on

**Missing abstractions** — the same logic repeated in multiple places:
- Same API call pattern copy-pasted across files
- Same validation logic written multiple times
- Same error handling repeated everywhere

---

## Phase 3: Report

Present the analysis:

```markdown
## Architecture Assessment

### Current Structure
[AI's understanding of how the code is currently organized]

### Problems Found
| # | Type | Location | Problem | Impact |
|---|------|----------|---------|--------|
| 1 | Responsibility | src/api/userController.ts | Controller contains DB queries, validation, and business logic (450 lines) | Hard to test, hard to modify |
| 2 | Dependency | src/models/User.ts | Domain model imports Express Request type | Business logic tied to framework |
| 3 | Inconsistency | src/features/ | 3 different state management patterns across 5 features | Confusing, hard to onboard |
| 4 | Coupling | src/services/AppService.ts | 15 other files import this single service | Any change risks breaking everything |
| 5 | Duplication | src/pages/*.tsx | Same fetch-loading-error pattern in 8 components | Bug fixes need 8 edits |

### Proposed Restructuring
| # | What | Before | After | Files Affected |
|---|------|--------|-------|---------------|
| 1 | Extract business logic from controller | userController.ts (450 lines) | userController.ts (80 lines) + userService.ts + userValidator.ts | 3 new, 1 modified |
| 2 | Remove framework import from model | User.ts imports Express | User.ts is plain, adapter handles conversion | 2 modified |
| 3 | Unify state pattern | Mixed MVC/MVVM/none | Consistent pattern based on majority usage | 5 modified |
| 4 | Split god service | AppService.ts (800 lines) | UserService.ts + OrderService.ts + AuthService.ts | 3 new, 15 imports updated |
| 5 | Extract shared hook/utility | 8 duplicated patterns | useAsyncData hook + 8 simplified components | 1 new, 8 modified |

Total: N files to create, M files to modify

Proceed with restructuring?
- Restructure all
- Choose which to fix
- Report only
```

---

## Phase 4: Restructure

**CRITICAL**: Only proceed after user approval from Phase 3.

Launch **arch-fixer agent** with the approved restructuring plan. The agent will:

### For each approved change:

1. **Read all affected files** — understand the full context
2. **Extract/move/split** — restructure the code
3. **Update all imports** — fix every file that references moved code
4. **Run build** — verify nothing is broken
5. **Mark TodoWrite item complete**

### Restructuring Patterns

| Problem | What the Agent Does |
|---------|-------------------|
| **God file** | Extract related functions into focused files. Keep public API stable via re-exports if needed. |
| **Mixed responsibilities** | Split into separate files by concern. Controller stays thin, logic moves to services. |
| **Wrong dependency direction** | Introduce interfaces/protocols. Business logic depends on abstractions, not implementations. |
| **Inconsistent patterns** | Identify the dominant pattern, migrate others to match. |
| **Duplicate logic** | Extract into shared utility/hook/helper. Replace all duplicates with calls to the shared version. |
| **Tight coupling** | Introduce boundaries. Replace direct imports with dependency injection or event-based communication. |

### Safety Rules

- **Behavior preservation**: The code must do exactly the same thing before and after
- **Build after every step**: Run build/compile after each restructuring. Fix before moving on.
- **Incremental**: One restructuring at a time. Never do multiple unrelated changes simultaneously.
- **Imports**: After moving code, update EVERY file that imports from the old location
- **Re-export if needed**: If many external files depend on a location, keep a re-export to avoid breaking everything at once

---

## Phase 5: Verify

**Goal**: Confirm restructuring preserved behavior

1. **Build check**: Both platforms / all targets must compile
2. **Test check**: Run existing tests. All must pass.
3. **Import check**: No broken imports remaining
4. **Dependency check**: Verify dependency direction improved (no new circular deps)

If any check fails:
1. Read the error
2. Fix it
3. Re-run the check
4. Repeat until all pass

---

## Phase 6: Report

```markdown
# Re-Arch Complete

## Restructured
| # | What Changed | Files Created | Files Modified | Build | Tests |
|---|-------------|--------------|---------------|-------|-------|
| 1 | Extracted user business logic | 2 | 1 | Pass | Pass |
| 2 | ... | ... | ... | ... | ... |

## Architecture Before → After
[Brief description of structural improvement]

## Remaining Issues (if any)
- [Issues that need manual architectural decisions]

## Metrics
- Files created: N
- Files modified: M
- God files eliminated: X
- Dependency violations fixed: Y
- Pattern inconsistencies unified: Z
```

---

## Notes

- `git commit` before running `/re-arch` — so you can always revert
- If restructuring is interrupted, run `/re-arch` again — TodoWrite preserves state
- This preserves behavior, not code. File names, locations, and structure may change significantly.
- Tests are your safety net. More tests = safer restructuring.
