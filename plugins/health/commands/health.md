---
description: Smart project health scan - detects context and checks everything
argument-hint: [--quick | --focus <area> | --since <date>]
---

# /health — Smart Project Health Scan

One command. Four areas. AI scans, reports, and fixes what you approve.

## Core Principles

- **Use TodoWrite**: Create a checklist of all scan and fix tasks. Update as you progress.
- **Agent delegation**: Use health-scanner agent for analysis, health-fixer agent for fixes.
- **Ask before fixing**: Always show the report first. Only fix after user approval.
- **Never stop after analysis**: If fixable issues are found and the user approves, proceed to fix them.

## Options

- (no args): Full smart scan — checks everything, then offers to fix
- `--quick`: Critical issues only — skip warnings, skip trends
- `--focus <area>`: Focus on one area: `security`, `debt`, `deps`, `perf`
- `--since <date>`: Compare with specific previous scan
- `--ci`: Machine-readable output, exit code 1 if score below threshold (no fixes)

---

## Phase 1: Discovery

**Goal**: Understand what to scan

**Actions**:
1. Create TodoWrite checklist with all phases
2. Check for `.health.yaml`
   - Exists → use configured thresholds
   - Missing → use sensible defaults (suggest `/health init`)
3. Detect project type, language, framework
4. Determine applicable scans:
   - Has routes/endpoints? → Security scan
   - Has source code? → Debt scan (always)
   - Has dependency manifest? → Dependency scan
   - Has build output or bundle? → Performance scan
5. Load previous health report for trend comparison

---

## Phase 2: Deep Analysis

**Goal**: Comprehensive health scan

Launch **health-scanner agent** on all applicable areas:

### Security (Weight: 30%)

| Check | Severity | What |
|-------|----------|------|
| Unauthenticated endpoints | Critical | Routes missing auth middleware |
| Hardcoded secrets | Critical | API keys, passwords in source |
| SQL injection vectors | Critical | String interpolation in queries |
| Command injection | Critical | User input in exec/system calls |
| XSS vectors | Critical | Raw user input in HTML output |
| Missing .gitignore for secrets | Warning | .env, *.key not in .gitignore |
| Permissive CORS | Warning | `Access-Control-Allow-Origin: *` |
| Verbose error messages | Warning | Stack traces in production responses |

### Technical Debt (Weight: 30%)

| Check | Severity | What |
|-------|----------|------|
| Complexity hotspot (churn x complexity) | Critical | Files that change often AND are complex |
| Function > 200 lines | Critical | Extremely long functions |
| Class > 1000 lines | Critical | God classes |
| Function > 50 lines | Warning | Long functions |
| Nesting > 4 levels | Warning | Deep conditional chains |
| TODO older than 30 days | Warning | Forgotten tasks |
| No tests for high-complexity files | Warning | Untested risky code |

### Dependencies (Weight: 20%)

| Check | Severity | What |
|-------|----------|------|
| GPL/AGPL in commercial project | Critical | License compliance risk |
| Known critical vulnerability | Critical | Security advisory match |
| Package unmaintained 36+ months | Critical | Abandoned dependency |
| Package unmaintained 18+ months | Warning | Aging dependency |
| Duplicate library purpose | Warning | Multiple packages for same task |
| Bundle over budget | Warning | Total size exceeds threshold |

### Performance (Weight: 20%)

| Check | Severity | What |
|-------|----------|------|
| N+1 query pattern | Critical | Database call inside loop |
| Bundle 50%+ over budget | Critical | Severely oversized |
| Memory leak pattern | Warning | addEventListener without cleanup |
| Unnecessary re-render | Warning | React component without memoization |
| Large unoptimized assets | Warning | Images > 500KB |
| Bundle 10-50% over budget | Warning | Approaching limit |

---

## Phase 3: Report

Present the full report:

```markdown
## Project Health: 72/100 (trend)

보안       [BAR]  62  — summary
부채       [BAR]  78  — summary
의존성     [BAR]  85  — summary
성능       [BAR]  65  — summary

### Critical (Immediate Action)
| # | Area | Location | Issue | Recommendation |
|---|------|----------|-------|----------------|

### Warning (Plan Needed)
| # | Area | Location | Issue |
|---|------|----------|-------|

### Auto-Fixable Issues
| # | Area | Issue | Fix | Risk |
|---|------|-------|-----|------|
| 1 | Security | .env not in .gitignore | Add .env to .gitignore | None |
| 2 | Security | Hardcoded DB password in config/db.ts | Move to environment variable | Low |
| 3 | Debt | 5 TODOs older than 30 days | Remove resolved, create issues for remaining | None |
| 4 | Security | CORS allows all origins | Restrict to specific domains | Low |
| 5 | Perf | Missing cleanup on event listeners | Add removeEventListener in cleanup | Low |

### Trend
| Area | Previous | Current | Change |
|------|----------|---------|--------|
```

**CRITICAL**: After the report, always ask:

> "Auto-fixable issues found. Fix them now?"
> - Fix all auto-fixable issues
> - Choose which to fix
> - Skip (report only)

---

## Phase 4: Execute Fixes

**CRITICAL**: Only proceed after user approval from Phase 3.

Launch **health-fixer agent** with the approved fix list. The agent will:

### Fixable Issue Types

| Issue Type | What the Agent Does |
|------------|-------------------|
| **Missing .gitignore entries** | Add .env, *.key, credentials.* to .gitignore |
| **Hardcoded secrets** | Move to .env file, replace with `process.env.VAR` / `os.environ` |
| **Missing auth middleware** | Add auth guard/middleware to unprotected routes |
| **Permissive CORS** | Replace wildcard with specific allowed origins |
| **Old TODOs** | Remove resolved TODOs, create GitHub issues for remaining |
| **Missing event cleanup** | Add removeEventListener / unsubscribe in cleanup functions |
| **Missing .env.example** | Create .env.example with variable names (no values) |
| **Verbose error messages** | Replace stack traces with generic messages in production |

### Fix Execution Pattern

For each approved fix:
1. Show the specific change preview (before/after)
2. Create/modify the file
3. Mark TodoWrite item complete

### Safety Rules

- **Non-destructive**: Never delete code without replacement
- **Backup first**: Create `.health-backup/` before modifying
- **Security-sensitive**: For auth/secrets fixes, always show the full change before applying
- **Scope-limited**: Only fix issues identified in Phase 2 — no "while I'm here" improvements

---

## Phase 5: Summary

After all fixes (or if user chose report-only):

```markdown
# Health Scan Complete

## Score: 72/100 (trend)

## Fixed (if applicable)
- [list each fix with file path]
- Expected score improvement: +N points

## Remaining Critical Issues
- [issues requiring manual attention]

## Recommended Next Steps
1. [Most impactful manual action]
2. [Second most impactful]
3. [Third most impactful]
```

Save report to `shared/health-reports/[date].md`.

---

## Configuration (.health.yaml)

Run `/health init` to generate, or create manually. Key settings:

- `scoring.weights` — Adjust area importance
- `security.allowed_public_endpoints` — Don't flag intentionally public routes
- `debt.max_function_lines` — Adjust for your team's standards
- `dependencies.allowed_licenses` — Define acceptable licenses
- `performance.bundle_budget_kb` — Set your bundle budget
- `ignore` — Exclude paths from scanning

## First Run

If `.health.yaml` doesn't exist, `/health` will:
1. Run with sensible defaults
2. Show results
3. Suggest running `/health init` for customization

## CI/CD Integration

```yaml
# .github/workflows/health.yml
- name: Health Check
  run: claude "/health --ci"
  env:
    HEALTH_MIN_SCORE: 70
    HEALTH_FAIL_ON_CRITICAL: true
```
