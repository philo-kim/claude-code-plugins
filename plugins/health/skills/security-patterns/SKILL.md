---
name: Security Patterns
description: When analyzing security posture, checking authentication, detecting secrets, or validating input handling
version: 1.0.0
---

# Security Patterns

Knowledge base for detecting security governance gaps in codebases.

## When to Use

- "check security", "find vulnerabilities", "auth missing"
- "hardcoded secrets", "API key exposed", "env file"
- "input validation", "SQL injection", "XSS"

## Key Principles

1. **Authentication Coverage** — Every non-public endpoint must have explicit auth
2. **Secrets Management** — No credentials in source code, ever
3. **Input Boundaries** — All external input must be validated at entry points
4. **Attack Surface Awareness** — Know every path external data can take

## Detection Capabilities

| Category | What We Detect | Reference |
|----------|---------------|-----------|
| Authentication | Missing auth middleware, unprotected routes, broken access control | [auth-patterns.md](references/auth-patterns.md) |
| Secrets | Hardcoded API keys, passwords, tokens, connection strings | [secrets-detection.md](references/secrets-detection.md) |
| Input Validation | Missing sanitization, SQL injection, XSS, command injection vectors | [input-validation.md](references/input-validation.md) |

## Framework-Specific Knowledge

| Framework | Auth Pattern | Common Gaps |
|-----------|-------------|-------------|
| Express/Koa | Middleware chain | Missing auth on new routes |
| NestJS | Guards/Decorators | @Public() overuse |
| Django | Decorators/Mixins | Missing @login_required |
| Spring Boot | SecurityFilterChain | Overly permissive matchers |
| Rails | before_action | skip_before_action overuse |
| FastAPI | Depends() | Missing dependency injection |

## Severity Classification

- **Critical**: Hardcoded secrets, SQL injection, unauthenticated admin endpoints
- **Warning**: Missing CSRF, permissive CORS, verbose error messages
- **Info**: Missing security headers, no rate limiting
