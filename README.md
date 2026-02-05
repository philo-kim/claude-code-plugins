# Claude Code Plugins

A collection of useful plugins for [Claude Code](https://claude.ai/claude-code) - Anthropic's official CLI for Claude.

## Quick Install

```bash
git clone https://github.com/philo-kim/claude-code-plugins.git
cd claude-code-plugins
./install.sh <plugin-name>
```

## Available Plugins

| Plugin | Description | Install |
|--------|-------------|---------|
| [twophone](#twophone) | iOS/Android simultaneous development without Flutter | `./install.sh twophone` |
| [ddd](#ddd) | Domain-Driven Design management for existing codebases | `./install.sh ddd` |

---

## twophone

**Build native iOS (Swift) and Android (Kotlin) apps simultaneously without Flutter.**

A Claude Code plugin designed for "vibe coders" who want to develop for both mobile platforms using AI assistance.

### Features

- 🚀 **Project Scaffolding** - Create iOS/Android project structure at once
- 🔄 **Code Sync** - Sync changes between Swift and Kotlin
- 📦 **Model Generation** - Generate models from OpenAPI specs for both platforms
- 🎨 **Design System Sync** - Sync colors, typography, spacing
- 🌍 **Localization Sync** - Unified i18n for both platforms
- 🔗 **Deep Link/Routing** - Configure routes for iOS and Android
- 🔔 **Push Notifications** - FCM setup for both platforms
- 🚩 **Feature Flags** - Firebase Remote Config integration
- 📦 **Asset Management** - Resize and sync assets
- 🏷️ **Version Sync** - Keep version numbers in sync
- 🧪 **Test Generation** - Generate tests for both platforms
- ⚡ **Full Auto** - Run all essential syncs at once

### Commands

```bash
/twophone init <project-name>     # Initialize new project
/twophone sync <file>             # Sync code changes
/twophone model <openapi.yaml>    # Generate models from API spec
/twophone scaffold <feature>      # Generate feature structure
/twophone auto                    # Full auto sync
/twophone design-system           # Sync design tokens
/twophone localize                # Sync localizations
/twophone routes                  # Sync deep links/routing
/twophone push --setup            # Setup push notifications
/twophone feature-flag --sync     # Sync feature flags
/twophone assets                  # Sync assets
/twophone release --bump patch    # Bump version
/twophone test --sync             # Sync tests
```

### Swift ↔ Kotlin Pattern Mapping

The plugin includes comprehensive pattern mapping:

| Swift | Kotlin |
|-------|--------|
| `struct User: Codable` | `@Serializable data class User` |
| `@Observable` | `ViewModel + StateFlow` |
| `async/await` | `suspend + coroutines` |
| `[T]` | `List<T>` |
| `Bool` | `Boolean` |
| `T?` | `T?` |

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
│   ├── api/
│   ├── design-tokens.yaml
│   ├── strings.yaml
│   └── routes.yaml
└── .twophone.json          # Project config
```

---

## ddd

**Introduce and maintain DDD governance for existing codebases.**

A Claude Code plugin for managing Domain-Driven Design in projects that weren't built with DDD in mind. This plugin does NOT generate application code - it creates management artifacts and provides guidance for maintaining healthy domain models.

### Key Philosophy

> "Maintain healthy domain models over time with AI assistance"

What this plugin does:
- Creates DDD management files (`.ddd.yaml`, `glossary.yaml`, `context-map.md`)
- Provides deep health monitoring (Anemic Model, Transaction Script detection)
- Offers refactoring guidance (not automatic code changes)

What this plugin does NOT do:
- Generate application code
- Scaffold new projects
- Auto-refactor code

### Features

- **Deep Health Checks** - Detect Anemic Models, Transaction Scripts, God Classes
- **Aggregate Analysis** - Validate size, boundaries, identity references
- **Layer Architecture** - Ensure domain independence from infrastructure
- **Domain Event Coverage** - Track state changes that should emit events
- **Bounded Context Isolation** - Detect context leaks and missing ACLs
- **Ubiquitous Language** - Manage glossary and naming consistency
- **Multi-Language Support** - TypeScript, Java, Kotlin, Python, Go, C#

### Commands

```bash
/ddd analyze [path]           # Analyze codebase, create management files
/ddd health [--full|--quick]  # Deep DDD health check
/ddd glossary [subcommand]    # Manage ubiquitous language
/ddd validate [target]        # Validate DDD principles
/ddd refactor <type> [target] # Get refactoring guidance
```

### Health Checks Include

| Check | Description |
|-------|-------------|
| Anemic Model | Detects entities with no business logic |
| Transaction Script | Finds God Classes with procedural code |
| Aggregate Size | Validates Vernon's aggregate rules |
| Layer Violations | Finds framework code in domain |
| Event Coverage | Measures domain event adoption |
| Context Isolation | Detects cross-context dependencies |
| Naming Consistency | Compares code with glossary |

### Refactoring Guides

```bash
/ddd refactor anemic Order          # Anemic → Rich Model guide
/ddd refactor split OrderService    # Break up God Class
/ddd refactor extract-vo Order      # Extract Value Objects
/ddd refactor add-event Order       # Add Domain Events
/ddd refactor fix-layer Order       # Fix layer violations
```

### Project Structure (Generated)

```
my-project/
├── .ddd.yaml              # DDD project configuration
└── shared/
    ├── glossary.yaml      # Ubiquitous language terms
    ├── context-map.md     # Bounded context relationships
    └── health-reports/    # Historical health reports
        └── 2024-01-15.md
```

### Example Health Report

```markdown
## DDD Health: 58/100 (↓7)

| Category | Score | Issues |
|----------|-------|--------|
| Anemic Model | 20/100 | 3 critical |
| Transaction Script | 30/100 | 2 critical |
| Aggregate Health | 65/100 | 4 warnings |
| Layer Architecture | 40/100 | 2 critical |

### Critical Issues
- Order.ts: Anemic Model (0 business methods)
- OrderService.ts: Transaction Script (847 lines)
```

---

## Installation

### Install specific plugin

```bash
./install.sh twophone
```

### Install all plugins

```bash
./install.sh all
```

### List available plugins

```bash
./install.sh list
```

### Uninstall a plugin

```bash
./install.sh uninstall twophone
```

## Manual Installation

Copy the plugin folder to your Claude plugins directory:

```bash
cp -r plugins/twophone ~/.claude/plugins/
```

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed
- macOS / Linux (Windows WSL supported)

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Create new plugins

## License

MIT License - feel free to use in your projects.

---

Made with ❤️ for developers who want AI-assisted development workflows.
