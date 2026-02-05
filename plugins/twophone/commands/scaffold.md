---
description: Generate MVVM structure for new feature on both platforms
argument-hint: <feature-name>
---

# TwoPhone Feature Scaffolding

Generate MVVM structure for a new feature on both iOS and Android simultaneously.

## Input
- Feature name: `$ARGUMENTS` (required, e.g., `login`, `user-profile`, `product-list`)

## Execution Steps

### 1. Verify Feature Name
If feature name is not provided, ask the user.

Name conversions:
- Original: `user-profile`
- PascalCase: `UserProfile`
- camelCase: `userProfile`
- snake_case: `user_profile`

### 2. Check Project Configuration
Read project info from `.twophone.json`.

### 3. Generate iOS Files

Generate in `ios/<ProjectName>/Features/<FeatureName>/` directory:

**<FeatureName>View.swift:**
```swift
import SwiftUI

struct <FeatureName>View: View {
    @State private var viewModel = <FeatureName>ViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("<Feature Name>")
                .task {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.error {
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            // TODO: Add your content here
            Text("<FeatureName> Content")
        }
    }
}

#Preview {
    <FeatureName>View()
}
```

**<FeatureName>ViewModel.swift:**
```swift
import Foundation
import Observation

@Observable
final class <FeatureName>ViewModel {
    var isLoading = false
    var error: String?

    // TODO: Add your state properties here

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // TODO: Load data
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

### 4. Generate Android Files

Generate in `android/app/src/main/java/com/example/<projectname>/features/<featurename>/` directory:

**<FeatureName>Screen.kt:**
```kotlin
package com.example.<projectname>.features.<featurename>

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun <FeatureName>Screen(
    viewModel: <FeatureName>ViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.load()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("<Feature Name>") }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator()
                }
                uiState.error != null -> {
                    Text(
                        text = uiState.error ?: "Unknown error",
                        color = MaterialTheme.colorScheme.error
                    )
                }
                else -> {
                    // TODO: Add your content here
                    Text("<FeatureName> Content")
                }
            }
        }
    }
}
```

**<FeatureName>ViewModel.kt:**
```kotlin
package com.example.<projectname>.features.<featurename>

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class <FeatureName>UiState(
    val isLoading: Boolean = false,
    val error: String? = null
    // TODO: Add your state properties here
)

class <FeatureName>ViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(<FeatureName>UiState())
    val uiState: StateFlow<<FeatureName>UiState> = _uiState.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                // TODO: Load data
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            } finally {
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }
}
```

### 5. Final Report

Output list of generated files and next steps:

```
✅ <FeatureName> feature scaffolding complete

iOS files:
  - ios/<ProjectName>/Features/<FeatureName>/<FeatureName>View.swift
  - ios/<ProjectName>/Features/<FeatureName>/<FeatureName>ViewModel.swift

Android files:
  - android/app/.../features/<featurename>/<FeatureName>Screen.kt
  - android/app/.../features/<featurename>/<FeatureName>ViewModel.kt

Next steps:
1. Add state properties and logic to ViewModel
2. Implement UI in View/Screen
3. Connect navigation (routing)
4. Use `/twophone sync` to keep both platforms in sync
```

## Additional Options

Upon user request, can also generate:

- **Repository pattern**: Separate data layer
- **Unit tests**: Test file templates
- **Navigation connection**: Register screen in router
