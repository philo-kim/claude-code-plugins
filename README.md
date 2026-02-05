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

Made with ❤️ for vibe coders who want native mobile apps without Flutter.
