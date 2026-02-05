---
description: Version/build sync and release preparation
argument-hint: [--bump major|minor|patch | --set <version> | --build]
---

# TwoPhone Release

Synchronize version numbers and prepare for release.

## Commands

### Version bump
```
/twophone release --bump patch    # 1.0.0 → 1.0.1
/twophone release --bump minor    # 1.0.0 → 1.1.0
/twophone release --bump major    # 1.0.0 → 2.0.0
```

### Set specific version
```
/twophone release --set 2.0.0
```

### Increment build number only
```
/twophone release --build         # build: 41 → 42
```

## Version Info Source

**.twophone.json:**
```json
{
  "version": "1.2.0",
  "build": 42,
  "releaseNotes": {
    "1.2.0": [
      "New profile screen",
      "Bug fixes"
    ]
  }
}
```

## iOS Update

**Info.plist (or xcconfig):**
```xml
<key>CFBundleShortVersionString</key>
<string>1.2.0</string>

<key>CFBundleVersion</key>
<string>42</string>
```

**Or project settings:**
```
MARKETING_VERSION = 1.2.0
CURRENT_PROJECT_VERSION = 42
```

## Android Update

**app/build.gradle.kts:**
```kotlin
android {
    defaultConfig {
        versionCode = 42
        versionName = "1.2.0"
    }
}
```

## Release Checklist

When running `/twophone release --bump minor`:

```markdown
# Release Checklist v1.2.0 → v1.3.0

## Auto-completed
✅ .twophone.json version updated
✅ iOS Info.plist version updated
✅ Android build.gradle version updated
✅ Build number: 42 → 43

## Manual Review Required
□ Write release notes
□ Update screenshots (if UI changed)
□ Complete testing
□ Create git tag

## Next Steps
1. `git add . && git commit -m "Bump version to 1.3.0"`
2. `git tag v1.3.0`
3. `git push origin main --tags`

### iOS Deployment
4. Xcode → Archive → Upload to App Store Connect

### Android Deployment
5. `./gradlew bundleRelease`
6. Upload AAB to Google Play Console
```

## Fastlane Setup

When running `/twophone release --setup-fastlane`:

**ios/fastlane/Fastfile:**
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "MyApp.xcodeproj")
    build_app(scheme: "MyApp")
    upload_to_testflight
  end

  desc "Push a new release build to the App Store"
  lane :release do
    build_app(scheme: "MyApp")
    upload_to_app_store(skip_metadata: true, skip_screenshots: true)
  end
end
```

**android/fastlane/Fastfile:**
```ruby
default_platform(:android)

platform :android do
  desc "Deploy a new beta version to Google Play"
  lane :beta do
    gradle(task: "clean bundleRelease")
    upload_to_play_store(track: "internal")
  end

  desc "Deploy a new version to Google Play"
  lane :release do
    gradle(task: "clean bundleRelease")
    upload_to_play_store(track: "production")
  end
end
```

## GitHub Actions CI/CD

When running `/twophone release --setup-ci`:

**.github/workflows/release.yml:**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - name: Install Fastlane
        run: cd ios && bundle install
      - name: Build and Upload
        run: cd ios && bundle exec fastlane beta
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}

  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Build AAB
        run: cd android && ./gradlew bundleRelease
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.example.myapp
          releaseFiles: android/app/build/outputs/bundle/release/app-release.aab
          track: internal
```

## Version History

```
/twophone release --history
```

```
Version History:
- v1.2.0 (build 42) - 2024-01-15
  - New profile screen
  - Bug fixes
- v1.1.0 (build 35) - 2024-01-01
  - Dark mode support
  - Performance improvements
- v1.0.0 (build 1) - 2023-12-01
  - Initial release
```
