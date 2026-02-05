---
description: Generate Swift/Kotlin models from OpenAPI spec
argument-hint: [api-spec-path]
---

# TwoPhone API Model Generation

Generate Swift and Kotlin models simultaneously from OpenAPI/JSON spec files.

## Input
- API spec file path: `$ARGUMENTS` (default: `shared/api-spec.yaml`)

## Execution Steps

### 1. Read Spec File

Read API spec file from specified or default path:
- `shared/api-spec.yaml`
- `shared/api-spec.json`
- `openapi.yaml`
- `swagger.json`

### 2. Parse Schema

Extract model definitions from OpenAPI `components.schemas` section.

**Supported types:**
- `string` → Swift `String`, Kotlin `String`
- `integer` → Swift `Int`, Kotlin `Int`
- `number` → Swift `Double`, Kotlin `Double`
- `boolean` → Swift `Bool`, Kotlin `Boolean`
- `array` → Swift `[T]`, Kotlin `List<T>`
- `object` → nested struct/data class
- `$ref` → reference to other schema

### 3. Generate Swift Models

Generate in `ios/<ProjectName>/Models/` directory

**Template:**
```swift
import Foundation

// MARK: - <ModelName>
struct <ModelName>: Codable, Hashable, Sendable {
    <properties>

    enum CodingKeys: String, CodingKey {
        <coding_keys_if_needed>
    }
}
```

**Example:**
```swift
import Foundation

// MARK: - User
struct User: Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let email: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
    }
}
```

### 4. Generate Kotlin Models

Generate in `android/app/src/main/java/com/example/<projectname>/models/` directory

**Template:**
```kotlin
package com.example.<projectname>.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class <ModelName>(
    <properties>
)
```

**Example:**
```kotlin
package com.example.myapp.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: Int,
    val name: String,
    val email: String? = null,
    @SerialName("created_at")
    val createdAt: String
)
```

### 5. Generate API Client (Optional)

Ask user if they want to generate API client as well.

**Swift APIClient:**
```swift
import Foundation

actor APIClient {
    static let shared = APIClient()
    private let baseURL = URL(string: "https://api.example.com")!
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(T.self, from: data)
    }
}
```

**Kotlin ApiClient:**
```kotlin
package com.example.myapp.services

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

object ApiClient {
    private const val BASE_URL = "https://api.example.com"

    private val client = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }

    suspend inline fun <reified T> fetch(endpoint: String): T {
        return client.get("$BASE_URL/$endpoint").body()
    }
}
```

### 6. Final Report

Output list of generated files:

```
✅ Model generation complete

iOS models:
  - ios/MyApp/Models/User.swift
  - ios/MyApp/Models/Product.swift
  - ios/MyApp/Models/Order.swift

Android models:
  - android/app/.../models/User.kt
  - android/app/.../models/Product.kt
  - android/app/.../models/Order.kt

API client:
  - ios/MyApp/Services/APIClient.swift
  - android/app/.../services/ApiClient.kt
```

## Type Mapping Reference

| OpenAPI | Swift | Kotlin |
|---------|-------|--------|
| `string` | `String` | `String` |
| `string` (date) | `Date` | `String` |
| `string` (date-time) | `Date` | `String` |
| `string` (uuid) | `UUID` | `String` |
| `integer` | `Int` | `Int` |
| `integer` (int64) | `Int64` | `Long` |
| `number` | `Double` | `Double` |
| `number` (float) | `Float` | `Float` |
| `boolean` | `Bool` | `Boolean` |
| `array` | `[T]` | `List<T>` |
| `object` | `[String: Any]` | `Map<String, Any>` |
