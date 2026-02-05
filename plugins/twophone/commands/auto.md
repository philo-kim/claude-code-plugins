---
description: Full auto - Scan entire project and sync everything automatically
argument-hint: [--init | --sync | --full]
---

# TwoPhone Full Auto

Scans the entire project and automatically performs all necessary synchronization tasks.

## Modes

- `--init`: Initialize new project + complete setup
- `--sync`: Detect changes + synchronize
- `--full`: Full regeneration (backup existing files first)
- (default): Smart mode - automatically determine required tasks

## Execution Order

### Phase 1: Project Analysis
```
1. Check .twophone.json (suggest creation if missing)
2. Scan iOS/Android directory structure
3. Detect changed files (using git diff)
4. Identify missing files/configurations
```

### Phase 2: Core Synchronization (Auto-executed)

Execute the following tasks in order:

#### 2-1. Model Sync
- Compare `Models/*.swift` ↔ `models/*.kt`
- Auto-create/update mismatched items
- Generate both platforms when new model detected

#### 2-2. API/Service Sync
- Compare `Services/*.swift` ↔ `services/*.kt`
- Verify endpoint consistency
- Generate missing methods

#### 2-3. Asset Sync
- Scan `shared/assets/` folder
- Update iOS Assets.xcassets
- Update Android drawable/mipmap
- Notify about missing resolutions

#### 2-4. Localization Sync
- Scan `shared/strings.yaml` or `shared/strings.json`
- Generate iOS Localizable.strings
- Generate Android strings.xml
- Warn about missing translation keys

#### 2-5. Design Token Sync
- Scan `shared/design-tokens.yaml`
- Generate iOS Colors.swift, Typography.swift
- Generate Android Color.kt, Type.kt

#### 2-6. Version Sync
- Read version info from `.twophone.json`
- Update iOS Info.plist version
- Update Android build.gradle version

### Phase 3: Validation

#### 3-1. Sync State Verification
Invoke sync-reviewer agent to verify:
- Model field matching
- API endpoint matching
- Type compatibility

#### 3-2. Missing Items Report
```
⚠️ The following items are not synchronized:
- iOS only: ProfileService.swift
- Android only: AnalyticsHelper.kt
```

### Phase 4: Final Report

```markdown
# 🚀 TwoPhone Auto Complete

## Executed Tasks
✅ Model sync: 5 files
✅ Service sync: 3 files
✅ Asset sync: 12 images
✅ Localization: 2 languages, 45 keys
✅ Design tokens: 15 colors, 4 fonts
✅ Version sync: 1.2.0 (build 42)

## Manual Review Required
⚠️ ProfileService.swift - No Android counterpart
⚠️ analytics_icon.png - Missing 3x resolution

## Next Steps
- Run `/twophone sync ios/Services/ProfileService.swift` to sync
- Request missing assets from designer
```

## Configuration File (.twophone.json)

Customize full auto behavior:

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

## Important Notes

- Recommend git commit before large changes
- `--full` mode backs up existing files with `.backup` extension
- Request user confirmation on conflicts
- Use `--sync` mode for CI/CD
