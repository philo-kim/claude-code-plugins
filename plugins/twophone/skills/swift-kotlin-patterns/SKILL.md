---
name: Swift-Kotlin Patterns
description: This skill should be used when the user asks to "convert Swift to Kotlin", "convert Kotlin to Swift", "sync iOS and Android code", "what's the Kotlin equivalent", "what's the Swift equivalent", or when working on cross-platform mobile development.
version: 1.0.0
---

# Swift ↔ Kotlin Pattern Mapping

Code conversion and pattern mapping guide between iOS (Swift) and Android (Kotlin).

## Basic Type Mapping

| Swift | Kotlin | Notes |
|-------|--------|-------|
| `String` | `String` | Same |
| `Int` | `Int` | Same |
| `Int64` | `Long` | 64-bit integer |
| `Double` | `Double` | Same |
| `Float` | `Float` | Same |
| `Bool` | `Boolean` | Caution! |
| `[T]` | `List<T>` | Array |
| `[K: V]` | `Map<K, V>` | Dictionary |
| `Set<T>` | `Set<T>` | Same |
| `T?` | `T?` | Optional |
| `Date` | `Instant` / `LocalDateTime` | kotlinx-datetime |
| `UUID` | `UUID` / `String` | |
| `Data` | `ByteArray` | Binary |
| `URL` | `String` | Treated as string |

## Data Classes

**Swift:**
```swift
struct User: Codable, Hashable {
    let id: Int
    let name: String
    let email: String?
}
```

**Kotlin:**
```kotlin
@Serializable
data class User(
    val id: Int,
    val name: String,
    val email: String? = null
)
```

## Optional Handling

**Swift:**
```swift
let name: String? = user?.name
let displayName = name ?? "Unknown"
if let email = user?.email {
    sendEmail(to: email)
}
guard let id = user?.id else { return }
```

**Kotlin:**
```kotlin
val name: String? = user?.name
val displayName = name ?: "Unknown"
user?.email?.let { email ->
    sendEmail(to = email)
}
val id = user?.id ?: return
```

## Collection Operations

**Swift:**
```swift
let numbers = [1, 2, 3, 4, 5]
let doubled = numbers.map { $0 * 2 }
let evens = numbers.filter { $0 % 2 == 0 }
let sum = numbers.reduce(0, +)
let first = numbers.first { $0 > 3 }
```

**Kotlin:**
```kotlin
val numbers = listOf(1, 2, 3, 4, 5)
val doubled = numbers.map { it * 2 }
val evens = numbers.filter { it % 2 == 0 }
val sum = numbers.reduce { acc, n -> acc + n }
val first = numbers.firstOrNull { it > 3 }
```

## Async Processing

**Swift (async/await):**
```swift
func fetchUser(id: Int) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Call
Task {
    do {
        let user = try await fetchUser(id: 1)
    } catch {
        print(error)
    }
}
```

**Kotlin (coroutines):**
```kotlin
suspend fun fetchUser(id: Int): User {
    return apiClient.get("https://api.example.com/users/$id")
}

// Call
viewModelScope.launch {
    try {
        val user = fetchUser(1)
    } catch (e: Exception) {
        println(e)
    }
}
```

## State Management

**Swift (@Observable):**
```swift
@Observable
final class UserViewModel {
    var user: User?
    var isLoading = false
    var error: String?

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userService.fetchCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

**Kotlin (StateFlow):**
```kotlin
class UserViewModel : ViewModel() {
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _user.value = userService.fetchCurrentUser()
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }
}
```

## Additional References

See the following files for detailed patterns:
- references/data-models.md - Advanced data model patterns
- references/networking.md - Network layer patterns
- references/state-management.md - State management patterns
