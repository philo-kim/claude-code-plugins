# Dependency Risk Analysis

## Detection Strategy

Analyze dependency manifests (package.json, requirements.txt, build.gradle, etc.) for risk indicators.

## Risk Categories

### 1. Unmaintained Packages

**Detection**: Check last publish date or last commit.

```
Warning: Package not updated in 18+ months
Critical: Package not updated in 36+ months or archived

Example:
  moment@2.29.4 — Last publish: 2022-07-06 (3+ years ago)
  Status: Effectively unmaintained
  Alternative: dayjs, date-fns
```

**How to check**:
```bash
# npm
npm outdated --long
npm view <package> time

# pip
pip list --outdated

# gradle
./gradlew dependencyUpdates
```

### 2. License Conflicts

**Allowed licenses** (typical for commercial projects):
- MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC

**Problematic licenses**:
| License | Risk | Issue |
|---------|------|-------|
| GPL-2.0 | Critical | Copyleft — must open-source your code |
| GPL-3.0 | Critical | Copyleft — must open-source your code |
| AGPL-3.0 | Critical | Network copyleft — even SaaS must open-source |
| SSPL | Critical | Server-side copyleft |
| Unlicensed | Warning | No permission granted |
| WTFPL | Warning | Legally questionable |

**Detection**:
```bash
# npm
npx license-checker --summary

# pip
pip-licenses

# gradle
./gradlew generateLicenseReport
```

### 3. Duplicate Libraries

Common duplications to detect:

| Purpose | Packages | Issue |
|---------|----------|-------|
| Date handling | moment + dayjs + date-fns | Pick one |
| HTTP client | axios + node-fetch + got | Pick one |
| Utility | lodash + underscore + ramda | Pick one |
| CSS-in-JS | styled-components + emotion | Pick one |
| State management | redux + mobx + zustand | Pick one |
| Validation | joi + yup + zod | Pick one |
| Testing | jest + mocha + vitest | Pick one |

**Detection**: Map packages to categories, flag when multiple packages serve the same purpose.

### 4. Bundle Size Impact

**Detection**: Analyze package sizes and their contribution to the final bundle.

```
Bundle Analysis:
  Total: 387KB (budget: 300KB) — OVER BUDGET

  Top contributors:
  1. lodash        — 71KB  (18%)  → Consider lodash-es or individual imports
  2. moment        — 67KB  (17%)  → Consider dayjs (2KB)
  3. @mui/material — 45KB  (12%)  → Tree-shaking configured?
  4. chart.js      — 38KB  (10%)  → Consider lightweight alternative
```

**How to check**:
```bash
# npm
npx bundlephobia <package>
npx webpack-bundle-analyzer

# General
npx source-map-explorer dist/main.js
```

### 5. Known Vulnerabilities

**Detection**:
```bash
# npm
npm audit

# pip
pip-audit
safety check

# gradle
./gradlew dependencyCheckAnalyze
```

Report format:
```
Vulnerability: prototype-pollution in lodash < 4.17.21
  Severity: High
  Package: lodash@4.17.15
  Fix: npm update lodash
```

## Package Ecosystem Detection

| File | Ecosystem | Tool |
|------|----------|------|
| package.json | npm/Node.js | npm audit, npm outdated |
| requirements.txt / pyproject.toml | pip/Python | pip-audit, pip list --outdated |
| Gemfile | RubyGems | bundle audit, bundle outdated |
| build.gradle / build.gradle.kts | Gradle/Java/Kotlin | dependencyUpdates |
| go.mod | Go modules | go list -m -u all |
| Package.swift | SwiftPM | swift package update --dry-run |
| Podfile | CocoaPods | pod outdated |

## Severity Classification

| Risk | Severity | Example |
|------|----------|---------|
| Known critical vulnerability | Critical | RCE, SQL injection in dependency |
| GPL in commercial project | Critical | Legal compliance failure |
| Package unmaintained 36+ months | Critical | No security patches |
| Bundle 50%+ over budget | Critical | Performance impact |
| Package unmaintained 18+ months | Warning | Aging risk |
| Duplicate library purpose | Warning | Unnecessary bloat |
| Bundle 10-50% over budget | Warning | Approaching limit |
| Minor vulnerability | Warning | Low exploitability |
