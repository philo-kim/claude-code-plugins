---
description: Test code synchronization and generation
argument-hint: [--sync | --generate <feature>]
---

# TwoPhone Tests

Generate iOS/Android test code simultaneously from a unified test specification.

## Commands

### Sync tests
```
/twophone test --sync
```

### Generate tests for specific feature
```
/twophone test --generate auth
/twophone test --generate user-profile
```

## Test Specification File

**shared/tests/auth.yaml:**
```yaml
feature: auth
description: Authentication related tests

unit_tests:
  - name: login_with_valid_credentials
    description: Login succeeds with valid credentials
    given:
      - email: "test@example.com"
      - password: "password123"
    when: login
    then:
      - success: true
      - user_not_null: true

  - name: login_with_invalid_email
    description: Login fails with invalid email
    given:
      - email: "invalid"
      - password: "password123"
    when: login
    then:
      - error: "invalid_email"

  - name: login_with_wrong_password
    description: Login fails with wrong password
    given:
      - email: "test@example.com"
      - password: "wrong"
    when: login
    then:
      - error: "invalid_credentials"

  - name: logout_clears_session
    description: Logout clears session data
    given:
      - logged_in: true
    when: logout
    then:
      - session: null
      - token: null

viewmodel_tests:
  - name: login_updates_loading_state
    description: Loading state updates during login
    steps:
      - initial_state:
          isLoading: false
      - action: login
      - expected_state:
          isLoading: true
      - on_complete:
          isLoading: false

ui_tests:
  - name: login_button_disabled_when_empty
    description: Login button disabled when inputs are empty
    steps:
      - screen: LoginScreen
      - assert: login_button.disabled

  - name: login_flow_success
    description: Navigate to home screen after successful login
    steps:
      - screen: LoginScreen
      - input: email_field, "test@example.com"
      - input: password_field, "password123"
      - tap: login_button
      - wait: 2s
      - assert: HomeScreen.visible
```

## iOS Test Output

**ios/MyAppTests/AuthTests.swift:**
```swift
import XCTest
@testable import MyApp

final class AuthTests: XCTestCase {

    var authService: AuthService!

    override func setUp() {
        super.setUp()
        authService = AuthService()
    }

    override func tearDown() {
        authService = nil
        super.tearDown()
    }

    // MARK: - Login succeeds with valid credentials

    func test_login_with_valid_credentials() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"

        // When
        let result = try await authService.login(email: email, password: password)

        // Then
        XCTAssertNotNil(result.user)
    }

    // MARK: - Login fails with invalid email

    func test_login_with_invalid_email() async {
        // Given
        let email = "invalid"
        let password = "password123"

        // When/Then
        do {
            _ = try await authService.login(email: email, password: password)
            XCTFail("Expected error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Login fails with wrong password

    func test_login_with_wrong_password() async {
        // Given
        let email = "test@example.com"
        let password = "wrong"

        // When/Then
        do {
            _ = try await authService.login(email: email, password: password)
            XCTFail("Expected error to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Logout clears session

    func test_logout_clears_session() async throws {
        // Given
        try await authService.login(email: "test@example.com", password: "password123")

        // When
        await authService.logout()

        // Then
        XCTAssertNil(authService.currentSession)
        XCTAssertNil(authService.token)
    }
}
```

**ios/MyAppTests/AuthViewModelTests.swift:**
```swift
import XCTest
@testable import MyApp

@MainActor
final class AuthViewModelTests: XCTestCase {

    var viewModel: LoginViewModel!

    override func setUp() {
        super.setUp()
        viewModel = LoginViewModel()
    }

    // MARK: - Loading state updates during login

    func test_login_updates_loading_state() async {
        // Initial state
        XCTAssertFalse(viewModel.isLoading)

        // Start login (don't await)
        let task = Task {
            await viewModel.login()
        }

        // During login
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(viewModel.isLoading)

        // Wait for completion
        await task.value

        // After login
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## Android Test Output

**android/app/src/test/java/.../AuthTest.kt:**
```kotlin
package com.example.myapp

import com.example.myapp.services.AuthService
import com.example.myapp.services.AuthError
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertFailsWith

class AuthTest {

    private lateinit var authService: AuthService

    @Before
    fun setUp() {
        authService = AuthService()
    }

    // Login succeeds with valid credentials
    @Test
    fun `login with valid credentials succeeds`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "password123"

        // When
        val result = authService.login(email, password)

        // Then
        assertNotNull(result.user)
    }

    // Login fails with invalid email
    @Test
    fun `login with invalid email fails`() = runTest {
        // Given
        val email = "invalid"
        val password = "password123"

        // When/Then
        val error = assertFailsWith<AuthError> {
            authService.login(email, password)
        }
        assertEquals(AuthError.InvalidEmail, error)
    }

    // Login fails with wrong password
    @Test
    fun `login with wrong password fails`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "wrong"

        // When/Then
        val error = assertFailsWith<AuthError> {
            authService.login(email, password)
        }
        assertEquals(AuthError.InvalidCredentials, error)
    }

    // Logout clears session
    @Test
    fun `logout clears session`() = runTest {
        // Given
        authService.login("test@example.com", "password123")

        // When
        authService.logout()

        // Then
        assertNull(authService.currentSession)
        assertNull(authService.token)
    }
}
```

**android/app/src/test/java/.../AuthViewModelTest.kt:**
```kotlin
package com.example.myapp

import com.example.myapp.features.auth.LoginViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: LoginViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = LoginViewModel()
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // Loading state updates during login
    @Test
    fun `login updates loading state`() = runTest {
        // Initial state
        assertFalse(viewModel.uiState.value.isLoading)

        // Start login
        viewModel.login()

        // During login
        advanceUntilIdle()

        // After login
        assertFalse(viewModel.uiState.value.isLoading)
    }
}
```

## Run Tests

```
/twophone test --run unit      # Unit tests only
/twophone test --run ui        # UI tests only
/twophone test --run all       # All tests
```
