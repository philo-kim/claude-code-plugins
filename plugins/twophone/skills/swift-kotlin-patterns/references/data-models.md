# Advanced Data Model Patterns

## Enum Mapping

**Swift:**
```swift
enum Status: String, Codable {
    case pending
    case active
    case completed
    case failed
}
```

**Kotlin:**
```kotlin
@Serializable
enum class Status {
    @SerialName("pending") PENDING,
    @SerialName("active") ACTIVE,
    @SerialName("completed") COMPLETED,
    @SerialName("failed") FAILED
}
```

## Sealed Class / Enum with Associated Values

**Swift:**
```swift
enum Result<T> {
    case success(T)
    case failure(Error)
}

enum NetworkResponse {
    case data(Data)
    case error(code: Int, message: String)
    case loading
}
```

**Kotlin:**
```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val error: Throwable) : Result<Nothing>()
}

sealed class NetworkResponse {
    data class Data(val data: ByteArray) : NetworkResponse()
    data class Error(val code: Int, val message: String) : NetworkResponse()
    object Loading : NetworkResponse()
}
```

## Nested Models

**Swift:**
```swift
struct Order: Codable {
    let id: Int
    let items: [OrderItem]
    let customer: Customer

    struct OrderItem: Codable {
        let productId: Int
        let quantity: Int
        let price: Double
    }

    struct Customer: Codable {
        let id: Int
        let name: String
    }
}
```

**Kotlin:**
```kotlin
@Serializable
data class Order(
    val id: Int,
    val items: List<OrderItem>,
    val customer: Customer
) {
    @Serializable
    data class OrderItem(
        val productId: Int,
        val quantity: Int,
        val price: Double
    )

    @Serializable
    data class Customer(
        val id: Int,
        val name: String
    )
}
```

## JSON Key Mapping (snake_case → camelCase)

**Swift:**
```swift
struct User: Codable {
    let userId: Int
    let firstName: String
    let lastName: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }
}
```

**Kotlin:**
```kotlin
@Serializable
data class User(
    @SerialName("user_id") val userId: Int,
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    @SerialName("created_at") val createdAt: String
)
```

## Default Values

**Swift:**
```swift
struct Settings: Codable {
    var theme: String = "light"
    var fontSize: Int = 14
    var notifications: Bool = true
}
```

**Kotlin:**
```kotlin
@Serializable
data class Settings(
    val theme: String = "light",
    val fontSize: Int = 14,
    val notifications: Boolean = true
)
```

## Generic Types

**Swift:**
```swift
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct PaginatedList<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
}
```

**Kotlin:**
```kotlin
@Serializable
data class APIResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: String? = null
)

@Serializable
data class PaginatedList<T>(
    val items: List<T>,
    val total: Int,
    val page: Int,
    val pageSize: Int
)
```

## Computed Properties

**Swift:**
```swift
struct User: Codable {
    let firstName: String
    let lastName: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
```

**Kotlin:**
```kotlin
@Serializable
data class User(
    val firstName: String,
    val lastName: String
) {
    val fullName: String
        get() = "$firstName $lastName"
}
```
