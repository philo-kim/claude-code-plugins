# Claude Code Plugins

AI-assisted governance plugins for vibe coders. Build fast, stay healthy.

> "Make invisible problems visible. Don't write code for users — show them what needs attention."

## Quick Install

```bash
git clone https://github.com/philo-kim/claude-code-plugins.git
cd claude-code-plugins
./install.sh <plugin-name>
```

## Available Plugins

| Plugin | What it does | Command | Install |
|--------|-------------|---------|---------|
| [twophone](#twophone) | Cross-platform iOS/Android sync | `/twophone` | `./install.sh twophone` |
| [health](#health) | Project health (security, debt, deps, perf) | `/health` | `./install.sh health` |
| [re-arch](#re-arch) | Rearchitect vibe-coded projects | `/re-arch` | `./install.sh re-arch` |

Each plugin is **one smart command**. AI figures out what's needed from context.

---

## twophone

**Build native iOS (Swift) and Android (Kotlin) apps simultaneously without Flutter.**

One command detects what changed and syncs everything needed.

### Commands

```bash
/twophone                         # Smart sync — detects changes, syncs everything
/twophone init <project-name>     # Initialize new project (first time only)
/twophone release --bump patch    # Version sync and release (deploy time only)
```

### What `/twophone` Does Automatically

- Model changes detected → sync Swift/Kotlin models
- `shared/design-tokens.yaml` changed → regenerate Colors, Typography, Spacing
- `shared/strings.yaml` changed → regenerate localizations
- `shared/routes.yaml` changed → regenerate routing
- `shared/feature-flags.yaml` changed → regenerate feature flags
- New feature on one platform → scaffold on the other
- Asset changes → resize and sync across platforms
- Test gaps → generate test templates
- Version mismatch → sync version numbers

### Swift ↔ Kotlin Pattern Mapping

| Swift | Kotlin |
|-------|--------|
| `struct User: Codable` | `@Serializable data class User` |
| `@Observable` | `ViewModel + StateFlow` |
| `async/await` | `suspend + coroutines` |
| `[T]` | `List<T>` |
| `Bool` | `Boolean` |

### Project Structure

```
my-app/
├── ios/                    # iOS (SwiftUI)
│   └── MyApp/
│       ├── Features/
│       ├── Models/
│       └── Services/
├── android/                # Android (Jetpack Compose)
│   └── app/src/main/
│       ├── features/
│       ├── models/
│       └── services/
├── shared/                 # Shared definitions
│   ├── api-spec.yaml
│   ├── design-tokens.yaml
│   ├── strings.yaml
│   ├── routes.yaml
│   └── feature-flags.yaml
└── .twophone.json          # Project config
```

---

## health

**Project health governor — Security, technical debt, dependencies, and performance in one scan.**

One command checks everything. AI decides what's relevant based on your project type.

### Commands

```bash
/health                           # Smart scan — checks everything applicable
/health init                      # First-time setup (creates .health.yaml)
```

### What `/health` Scans

| Area | Weight | What It Checks |
|------|--------|---------------|
| Security | 30% | Unauthenticated endpoints, hardcoded secrets, injection vectors |
| Technical Debt | 30% | Complexity hotspots, long functions, TODO age, test gaps |
| Dependencies | 20% | Unmaintained packages, license conflicts, duplicates |
| Performance | 20% | Bundle budget, N+1 queries, memory leaks, re-renders |

### Example Output

```
## Project Health: 72/100

보안       ██████░░░░  62  — API 3개 인증 없음, .env 하드코딩 1건
부채       ████████░░  78  — hotspot 2개, TODO 14개 (최고 43일)
의존성     █████████░  85  — 미유지 패키지 1개, 중복 라이브러리 1쌍
성능       ███████░░░  65  — 번들 387KB (예산 300KB 초과)

💡 가장 시급: API /users 엔드포인트에 인증이 없습니다. 의도적인가요?
```

### Supported Languages

JavaScript/TypeScript, Python, Java, Kotlin, Swift, Go, Ruby

---

## re-arch

**Rearchitect vibe-coded projects — evaluate structure, identify problems, restructure with behavior preserved.**

Code works. Structure doesn't. One command reads everything, finds structural problems, and fixes them.

### Commands

```bash
/re-arch                          # Smart mode — scan, report, restructure
/re-arch --report                 # Analysis only, no changes
/re-arch src/services/            # Focus on specific directory
```

### What `/re-arch` Finds and Fixes

| Problem | Example | What It Does |
|---------|---------|-------------|
| God files | Controller with 500 lines doing DB + logic + validation | Split into focused files by responsibility |
| Wrong dependencies | Domain model importing Express types | Introduce interfaces, fix dependency direction |
| Inconsistent patterns | 3 different state management approaches | Unify to dominant pattern |
| Tight coupling | Changing one file breaks 10 others | Introduce boundaries and abstractions |
| Duplicate logic | Same fetch pattern copy-pasted 8 times | Extract shared utility |

### Safety

- Preserves all behavior — restructures structure, not functionality
- Builds after every change — never leaves code broken
- Shows plan before executing — restructures only what you approve
- `git commit` before running — easy revert if needed

---

## Installation

```bash
./install.sh twophone    # Install specific plugin
./install.sh all         # Install all plugins
./install.sh list        # List available plugins
./install.sh uninstall twophone  # Uninstall
```

### Manual Installation

```bash
cp -r plugins/twophone ~/.claude/plugins/
```

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed
- macOS / Linux (Windows WSL supported)

## Philosophy

These plugins share a common design:

1. **One smart command** — AI figures out what's needed from context
2. **Governance, not automation** — Show problems, don't force fixes
3. **Incremental adoption** — Works on existing projects without rewriting
4. **YAML as source of truth** — Human-readable, version-controllable config
5. **Health scores with trends** — Track improvement over time

## Contributing

Contributions are welcome! Feel free to report bugs, suggest features, or create new plugins.

## License

MIT License
