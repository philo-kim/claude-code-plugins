---
description: Smart cross-platform sync - ensures your iOS and Android apps express the same domain model completely
argument-hint: [file-path | --full]
---

# /twophone — Cross-Platform Domain Sync

Two apps. One domain model. AI ensures both are complete.

## Philosophy

Software is an encoding of a domain model. An iOS app and an Android app of the same product encode the same domain model in different mechanisms (Swift vs Kotlin, SwiftUI vs Compose, URLSession vs Retrofit). Sync means ensuring the domain model is completely expressed on both platforms.

There are no categories to check, no layers to compare, no fixed list of file types. AI reads the code, understands the domain model, and fills what's missing — natively.

## Core Principles

- **Use TodoWrite**: List every gap found. Mark each as complete only after the file is created.
- **Agent delegation**: Use auto-sync agent for creation, sync-reviewer agent for verification.
- **Ask before large changes**: If more than 10 files need creation, confirm with the user first.
- **Do not stop until done**: Keep creating files until every TodoWrite item is complete. If context is running low, tell the user to run `/twophone` again to continue.

## Options

- (no args): Smart mode — scan, find gaps, fill them
- `<file-path>`: Sync a specific file to the other platform
- `--full`: Full parity scan (ignores git diff, compares everything)

---

## Phase 1: Declarative Sync

**Goal**: Generate code from shared definitions (if they exist)

If `shared/` directory contains YAML definitions, generate platform code from them:
- `design-tokens.yaml` → Colors, Typography, Spacing for both platforms
- `strings.yaml` → Localizable.strings (iOS) + strings.xml (Android)
- `routes.yaml` → Router (iOS) + NavGraph (Android)
- `feature-flags.yaml` → Flag classes for both platforms
- `api-spec.yaml` → Model/DTO generation for both platforms

Skip this phase if no `shared/` YAML files exist. This is optional — not all projects use it.

---

## Phase 2: Domain Completeness Scan

**Goal**: Find every gap where the domain model exists on one platform but not the other

**CRITICAL**: This is exhaustive. Do not limit to specific directories or file types.

**Actions**:
1. Read `.twophone.json` for platform paths. **If missing → auto-detect and create it**:
   - Scan project root for `ios/` and `android/` directories
   - Find the main source directories (where `.swift` and `.kt` files live)
   - Infer project name from directory structure or `package.json` / `build.gradle`
   - Create `.twophone.json` with detected paths and sensible defaults
   - Continue immediately — do not stop or ask the user
2. List ALL source files on both platforms:
   - iOS: every `.swift` file (excluding Generated/, Pods/, build/)
   - Android: every `.kt` file (excluding generated/, build/)
3. For each file, AI reads it and understands what domain concept it encodes:
   - What data does it define?
   - What behavior does it implement?
   - What contracts does it expose?
   - What does it depend on?
4. Match files across platforms by domain concept (not by name or directory)
5. Identify:
   - **Gaps**: Domain concepts encoded on one platform but not the other
   - **Drift**: Matched pairs where the domain model diverges (different fields, missing methods)
   - **Platform-specific**: Code that genuinely belongs to only one platform (widgets, watch extensions, etc.) — skip these

6. Group gaps by dependency clusters — files that need each other to work
7. Create TodoWrite with every gap, grouped by cluster

Present to user:

```markdown
## Domain Parity: X/100

### Gaps Found
| Cluster | Platform Missing | Files Needed | Source Files |
|---------|-----------------|--------------|--------------|
| Auth data access | iOS | 3 | AuthRepositoryImpl.kt, AuthRemoteDataSource.kt, AuthMapper.kt |
| Offline caching | iOS | 4 | UserDao.kt, UserEntity.kt, AppDatabase.kt, CacheManager.kt |
| ...

### Drift Found
| Concept | iOS | Android | Difference |
|---------|-----|---------|------------|
| User model | User.swift | User.kt | iOS missing `lastSyncDate` field |
| ...

### Platform-Specific (skipped)
| File | Platform | Reason |
|------|----------|--------|
| WatchExtension.swift | iOS only | Apple Watch specific |
| ...

Proceed with sync? (Y files to create, Z fields to update)
```

---

## Phase 3: Generate

**Goal**: Fill every gap with native platform code

**CRITICAL**: Do not stop until every TodoWrite item is complete.

Launch **auto-sync agent** with:
- The complete gap list from Phase 2
- For each gap: the source files to read, the target platform, the target path

The agent will:
1. Read all source files in a dependency cluster
2. Extract the domain model (data, behavior, contracts)
3. Re-express it using the target platform's native patterns
4. Write the files
5. Mark each TodoWrite item complete
6. Move to the next cluster

**If there are too many files for one pass**: The agent creates as many as it can, then the command tells the user to run `/twophone` again to continue from where it left off (TodoWrite preserves state).

---

## Phase 4: Fix Drift

**Goal**: Align matched pairs where domain models diverge

For each drift item found in Phase 2:
- Read both files
- Determine which platform has the more complete version
- Update the less-complete file to match
- Show the change to the user before applying

---

## Phase 5: Build Verification

**Goal**: Confirm generated code compiles

Run platform build commands to catch syntax errors, missing imports, and type mismatches:
- **iOS**: `xcodebuild build` (or `swift build` if SPM project)
- **Android**: `./gradlew compileDebugKotlin` (compile only, fastest check)

If build fails:
1. Read the error output
2. Fix the issue (missing import, type mismatch, syntax error)
3. Re-run the build
4. Repeat until both platforms compile

**CRITICAL**: Do not skip this phase. A file that doesn't compile is worse than no file.

---

## Phase 6: Verify Domain Completeness

**Goal**: Confirm all gaps are filled and behavior is consistent

Launch **sync-reviewer agent** to verify:
- All previously identified gaps are now filled
- No new gaps introduced
- Matched pairs behave the same (same data, same operations, same contracts)

---

## Phase 7: Report

```markdown
# TwoPhone Sync Complete

## Domain Parity: X/100 → Y/100

## Created
- [every file created, with path]

## Updated
- [every file modified for drift fix]

## Remaining (if any)
- [gaps that couldn't be filled in this pass]
- Run `/twophone` again to continue

## Platform Parity
| Concept Area | iOS | Android | Status |
|-------------|-----|---------|--------|
| Data models | N | N | status |
| Business logic | N | N | status |
| Data access | N | N | status |
| State management | N | N | status |
| Presentation | N | N | status |
```

---

## Type & Pattern Reference

The only hardcoded rules. Everything else is AI understanding.

### Type Mapping (Swift ↔ Kotlin)

| Swift | Kotlin |
|-------|--------|
| `struct X: Codable` | `@Serializable data class X` |
| `let` / `var` | `val` / `var` |
| `String`, `Int`, `Double`, `Bool` | `String`, `Int`, `Double`, `Boolean` |
| `T?` | `T?` (with `= null`) |
| `[T]` | `List<T>` |
| `[K: V]` | `Map<K, V>` |
| `Date` | Instant / String |
| `UUID` | String |
| `Data` | ByteArray |

### Pattern Mapping (Swift ↔ Kotlin)

| Swift | Kotlin |
|-------|--------|
| `async throws -> T` | `suspend fun(): T` |
| `@Observable class` | `ViewModel` + `StateFlow` |
| `protocol X` | `interface X` |
| `actor` | `object` + `Mutex` / synchronized |
| `Task { }` | `viewModelScope.launch { }` |
| `try await` | `suspend` + `try/catch` |

### Platform Mechanism Mapping

| Concern | iOS | Android |
|---------|-----|---------|
| Persistence | SwiftData / CoreData | Room |
| Network | URLSession | Retrofit / Ktor |
| Secure storage | Keychain | EncryptedSharedPreferences |
| Simple storage | UserDefaults | DataStore |
| Background work | BGTaskScheduler | WorkManager |
| Push | APNs | FCM |
| DI | Environment / manual | Hilt / Koin |
| Navigation | NavigationStack | Navigation Compose |

---

## Configuration (.twophone.json)

```json
{
  "projectName": "MyApp",
  "version": "1.0.0",
  "platforms": {
    "ios": { "path": "ios/MyApp" },
    "android": { "path": "android/app/src/main/java/com/example/myapp" }
  },
  "ignore": [
    "**/Generated/**", "**/build/**", "**/Pods/**",
    "**/*.generated.swift", "**/*.generated.kt"
  ]
}
```

## Notes

- `git commit` before `--full` mode
- If sync is interrupted, run `/twophone` again — it picks up from where it left off
- Platform-specific code (widgets, watch, wear) is automatically detected and skipped
