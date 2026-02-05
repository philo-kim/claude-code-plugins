---
name: Project Structure
description: This skill should be used when the user asks about "iOS project structure", "Android project structure", "where to put files", "folder organization", "Xcode project layout", "Gradle module structure", or when setting up a new mobile project.
version: 1.0.0
---

# iOS/Android Project Structure Guide

Standard directory structure and conventions for mobile app projects.

## iOS Project Structure (SwiftUI)

```
MyApp/
├── MyApp.xcodeproj           # Xcode project file
├── MyApp/
│   ├── MyAppApp.swift        # @main app entry point
│   ├── ContentView.swift     # Root view
│   │
│   ├── App/                  # App configuration
│   │   ├── AppDelegate.swift
│   │   └── Configuration.swift
│   │
│   ├── Features/             # Feature modules (core!)
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   ├── LoginViewModel.swift
│   │   │   └── RegisterView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   └── Profile/
│   │       ├── ProfileView.swift
│   │       └── ProfileViewModel.swift
│   │
│   ├── Models/               # Data models
│   │   ├── User.swift
│   │   └── Product.swift
│   │
│   ├── Services/             # Business logic/API
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   └── UserService.swift
│   │
│   ├── Components/           # Reusable UI components
│   │   ├── Buttons/
│   │   ├── Cards/
│   │   └── Forms/
│   │
│   ├── Extensions/           # Swift extensions
│   │   ├── View+Extensions.swift
│   │   └── String+Extensions.swift
│   │
│   ├── Utilities/            # Utilities
│   │   ├── Constants.swift
│   │   └── Helpers.swift
│   │
│   └── Resources/            # Resources
│       ├── Assets.xcassets
│       ├── Localizable.strings
│       └── Info.plist
│
├── MyAppTests/               # Unit tests
└── MyAppUITests/             # UI tests
```

## Android Project Structure (Jetpack Compose)

```
my-app/
├── settings.gradle.kts
├── build.gradle.kts          # Root build file
├── gradle.properties
├── gradle/
│   └── libs.versions.toml    # Version catalog
│
├── app/                      # Main app module
│   ├── build.gradle.kts
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/com/example/myapp/
│       │   │   ├── MainActivity.kt
│       │   │   ├── MyApplication.kt
│       │   │   │
│       │   │   ├── features/         # Feature modules
│       │   │   │   ├── auth/
│       │   │   │   │   ├── LoginScreen.kt
│       │   │   │   │   ├── LoginViewModel.kt
│       │   │   │   │   └── RegisterScreen.kt
│       │   │   │   ├── home/
│       │   │   │   │   ├── HomeScreen.kt
│       │   │   │   │   └── HomeViewModel.kt
│       │   │   │   └── profile/
│       │   │   │       ├── ProfileScreen.kt
│       │   │   │       └── ProfileViewModel.kt
│       │   │   │
│       │   │   ├── models/           # Data models
│       │   │   │   ├── User.kt
│       │   │   │   └── Product.kt
│       │   │   │
│       │   │   ├── services/         # API/services
│       │   │   │   ├── ApiClient.kt
│       │   │   │   ├── AuthService.kt
│       │   │   │   └── UserRepository.kt
│       │   │   │
│       │   │   ├── ui/               # UI related
│       │   │   │   ├── components/   # Reusable components
│       │   │   │   ├── theme/        # Theme
│       │   │   │   │   ├── Theme.kt
│       │   │   │   │   ├── Color.kt
│       │   │   │   │   └── Type.kt
│       │   │   │   └── navigation/   # Navigation
│       │   │   │       └── NavGraph.kt
│       │   │   │
│       │   │   ├── di/               # Dependency injection (Hilt)
│       │   │   │   └── AppModule.kt
│       │   │   │
│       │   │   └── utils/            # Utilities
│       │   │       └── Constants.kt
│       │   │
│       │   └── res/
│       │       ├── values/
│       │       ├── drawable/
│       │       └── mipmap/
│       │
│       ├── test/                     # Unit tests
│       └── androidTest/              # Instrumented tests
│
└── buildSrc/                         # Custom Gradle plugins (optional)
```

## File Mapping Rules

| iOS Path | Android Path |
|----------|--------------|
| `Features/Auth/LoginView.swift` | `features/auth/LoginScreen.kt` |
| `Features/Auth/LoginViewModel.swift` | `features/auth/LoginViewModel.kt` |
| `Models/User.swift` | `models/User.kt` |
| `Services/APIClient.swift` | `services/ApiClient.kt` |
| `Components/PrimaryButton.swift` | `ui/components/PrimaryButton.kt` |

## Naming Conventions

| Item | iOS (Swift) | Android (Kotlin) |
|------|-------------|------------------|
| File name | PascalCase.swift | PascalCase.kt |
| Class | PascalCase | PascalCase |
| Function | camelCase | camelCase |
| Variable | camelCase | camelCase |
| Constant | camelCase | SCREAMING_SNAKE |
| Package | - | lowercase |

## Additional References

See the following files for detailed structure:
- references/xcode-structure.md - Xcode project details
- references/gradle-structure.md - Gradle multi-module details
