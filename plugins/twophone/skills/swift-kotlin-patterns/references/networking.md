# Network Layer Patterns

## HTTP Client Comparison

| Item | Swift | Kotlin |
|------|-------|--------|
| Default | URLSession | HttpURLConnection |
| Recommended | URLSession (async) | Ktor / OkHttp |
| JSON Parsing | Codable + JSONDecoder | kotlinx.serialization |

## Basic API Client

**Swift:**
```swift
actor APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://api.example.com")!
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable, U: Encodable>(
        _ endpoint: String,
        body: U
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
}
```

**Kotlin (Ktor):**
```kotlin
object ApiClient {
    private const val BASE_URL = "https://api.example.com"

    private val client = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
        install(Logging) {
            level = LogLevel.BODY
        }
        defaultRequest {
            contentType(ContentType.Application.Json)
        }
    }

    suspend inline fun <reified T> get(endpoint: String): T {
        return client.get("$BASE_URL/$endpoint").body()
    }

    suspend inline fun <reified T, reified U> post(
        endpoint: String,
        body: U
    ): T {
        return client.post("$BASE_URL/$endpoint") {
            setBody(body)
        }.body()
    }
}

sealed class ApiError : Exception() {
    data class HttpError(val code: Int, val message: String) : ApiError()
    data class NetworkError(override val cause: Throwable) : ApiError()
    data class ParseError(override val cause: Throwable) : ApiError()
}
```

## Interceptor / Middleware

**Swift (Request Modifier):**
```swift
extension URLRequest {
    mutating func addAuthHeader(token: String) {
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// Usage
var request = URLRequest(url: url)
request.addAuthHeader(token: authToken)
```

**Kotlin (OkHttp Interceptor):**
```kotlin
class AuthInterceptor(private val tokenProvider: () -> String?) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = tokenProvider() ?: return chain.proceed(chain.request())

        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .build()

        return chain.proceed(request)
    }
}

// Setup
val client = OkHttpClient.Builder()
    .addInterceptor(AuthInterceptor { authManager.token })
    .build()
```

## Repository Pattern

**Swift:**
```swift
protocol UserRepository {
    func getUser(id: Int) async throws -> User
    func getUsers() async throws -> [User]
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: Int) async throws
}

final class RemoteUserRepository: UserRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getUser(id: Int) async throws -> User {
        try await apiClient.get("users/\(id)")
    }

    func getUsers() async throws -> [User] {
        try await apiClient.get("users")
    }

    func createUser(_ user: User) async throws -> User {
        try await apiClient.post("users", body: user)
    }

    func updateUser(_ user: User) async throws -> User {
        try await apiClient.post("users/\(user.id)", body: user)
    }

    func deleteUser(id: Int) async throws {
        try await apiClient.delete("users/\(id)")
    }
}
```

**Kotlin:**
```kotlin
interface UserRepository {
    suspend fun getUser(id: Int): User
    suspend fun getUsers(): List<User>
    suspend fun createUser(user: User): User
    suspend fun updateUser(user: User): User
    suspend fun deleteUser(id: Int)
}

class RemoteUserRepository(
    private val apiClient: ApiClient = ApiClient
) : UserRepository {

    override suspend fun getUser(id: Int): User {
        return apiClient.get("users/$id")
    }

    override suspend fun getUsers(): List<User> {
        return apiClient.get("users")
    }

    override suspend fun createUser(user: User): User {
        return apiClient.post("users", user)
    }

    override suspend fun updateUser(user: User): User {
        return apiClient.post("users/${user.id}", user)
    }

    override suspend fun deleteUser(id: Int) {
        apiClient.delete("users/$id")
    }
}
```

## Error Handling

**Swift:**
```swift
do {
    let user = try await userRepository.getUser(id: 1)
} catch let error as APIError {
    switch error {
    case .invalidResponse:
        showError("Server error")
    case .networkError(let underlying):
        showError("Network error: \(underlying.localizedDescription)")
    case .decodingError:
        showError("Data parsing error")
    }
} catch {
    showError("Unknown error")
}
```

**Kotlin:**
```kotlin
try {
    val user = userRepository.getUser(1)
} catch (e: ApiError) {
    when (e) {
        is ApiError.HttpError -> showError("Server error: ${e.code}")
        is ApiError.NetworkError -> showError("Network error")
        is ApiError.ParseError -> showError("Data parsing error")
    }
} catch (e: Exception) {
    showError("Unknown error")
}
```
