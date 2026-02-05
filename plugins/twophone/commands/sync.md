---
description: Sync iOS/Android code changes
argument-hint: [file-path]
---

# TwoPhone Code Sync

When user changes code on one platform, suggest corresponding changes for the other platform.

## Input
- File path: `$ARGUMENTS` (optional, detect recent changes if not provided)

## Execution Steps

### 1. Check Project Configuration
Read `.twophone.json` for project settings.
If missing, guide user to run `/twophone init` first.

### 2. Analyze Changed File

If file path is provided:
- Read and analyze the file

If file path is not provided:
- Check recent changes via `git diff` or `git status`
- Find changed files in iOS or Android directories

### 3. Determine Platform

Determine platform from file path:
- `ios/` or `.swift` → iOS
- `android/` or `.kt` → Android

### 4. Map Corresponding Files

**Model files:**
| iOS | Android |
|-----|---------|
| `Models/User.swift` | `models/User.kt` |
| `Models/Product.swift` | `models/Product.kt` |

**Service/Repository files:**
| iOS | Android |
|-----|---------|
| `Services/UserService.swift` | `services/UserRepository.kt` |
| `Services/APIClient.swift` | `services/ApiClient.kt` |

**ViewModel:**
| iOS | Android |
|-----|---------|
| `Features/Home/HomeViewModel.swift` | `features/home/HomeViewModel.kt` |

### 5. Code Conversion

Analyze changed code and convert for the other platform.

**Swift → Kotlin conversion rules:**
- `struct` → `data class`
- `class` → `class`
- `let` → `val`
- `var` → `var`
- `Optional<T>` / `T?` → `T?`
- `[T]` → `List<T>`
- `[K: V]` → `Map<K, V>`
- `func` → `fun`
- `@Published` → `MutableStateFlow`
- `@Observable` → `ViewModel with StateFlow`
- `async/await` → `suspend`
- `Task { }` → `viewModelScope.launch { }`

**Kotlin → Swift conversion rules:**
- `data class` → `struct` (with Codable)
- `val` → `let`
- `var` → `var`
- `T?` → `T?`
- `List<T>` → `[T]`
- `Map<K, V>` → `[K: V]`
- `fun` → `func`
- `StateFlow` → `@Published`
- `suspend` → `async`
- `viewModelScope.launch` → `Task { }`

### 6. Output Sync Suggestion

Output with converted code:

1. **Changed file** (source platform)
2. **Corresponding file path** (target platform)
3. **Converted code** (full or diff)
4. **Notes** (parts requiring manual review)

### 7. Confirm Application

Ask user whether to apply changes:
- "Apply these changes?"
- If yes, modify target file
- If no, just show changes and exit

## Example

**Input:** `/twophone sync ios/MyApp/Models/User.swift`

**Output:**
```
📱 iOS → Android Sync

Changed file: ios/MyApp/Models/User.swift
Target file: android/app/src/main/java/com/example/myapp/models/User.kt

Swift source:
struct User: Codable {
    let id: Int
    let name: String
    let email: String?
}

Kotlin conversion:
data class User(
    val id: Int,
    val name: String,
    val email: String? = null
)

Apply these changes to android/app/.../models/User.kt?
```
