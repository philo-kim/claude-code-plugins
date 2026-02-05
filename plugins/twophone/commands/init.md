---
description: Create new iOS/Android project simultaneously
argument-hint: <project-name>
---

# TwoPhone Project Initialization

User wants to create a new cross-platform mobile project.

## Input
- Project name: `$ARGUMENTS` (ask user if not provided)

## Execution Steps

### 1. Verify Project Name
If project name is not provided, ask the user.
Project name allows only alphanumeric characters and hyphens.

### 2. Create Directory Structure
Create the following structure in the current directory:

```
<project-name>/
├── ios/
│   └── <ProjectName>/
│       ├── <ProjectName>App.swift
│       ├── ContentView.swift
│       ├── Features/
│       ├── Models/
│       ├── Services/
│       └── Resources/
├── android/
│   └── app/
│       └── src/main/
│           ├── java/com/example/<projectname>/
│           │   ├── MainActivity.kt
│           │   ├── MainApplication.kt
│           │   ├── features/
│           │   ├── models/
│           │   └── services/
│           └── res/
├── shared/
│   └── api-spec.yaml      # Common API spec
└── .twophone.json         # Project configuration
```

### 3. Create iOS Project Files

**<ProjectName>App.swift:**
```swift
import SwiftUI

@main
struct <ProjectName>App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**ContentView.swift:**
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Hello, <ProjectName>!")
                .navigationTitle("<ProjectName>")
        }
    }
}

#Preview {
    ContentView()
}
```

### 4. Create Android Project Files

**MainActivity.kt:**
```kotlin
package com.example.<projectname>

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Greeting("<ProjectName>")
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello, $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    MaterialTheme {
        Greeting("<ProjectName>")
    }
}
```

**build.gradle.kts (app):**
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.<projectname>"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.<projectname>"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
}
```

### 5. Create Common Configuration Files

**.twophone.json:**
```json
{
  "projectName": "<ProjectName>",
  "platforms": {
    "ios": {
      "path": "ios/<ProjectName>",
      "bundleId": "com.example.<projectname>",
      "minVersion": "16.0"
    },
    "android": {
      "path": "android/app",
      "packageName": "com.example.<projectname>",
      "minSdk": 26
    }
  },
  "sync": {
    "models": true,
    "services": true
  }
}
```

**shared/api-spec.yaml:**
```yaml
openapi: 3.0.0
info:
  title: <ProjectName> API
  version: 1.0.0
paths: {}
components:
  schemas: {}
```

### 6. Completion Message

After project creation, inform the user about:
- Created directory structure
- Next steps (open in Xcode/Android Studio)
- Available TwoPhone commands:
  - `/twophone sync` - Code synchronization
  - `/twophone model` - API model generation
  - `/twophone scaffold` - Feature scaffolding

## Notes
- PascalCase conversion: `my-app` → `MyApp`
- Package name is lowercase: `my-app` → `myapp`
- Confirm before overwriting existing directory
