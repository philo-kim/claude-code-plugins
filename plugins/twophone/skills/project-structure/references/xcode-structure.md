# Xcode Project Structure Details

## Project File Structure

```
MyApp.xcodeproj/
├── project.pbxproj          # Project settings (auto-generated)
├── xcshareddata/
│   └── xcschemes/           # Build schemes
└── xcuserdata/              # User-specific settings
```

## Swift Package Manager (SPM)

Use `Package.swift` or Xcode's Package Dependencies:

```swift
// Add via Project Settings > Package Dependencies
// or File > Add Package Dependencies...

// Common dependencies:
// - Alamofire (networking)
// - Kingfisher (image loading)
// - SwiftLint (linter)
```

## Target Configuration

| Target | Purpose |
|--------|---------|
| MyApp | Main app |
| MyAppTests | Unit tests |
| MyAppUITests | UI tests |
| MyAppKit | Shared framework (optional) |
| MyAppWidget | Widget extension (optional) |

## Info.plist Key Settings

```xml
<key>CFBundleName</key>
<string>$(PRODUCT_NAME)</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleVersion</key>
<string>1</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<!-- Permissions -->
<key>NSCameraUsageDescription</key>
<string>Camera access reason</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access reason</string>
```

## Build Settings

**Development vs Production:**

```swift
// Configuration.swift
enum Environment {
    case development
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://dev-api.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
}
```

## Assets.xcassets Structure

```
Assets.xcassets/
├── AppIcon.appiconset/      # App icon
├── AccentColor.colorset/    # Accent color
├── Colors/                  # Custom colors
│   ├── Primary.colorset/
│   └── Background.colorset/
├── Images/                  # Images
│   ├── logo.imageset/
│   └── placeholder.imageset/
└── Symbols/                 # Custom SF Symbols
```

## Localization (Multi-language)

```
MyApp/
├── en.lproj/
│   └── Localizable.strings
├── ko.lproj/
│   └── Localizable.strings
└── Resources/
    └── Localizable.strings  # Base
```

**Localizable.strings:**
```
/* Login screen */
"login.title" = "Login";
"login.email.placeholder" = "Email";
"login.password.placeholder" = "Password";
"login.button" = "Sign In";
```

**Usage:**
```swift
Text("login.title")
// or
Text(NSLocalizedString("login.title", comment: "Login screen title"))
```

## Project Group Organization Tips

1. **Sync with filesystem**: Match Xcode group structure with filesystem structure
2. **Feature-based organization**: Group by feature (Auth, Home) rather than file type (Views, ViewModels)
3. **Reference management**: Move files within Xcode (not Finder)
