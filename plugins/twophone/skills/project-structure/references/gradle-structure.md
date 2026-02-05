# Gradle Project Structure Details

## Root Project

**settings.gradle.kts:**
```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MyApp"
include(":app")
// For multi-module
// include(":core:network")
// include(":core:database")
// include(":feature:auth")
```

**build.gradle.kts (root):**
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.hilt) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
```

## Version Catalog

**gradle/libs.versions.toml:**
```toml
[versions]
agp = "8.2.0"
kotlin = "1.9.22"
compose-bom = "2024.01.00"
compose-compiler = "1.5.8"
hilt = "2.50"
ktor = "2.3.7"
coroutines = "1.7.3"

[libraries]
# Compose
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
compose-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }

# Lifecycle
lifecycle-runtime = { group = "androidx.lifecycle", name = "lifecycle-runtime-ktx", version = "2.7.0" }
lifecycle-viewmodel = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version = "2.7.0" }

# Networking
ktor-core = { group = "io.ktor", name = "ktor-client-core", version.ref = "ktor" }
ktor-cio = { group = "io.ktor", name = "ktor-client-cio", version.ref = "ktor" }
ktor-serialization = { group = "io.ktor", name = "ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-content = { group = "io.ktor", name = "ktor-client-content-negotiation", version.ref = "ktor" }

# DI
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }

# Serialization
kotlinx-serialization = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version = "1.6.2" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

## App Module

**app/build.gradle.kts:**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.hilt)
    kotlin("kapt")
}

android {
    namespace = "com.example.myapp"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            buildConfigField("String", "API_BASE_URL", "\"https://dev-api.example.com\"")
        }
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("String", "API_BASE_URL", "\"https://api.example.com\"")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.compose.compiler.get()
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Compose BOM
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.preview)
    debugImplementation("androidx.compose.ui:ui-tooling")

    // Lifecycle
    implementation(libs.lifecycle.runtime)
    implementation(libs.lifecycle.viewmodel)

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.6")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // Networking
    implementation(libs.ktor.core)
    implementation(libs.ktor.cio)
    implementation(libs.ktor.serialization)
    implementation(libs.ktor.content)
    implementation(libs.kotlinx.serialization)

    // DI
    implementation(libs.hilt.android)
    kapt(libs.hilt.compiler)

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
}
```

## Multi-Module Structure (Large Apps)

```
my-app/
├── app/                     # App module (main)
├── core/
│   ├── network/            # Network module
│   ├── database/           # Local DB module
│   ├── ui/                 # Common UI components
│   └── common/             # Common utilities
├── feature/
│   ├── auth/               # Auth feature
│   ├── home/               # Home feature
│   └── profile/            # Profile feature
└── data/
    ├── user/               # User data layer
    └── product/            # Product data layer
```

**core/network/build.gradle.kts:**
```kotlin
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.example.myapp.core.network"
    // ...
}

dependencies {
    implementation(libs.ktor.core)
    implementation(libs.ktor.cio)
    implementation(libs.kotlinx.serialization)
}
```

## ProGuard Rules

**proguard-rules.pro:**
```proguard
# Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep app models
-keep class com.example.myapp.models.** { *; }

# Ktor
-keep class io.ktor.** { *; }
```

## Resource Structure

```
res/
├── values/
│   ├── strings.xml          # Strings
│   ├── colors.xml           # Colors
│   ├── themes.xml           # Themes
│   └── dimens.xml           # Dimensions
├── values-ko/
│   └── strings.xml          # Korean
├── drawable/                # Vectors/images
├── mipmap-xxxhdpi/          # App icons
└── font/                    # Custom fonts
```
