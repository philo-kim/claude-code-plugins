# Secrets Detection Patterns

## Detection Strategy

Scan for patterns that indicate hardcoded credentials, API keys, tokens, or connection strings in source code.

## High-Confidence Patterns

### API Keys & Tokens

```regex
# AWS
(AKIA|ABIA|ACCA|ASIA)[0-9A-Z]{16}
aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}

# Google
AIza[0-9A-Za-z\-_]{35}

# GitHub
gh[pousr]_[A-Za-z0-9_]{36,255}

# Stripe
sk_(live|test)_[A-Za-z0-9]{24,}
pk_(live|test)_[A-Za-z0-9]{24,}

# Slack
xox[baprs]-[0-9a-zA-Z\-]{10,}

# Generic patterns
(api[_-]?key|apikey|api[_-]?secret)\s*[:=]\s*['"][A-Za-z0-9]{16,}['"]
(token|secret|password|passwd|pwd)\s*[:=]\s*['"][^'"]{8,}['"]
```

### Connection Strings

```regex
# Database URLs with credentials
(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@
jdbc:[a-z]+://.*password=[^&\s]+

# Connection strings
(Server|Data Source)=.*Password=[^;]+
```

### Private Keys

```regex
-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----
-----BEGIN OPENSSH PRIVATE KEY-----
```

## File-Based Detection

### Files That Should Never Be Committed

| File Pattern | Risk |
|-------------|------|
| `.env` | Environment variables with secrets |
| `.env.local` | Local overrides with secrets |
| `*.pem`, `*.key` | Private keys |
| `credentials.json` | Service account keys |
| `*.p12`, `*.pfx` | Certificate bundles |
| `id_rsa`, `id_ed25519` | SSH private keys |
| `*.keystore` | Java/Android keystores |
| `service-account*.json` | GCP service accounts |

### .gitignore Check

Verify these patterns exist in `.gitignore`:
```
.env
.env.*
*.pem
*.key
credentials.json
```

## Low-Confidence (Needs Context)

These require human judgment — flag as "needs review":

```
# Could be secrets or could be test data
password = "changeme"           # Likely default/placeholder
API_KEY = "your-key-here"       # Likely placeholder
token = "test-token-123"        # Likely test fixture

# Config files that might contain secrets
config/database.yml             # Check for password fields
application.properties          # Check for credentials
```

## What NOT to Flag

- Environment variable references: `process.env.API_KEY`, `os.environ['SECRET']`
- Placeholder/example values in documentation
- Test fixtures with obviously fake data
- Hash values (SHA256, bcrypt outputs)
