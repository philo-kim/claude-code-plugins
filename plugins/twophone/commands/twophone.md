---
description: Smart cross-platform sync - detects changes and syncs everything needed
argument-hint: [file-path | --full]
---

# /twophone — Smart Cross-Platform Sync

One command. AI detects what changed and syncs what's needed.

## Core Principles

- **Use TodoWrite**: Create a checklist of ALL sync tasks before starting. Update as you progress.
- **Agent delegation**: Use auto-sync agent for file creation, sync-reviewer agent for validation.
- **Ask before large changes**: If more than 10 files need creation, confirm with the user first.
- **Never stop after analysis**: Analysis is Phase 1. The main job is Phase 2 (creating files).

## Options

- (no args): Smart mode — detect and sync everything needed
- `<file-path>`: Sync a specific file between platforms
- `--full`: Full regeneration of all synced files (backs up first)

---

## Phase 1: Discovery

**Goal**: Understand what needs syncing

**Actions**:
1. Create a TodoWrite checklist with all phases
2. Read `.twophone.json` for project configuration
   - If missing → suggest `/twophone init` and stop
3. Scan iOS and Android directory structures
4. Detect changes:
   - `git diff --name-only` (uncommitted)
   - `git diff HEAD~1 --name-only` (recent commit)
   - Compare platform file counts for parity gaps
5. Build complete list of what needs syncing

Present summary to user:

```
Found: X files changed, Y files missing on iOS, Z files missing on Android
Sync tasks: [list each task]
```

**Ask user**: "Proceed with sync?" (if more than 10 files)

---

## Phase 2: Sync Execution

**Goal**: Create and update all necessary files

**CRITICAL**: This is the main phase. Do NOT skip or abbreviate.

Launch **auto-sync agent** with clear instructions:
- Pass the list of tasks identified in Phase 1
- Agent has Write, Edit, Glob, Grep, Bash tools — it will create the actual files
- Agent follows Swift ↔ Kotlin conversion patterns from the swift-kotlin-patterns skill

If syncing a single file (`/twophone path/to/file`):
- Read the source file
- Convert using type/pattern mapping
- Create the target file directly (no agent needed for single file)

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
| `async throws -> T` | `suspend fun(): T` |
| `@Observable` | `ViewModel + StateFlow` |

**Sync categories** (execute only what's needed):

| Trigger | Action |
|---------|--------|
| Model files changed/missing | Convert and create model counterparts |
| Service files changed/missing | Convert async patterns, create counterparts |
| `shared/design-tokens.yaml` changed | Generate platform-specific color/typography/spacing files |
| `shared/strings.yaml` changed | Generate Localizable.strings (iOS) and strings.xml (Android) |
| `shared/routes.yaml` changed | Generate Router (iOS) and NavGraph (Android) |
| `shared/feature-flags.yaml` changed | Generate flag classes for both platforms |
| Assets changed in `shared/assets/` | Sync to platform asset directories |
| Feature exists on one platform only | Scaffold View + ViewModel on missing platform |
| Tests exist on one platform only | Generate test templates for missing platform |
| Version mismatch | Update Info.plist and build.gradle |

---

## Phase 3: Validation

**Goal**: Verify sync quality

Launch **sync-reviewer agent** to check:
- Model field matching across platforms
- API endpoint consistency
- Type compatibility
- No remaining missing counterpart files

---

## Phase 4: Report

**Goal**: Summarize what was done

Mark all TodoWrite items complete, then report:

```markdown
# TwoPhone Sync Complete

## Created/Updated
- [list every file with path and action: New/Updated]

## Skipped (no changes needed)
- [list areas that didn't need sync]

## Manual Review Required
- [files with complex logic that need human verification]

## Platform Parity
| Category | iOS | Android | Status |
|----------|-----|---------|--------|
| Models | N | N | status |
| Services | N | N | status |
| Features | N | N | status |
| Tests | N | N | status |
```

---

## Configuration (.twophone.json)

```json
{
  "projectName": "MyApp",
  "version": "1.2.0",
  "build": 42,
  "platforms": {
    "ios": { "path": "ios/MyApp", "bundleId": "com.example.myapp" },
    "android": { "path": "android/app", "packageName": "com.example.myapp" }
  },
  "auto": {
    "syncModels": true,
    "syncServices": true,
    "syncAssets": true,
    "syncStrings": true,
    "syncDesignTokens": true,
    "syncVersion": true,
    "ignorePaths": ["ios/MyApp/Generated/*", "android/app/src/main/java/*/generated/*"]
  }
}
```

## Notes

- Recommend `git commit` before running with `--full`
- `--full` mode backs up existing files before regeneration
- Asks confirmation on conflicts (both sides changed)
- If sync is interrupted, run `/twophone` again — it detects remaining gaps
