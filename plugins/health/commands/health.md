---
description: Smart project health scan - detects context and checks everything
argument-hint: [--quick | --focus <area> | --since <date>]
---

# /health — Smart Project Health Scan

One command. Four areas. AI decides what matters.

## How It Works

`/health` reads your project, detects what's there, and scans everything relevant. No configuration required — but `.health.yaml` lets you tune thresholds if you want.

## Default Behavior (No Arguments)

```
1. Check for .health.yaml
   - Exists → Use configured thresholds
   - Missing → Use sensible defaults (suggest /health init)

2. Detect project type, language, framework

3. Determine what to scan:
   - Has routes/endpoints? → Security scan
   - Has source code? → Debt scan (always)
   - Has dependency manifest? → Dependency scan
   - Has build output or bundle? → Performance scan

4. Run health-scanner agent on all applicable areas

5. Generate unified report with scores and recommendations
```

## Options

- (no args): Full smart scan — checks everything applicable
- `--quick`: Critical issues only — skip warnings, skip trends
- `--focus <area>`: Focus on one area: `security`, `debt`, `deps`, `perf`
- `--since <date>`: Compare with specific previous scan
- `--ci`: Machine-readable output, exit code 1 if score below threshold

## Analysis Areas

### Security (Weight: 30%)

Scans for governance gaps in authentication, secrets, and input validation.

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

Measures code complexity, change patterns, and maintenance signals.

| Check | Severity | What |
|-------|----------|------|
| Complexity hotspot (churn × complexity) | Critical | Files that change often AND are complex |
| Function > 200 lines | Critical | Extremely long functions |
| Class > 1000 lines | Critical | God classes |
| Function > 50 lines | Warning | Long functions |
| Nesting > 4 levels | Warning | Deep conditional chains |
| TODO older than 30 days | Warning | Forgotten tasks |
| No tests for high-complexity files | Warning | Untested risky code |

### Dependencies (Weight: 20%)

Checks package health, licensing, and bloat.

| Check | Severity | What |
|-------|----------|------|
| GPL/AGPL in commercial project | Critical | License compliance risk |
| Known critical vulnerability | Critical | Security advisory match |
| Package unmaintained 36+ months | Critical | Abandoned dependency |
| Package unmaintained 18+ months | Warning | Aging dependency |
| Duplicate library purpose | Warning | Multiple packages for same task |
| Bundle over budget | Warning | Total size exceeds threshold |

### Performance (Weight: 20%)

Detects patterns that cause slowness or resource waste.

| Check | Severity | What |
|-------|----------|------|
| N+1 query pattern | Critical | Database call inside loop |
| Bundle 50%+ over budget | Critical | Severely oversized |
| Memory leak pattern | Warning | addEventListener without cleanup |
| Unnecessary re-render | Warning | React component without memoization |
| Large unoptimized assets | Warning | Images > 500KB |
| Bundle 10-50% over budget | Warning | Approaching limit |

## Output Format

```markdown
## Project Health: 72/100 (↓3)

보안       ██████░░░░  62  — API 3개 인증 없음, .env 하드코딩 1건
부채       ████████░░  78  — hotspot 2개, TODO 14개 (최고 43일)
의존성     █████████░  85  — 미유지 패키지 1개, 중복 라이브러리 1쌍
성능       ███████░░░  65  — 번들 387KB (예산 300KB 초과)

### Critical (즉시 조치)

| # | 영역 | 위치 | 문제 | 권장 조치 |
|---|------|------|------|-----------|
| 1 | 보안 | routes/admin.ts:12 | /admin/users 인증 없음 | auth middleware 추가 |
| 2 | 보안 | config/db.ts:5 | DB 비밀번호 하드코딩 | 환경변수로 이동 |
| 3 | 부채 | services/Order.ts | 847줄, 복잡도 42 | 책임별로 분리 |

### Warning (계획 필요)

| # | 영역 | 위치 | 문제 |
|---|------|------|------|
| 1 | 의존성 | moment@2.29.4 | 3년간 미업데이트 |
| 2 | 성능 | dist/main.js | 387KB (예산 300KB) |
| 3 | 부채 | utils/helpers.ts:23 | TODO: 43일 경과 |

### 추세

| 영역 | 이전 | 현재 | 변화 |
|------|------|------|------|
| 보안 | 65 | 62 | ↓ -3 |
| 부채 | 75 | 78 | ↑ +3 |
| 의존성 | 85 | 85 | → 0 |
| 성능 | 68 | 65 | ↓ -3 |

### Top 3 권장 조치

1. admin 라우트에 인증 미들웨어 추가 (보안 +8점 예상)
2. OrderService 분리 (부채 +5점 예상)
3. moment → dayjs 교체 (의존성 +3점, 성능 +5점 예상)
```

## Configuration (.health.yaml)

Run `/health init` to generate, or create manually. See template for all options.

Key settings:
- `scoring.weights` — Adjust area importance
- `security.allowed_public_endpoints` — Don't flag intentionally public routes
- `debt.max_function_lines` — Adjust for your team's standards
- `dependencies.allowed_licenses` — Define acceptable licenses
- `performance.bundle_budget_kb` — Set your bundle budget
- `ignore` — Exclude paths from scanning

## Saving Reports

Reports are automatically saved to `shared/health-reports/[date].md` for trend tracking.

## CI/CD Integration

```yaml
# .github/workflows/health.yml
- name: Health Check
  run: claude "/health --ci"
  env:
    HEALTH_MIN_SCORE: 70
    HEALTH_FAIL_ON_CRITICAL: true
```

## First Run

If `.health.yaml` doesn't exist, `/health` will:
1. Run with sensible defaults
2. Show results
3. Suggest running `/health init` for customization
