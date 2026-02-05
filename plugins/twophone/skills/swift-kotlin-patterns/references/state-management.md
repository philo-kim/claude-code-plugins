# State Management Patterns

## ViewModel Pattern Comparison

| Item | Swift (iOS 17+) | Kotlin (Jetpack) |
|------|-----------------|------------------|
| State | `@Observable` | `StateFlow` |
| Lifecycle | View-owned | Activity/Fragment-owned |
| DI | Manual / Swinject | Hilt / Koin |

## Basic ViewModel

**Swift:**
```swift
import SwiftUI
import Observation

@Observable
final class CounterViewModel {
    var count = 0
    var isLoading = false

    func increment() {
        count += 1
    }

    func decrement() {
        count -= 1
    }

    @MainActor
    func loadFromServer() async {
        isLoading = true
        defer { isLoading = false }

        // Load from server
        try? await Task.sleep(for: .seconds(1))
        count = 42
    }
}

struct CounterView: View {
    @State private var viewModel = CounterViewModel()

    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")

            HStack {
                Button("-") { viewModel.decrement() }
                Button("+") { viewModel.increment() }
            }

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadFromServer()
        }
    }
}
```

**Kotlin:**
```kotlin
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class CounterViewModel : ViewModel() {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun increment() {
        _count.value++
    }

    fun decrement() {
        _count.value--
    }

    fun loadFromServer() {
        viewModelScope.launch {
            _isLoading.value = true
            // Load from server
            delay(1000)
            _count.value = 42
            _isLoading.value = false
        }
    }
}

@Composable
fun CounterScreen(viewModel: CounterViewModel = viewModel()) {
    val count by viewModel.count.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadFromServer()
    }

    Column {
        Text("Count: $count")

        Row {
            Button(onClick = { viewModel.decrement() }) { Text("-") }
            Button(onClick = { viewModel.increment() }) { Text("+") }
        }

        if (isLoading) {
            CircularProgressIndicator()
        }
    }
}
```

## UiState Pattern (Recommended)

**Swift:**
```swift
@Observable
final class UserListViewModel {
    enum State {
        case idle
        case loading
        case loaded([User])
        case error(String)
    }

    var state: State = .idle

    @MainActor
    func load() async {
        state = .loading
        do {
            let users = try await userRepository.getUsers()
            state = .loaded(users)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

struct UserListView: View {
    @State private var viewModel = UserListViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
            case .loaded(let users):
                List(users) { user in
                    Text(user.name)
                }
            case .error(let message):
                ContentUnavailableView("Error", systemImage: "xmark", description: Text(message))
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

**Kotlin:**
```kotlin
sealed class UserListUiState {
    object Idle : UserListUiState()
    object Loading : UserListUiState()
    data class Loaded(val users: List<User>) : UserListUiState()
    data class Error(val message: String) : UserListUiState()
}

class UserListViewModel(
    private val userRepository: UserRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<UserListUiState>(UserListUiState.Idle)
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _uiState.value = UserListUiState.Loading
            try {
                val users = userRepository.getUsers()
                _uiState.value = UserListUiState.Loaded(users)
            } catch (e: Exception) {
                _uiState.value = UserListUiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}

@Composable
fun UserListScreen(viewModel: UserListViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.load()
    }

    when (val state = uiState) {
        is UserListUiState.Idle -> {}
        is UserListUiState.Loading -> CircularProgressIndicator()
        is UserListUiState.Loaded -> {
            LazyColumn {
                items(state.users) { user ->
                    Text(user.name)
                }
            }
        }
        is UserListUiState.Error -> {
            Text(state.message, color = MaterialTheme.colorScheme.error)
        }
    }
}
```

## Event Handling (One-time Events)

**Swift:**
```swift
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false

    // One-time event
    var loginSuccess: Bool? = nil
    var errorMessage: String? = nil

    @MainActor
    func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.login(email: email, password: password)
            loginSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField("Email", text: $viewModel.email)
            SecureField("Password", text: $viewModel.password)
            Button("Login") {
                Task { await viewModel.login() }
            }
        }
        .onChange(of: viewModel.loginSuccess) { _, success in
            if success == true {
                dismiss()
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

**Kotlin:**
```kotlin
sealed class LoginEvent {
    object Success : LoginEvent()
    data class Error(val message: String) : LoginEvent()
}

class LoginViewModel(
    private val authService: AuthService
) : ViewModel() {
    var email by mutableStateOf("")
    var password by mutableStateOf("")

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // One-time events via Channel
    private val _events = Channel<LoginEvent>(Channel.BUFFERED)
    val events: Flow<LoginEvent> = _events.receiveAsFlow()

    fun login() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                authService.login(email, password)
                _events.send(LoginEvent.Success)
            } catch (e: Exception) {
                _events.send(LoginEvent.Error(e.message ?: "Unknown error"))
            } finally {
                _isLoading.value = false
            }
        }
    }
}

@Composable
fun LoginScreen(
    viewModel: LoginViewModel = viewModel(),
    onLoginSuccess: () -> Unit
) {
    val isLoading by viewModel.isLoading.collectAsState()
    var showError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is LoginEvent.Success -> onLoginSuccess()
                is LoginEvent.Error -> showError = event.message
            }
        }
    }

    Column {
        TextField(
            value = viewModel.email,
            onValueChange = { viewModel.email = it },
            label = { Text("Email") }
        )
        TextField(
            value = viewModel.password,
            onValueChange = { viewModel.password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation()
        )
        Button(
            onClick = { viewModel.login() },
            enabled = !isLoading
        ) {
            Text("Login")
        }
    }

    showError?.let { message ->
        AlertDialog(
            onDismissRequest = { showError = null },
            title = { Text("Error") },
            text = { Text(message) },
            confirmButton = {
                Button(onClick = { showError = null }) { Text("OK") }
            }
        )
    }
}
```
