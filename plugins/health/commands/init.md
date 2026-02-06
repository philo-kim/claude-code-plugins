---
description: Initialize health governance for this project
argument-hint: [--force]
---

# Health Init

Set up health governance for an existing project. Creates `.health.yaml` with sensible defaults based on your stack.

## What It Does

1. **Scans your project** to detect language, framework, and structure
2. **Creates `.health.yaml`** with pre-configured thresholds
3. **Runs first health scan** so you see your baseline immediately

## Execution Steps

### Step 1: Project Detection

```
1. Scan root directory for project indicators:
   - package.json → Node.js project
   - requirements.txt / pyproject.toml → Python project
   - build.gradle / pom.xml → Java/Kotlin project
   - Package.swift / *.xcodeproj → iOS project
   - go.mod → Go project
   - Gemfile → Ruby project

2. Detect framework from dependencies:
   - next, react → Next.js / React
   - express, koa, fastify → Express / Koa / Fastify
   - @nestjs/core → NestJS
   - django → Django
   - flask → Flask
   - fastapi → FastAPI
   - spring-boot → Spring Boot
   - ktor → Ktor
   - rails → Rails

3. Detect project type:
   - Has routes/controllers + views/templates → Web app
   - Has routes/controllers only → API server
   - Has ios/ + android/ → Cross-platform mobile
   - Has lib/ + test/ + *.podspec → Library
   - Has multiple package.json → Monorepo
```

### Step 2: Generate .health.yaml

Based on detection results, create `.health.yaml` from template with:

- **Language & framework** filled in
- **Thresholds adjusted** for the framework:
  - Spring Boot projects: higher service line limits (Java is verbose)
  - React projects: re-render checks enabled
  - Express projects: auth middleware patterns configured
  - Django projects: ORM N+1 patterns configured
- **Ignore paths** adjusted for the ecosystem:
  - Node.js: `node_modules`, `dist`, `.next`
  - Python: `venv`, `__pycache__`, `.mypy_cache`
  - Java: `target`, `build`, `.gradle`
  - iOS: `Pods`, `DerivedData`, `.build`
- **Sensitive paths** seeded from detected patterns

### Step 3: Run First Scan

Automatically invoke the health-scanner agent with:
- `--baseline` flag to mark this as the initial measurement
- Full output displayed to console
- Report saved to `shared/health-reports/[date].md`

## Output

```markdown
# Health Init Complete

Detected: TypeScript / NestJS / API Server
Config: .health.yaml created

## Baseline Health: 73/100

보안       ███████░░░  68  — 2 endpoints without auth
부채       ████████░░  78  — 3 hotspots, 8 TODOs
의존성     █████████░  82  — 1 outdated package
성능       ███████░░░  65  — Bundle 340KB (budget: 300KB)

This is your baseline. Run /health anytime to track changes.
```

## Options

- `--force`: Overwrite existing `.health.yaml`

## Notes

- If `.health.yaml` already exists, aborts with a message (use `--force` to overwrite)
- Creates `shared/health-reports/` directory if it doesn't exist
- Safe to run — only creates config files, never modifies source code
