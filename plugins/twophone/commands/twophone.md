---
description: Smart cross-platform sync - detects changes and syncs everything needed
argument-hint: [file-path | --full]
---

# /twophone — Smart Cross-Platform Sync

One command. AI detects what changed and syncs what's needed.

## How It Works

`/twophone` scans your project, detects changes since the last sync, and automatically runs all necessary synchronization tasks. No need to remember which command to use.

## Default Behavior (No Arguments)

```
1. Read .twophone.json (suggest /twophone init if missing)
2. Detect changes via git diff / git status
3. Determine what needs syncing
4. Execute applicable sync tasks
5. Validate with sync-reviewer agent
6. Report results
```

## Options

- (no args): Smart mode — detect and sync everything needed
- `<file-path>`: Sync a specific file between platforms
- `--full`: Full regeneration of all synced files (backs up first)

---

## Phase 1: Project Analysis

```
1. Read .twophone.json for project configuration
2. Scan iOS/Android directory structure
3. Detect changed files:
   - git diff --name-only (uncommitted changes)
   - git diff HEAD~1 --name-only (recent commit)
4. Categorize changes by type
5. Identify missing files/configurations
```

## Phase 2: Smart Sync

Execute only the tasks that are needed based on detected changes.

### Model Sync

**Trigger**: Changes in `Models/*.swift`, `models/*.kt`, or `shared/api-spec.yaml`

- Compare model files between iOS and Android
- If API spec changed: regenerate models for both platforms
- If one platform changed: convert and sync to the other

**Type mapping** (Swift ↔ Kotlin):

| Swift | Kotlin |
|-------|--------|
| `struct X: Codable, Hashable, Sendable` | `@Serializable data class X` |
| `let` / `var` | `val` / `var` |
| `String`, `Int`, `Double`, `Bool` | `String`, `Int`, `Double`, `Boolean` |
| `T?` | `T?` (with `= null` default) |
| `[T]` | `List<T>` |
| `[K: V]` | `Map<K, V>` |
| `Date` | `String` (with `@SerialName`) |
| `UUID` | `String` |
| `enum CodingKeys` | `@SerialName` annotations |

### Service/API Sync

**Trigger**: Changes in `Services/*.swift` or `services/*.kt`

- Compare service methods between platforms
- Convert async patterns: `async/await` ↔ `suspend/coroutines`
- Verify endpoint consistency
- Generate missing methods

**Pattern mapping**:

| Swift | Kotlin |
|-------|--------|
| `actor APIClient` | `object ApiClient` |
| `async throws -> T` | `suspend fun(): T` |
| `URLSession.shared.data(from:)` | `client.get().body()` |
| `Task { }` | `viewModelScope.launch { }` |

### Design Token Sync

**Trigger**: Changes in `shared/design-tokens.yaml`

- Parse YAML for colors, typography, spacing, radius
- Generate iOS: `Colors.swift`, `Typography.swift`, `Spacing.swift`
- Generate Android: `Color.kt`, `Type.kt`, `Spacing.kt`

### Localization Sync

**Trigger**: Changes in `shared/strings.yaml`

- Parse hierarchical YAML structure
- Generate iOS: `*.lproj/Localizable.strings` + type-safe `Strings.swift`
- Generate Android: `values-*/strings.xml`
- Warn about missing keys in any language

### Route Sync

**Trigger**: Changes in `shared/routes.yaml`

- Parse route definitions (scheme, paths, params)
- Generate iOS: Router enum + URL handling extensions
- Generate Android: Sealed Route class + NavGraph configuration

### Feature Flag Sync

**Trigger**: Changes in `shared/feature-flags.yaml`

- Parse flag definitions (name, type, default value)
- Generate iOS: `@Observable` class with `RemoteConfig`
- Generate Android: Object singleton with `MutableStateFlow`

### Asset Sync

**Trigger**: Changes in `shared/assets/` or platform asset directories

- Detect new/changed images and icons
- Generate iOS: Asset catalog entries (1x/2x/3x)
- Generate Android: drawable resources (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi)
- Map icon names: SF Symbols ↔ Material Icons
- Warn about missing resolutions

### Scaffold Detection

**Trigger**: New feature directory detected on one platform but not the other

- Detect MVVM structure (View/Screen + ViewModel) on one platform
- Generate corresponding structure on the other platform
- iOS: `*View.swift` + `*ViewModel.swift` (SwiftUI + @Observable)
- Android: `*Screen.kt` + `*ViewModel.kt` (Compose + StateFlow)

### Test Sync

**Trigger**: Test files exist on one platform but not the other

- Detect test files and their corresponding source files
- Generate test templates for the other platform
- iOS: XCTest with async test patterns
- Android: JUnit + kotlinx-coroutines-test

### Push Notification Check

**Trigger**: FCM configuration files detected or changed

- Verify `GoogleService-Info.plist` (iOS) and `google-services.json` (Android)
- Check notification handling code on both platforms
- Warn about missing notification setup

### Version Sync

**Trigger**: Version mismatch between `.twophone.json`, Info.plist, build.gradle

- Read version from `.twophone.json`
- Compare with iOS `Info.plist` and Android `build.gradle`
- Update if mismatched

## Phase 3: Validation

Invoke **sync-reviewer agent** to verify:
- Model field matching across platforms
- API endpoint consistency
- Type compatibility
- Missing counterpart files

## Phase 4: Report

```markdown
# TwoPhone Sync Complete

## Executed
✅ Model sync: 5 files (2 new, 3 updated)
✅ Design tokens: 15 colors, 4 fonts, 6 spacing
✅ Localization: 2 languages, 45 keys
✅ Version sync: 1.2.0 (build 42)

## Skipped (no changes detected)
⏭️ Routes, Feature flags, Assets, Push

## Manual Review Required
⚠️ ProfileService.swift — Complex async logic, verify Kotlin conversion
⚠️ analytics_icon.png — Missing 3x resolution

## Platform Parity
| Category | iOS | Android | Status |
|----------|-----|---------|--------|
| Models | 8 | 8 | ✅ In sync |
| Services | 5 | 4 | ⚠️ 1 missing |
| Features | 6 | 6 | ✅ In sync |
| Tests | 3 | 1 | ⚠️ 2 missing |
```

## Configuration (.twophone.json)

```json
{
  "projectName": "MyApp",
  "version": "1.2.0",
  "build": 42,
  "auto": {
    "syncModels": true,
    "syncServices": true,
    "syncAssets": true,
    "syncStrings": true,
    "syncDesignTokens": true,
    "syncVersion": true,
    "ignorePaths": [
      "ios/MyApp/Generated/*",
      "android/app/src/main/java/*/generated/*"
    ]
  },
  "platforms": {
    "ios": {
      "path": "ios/MyApp",
      "bundleId": "com.example.myapp"
    },
    "android": {
      "path": "android/app",
      "packageName": "com.example.myapp"
    }
  }
}
```

## Notes

- Recommend `git commit` before running with `--full`
- `--full` mode backs up existing files with `.backup` extension
- Asks confirmation on conflicts
- Specific file sync: `/twophone path/to/file.swift` syncs just that file
