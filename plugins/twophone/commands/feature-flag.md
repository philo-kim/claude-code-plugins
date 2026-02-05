---
description: Feature flag management (Firebase Remote Config)
argument-hint: <flag-name> [--add | --remove | --sync]
---

# TwoPhone Feature Flags

Configure feature flags for iOS/Android simultaneously using Firebase Remote Config.

## Commands

### Add new flag
```
/twophone feature-flag --add dark_mode_enabled
/twophone feature-flag --add new_checkout_flow --type bool --default false
/twophone feature-flag --add max_items_per_page --type int --default 20
```

### Sync flags (generate code)
```
/twophone feature-flag --sync
```

### Remove flag
```
/twophone feature-flag --remove old_feature
```

## Flag Definition File

**shared/feature-flags.yaml:**
```yaml
flags:
  # Boolean flags
  dark_mode_enabled:
    type: bool
    default: true
    description: "Enable dark mode"

  new_checkout_flow:
    type: bool
    default: false
    description: "Use new checkout flow"

  show_promotions:
    type: bool
    default: true
    description: "Show promotion banners"

  # Number flags
  max_items_per_page:
    type: int
    default: 20
    description: "Maximum items per page"

  cache_ttl_seconds:
    type: int
    default: 300
    description: "Cache TTL in seconds"

  # String flags
  api_version:
    type: string
    default: "v1"
    description: "API version to use"

  welcome_message:
    type: string
    default: "Welcome!"
    description: "Welcome message"

  # JSON flags (complex configuration)
  onboarding_config:
    type: json
    default:
      steps: 3
      skippable: true
      showVideo: false
    description: "Onboarding configuration"
```

## iOS Output

**ios/MyApp/Services/FeatureFlags.swift:**
```swift
import Foundation
import FirebaseRemoteConfig

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    private let remoteConfig = RemoteConfig.remoteConfig()

    // Boolean flags
    var darkModeEnabled: Bool = true
    var newCheckoutFlow: Bool = false
    var showPromotions: Bool = true

    // Number flags
    var maxItemsPerPage: Int = 20
    var cacheTTLSeconds: Int = 300

    // String flags
    var apiVersion: String = "v1"
    var welcomeMessage: String = "Welcome!"

    // JSON flags
    var onboardingConfig: OnboardingConfig = .default

    struct OnboardingConfig: Codable {
        var steps: Int
        var skippable: Bool
        var showVideo: Bool

        static let `default` = OnboardingConfig(steps: 3, skippable: true, showVideo: false)
    }

    private init() {
        setupDefaults()
    }

    private func setupDefaults() {
        let defaults: [String: NSObject] = [
            "dark_mode_enabled": true as NSObject,
            "new_checkout_flow": false as NSObject,
            "show_promotions": true as NSObject,
            "max_items_per_page": 20 as NSObject,
            "cache_ttl_seconds": 300 as NSObject,
            "api_version": "v1" as NSObject,
            "welcome_message": "Welcome!" as NSObject,
            "onboarding_config": "{\"steps\":3,\"skippable\":true,\"showVideo\":false}" as NSObject
        ]
        remoteConfig.setDefaults(defaults)

        // Fetch frequently during development
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        #endif
    }

    @MainActor
    func fetch() async {
        do {
            let status = try await remoteConfig.fetch()
            if status == .success {
                try await remoteConfig.activate()
                updateValues()
            }
        } catch {
            print("Remote config fetch failed: \(error)")
        }
    }

    private func updateValues() {
        darkModeEnabled = remoteConfig["dark_mode_enabled"].boolValue
        newCheckoutFlow = remoteConfig["new_checkout_flow"].boolValue
        showPromotions = remoteConfig["show_promotions"].boolValue

        maxItemsPerPage = remoteConfig["max_items_per_page"].numberValue.intValue
        cacheTTLSeconds = remoteConfig["cache_ttl_seconds"].numberValue.intValue

        apiVersion = remoteConfig["api_version"].stringValue ?? "v1"
        welcomeMessage = remoteConfig["welcome_message"].stringValue ?? "Welcome!"

        if let jsonString = remoteConfig["onboarding_config"].stringValue,
           let data = jsonString.data(using: .utf8),
           let config = try? JSONDecoder().decode(OnboardingConfig.self, from: data) {
            onboardingConfig = config
        }
    }
}

// Usage example
// if FeatureFlags.shared.newCheckoutFlow {
//     NewCheckoutView()
// } else {
//     LegacyCheckoutView()
// }
```

## Android Output

**android/app/.../services/FeatureFlags.kt:**
```kotlin
package com.example.myapp.services

import com.google.firebase.ktx.Firebase
import com.google.firebase.remoteconfig.ktx.remoteConfig
import com.google.firebase.remoteconfig.ktx.remoteConfigSettings
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

object FeatureFlags {
    private val remoteConfig = Firebase.remoteConfig

    // Boolean flags
    private val _darkModeEnabled = MutableStateFlow(true)
    val darkModeEnabled: StateFlow<Boolean> = _darkModeEnabled.asStateFlow()

    private val _newCheckoutFlow = MutableStateFlow(false)
    val newCheckoutFlow: StateFlow<Boolean> = _newCheckoutFlow.asStateFlow()

    private val _showPromotions = MutableStateFlow(true)
    val showPromotions: StateFlow<Boolean> = _showPromotions.asStateFlow()

    // Number flags
    private val _maxItemsPerPage = MutableStateFlow(20)
    val maxItemsPerPage: StateFlow<Int> = _maxItemsPerPage.asStateFlow()

    private val _cacheTTLSeconds = MutableStateFlow(300)
    val cacheTTLSeconds: StateFlow<Int> = _cacheTTLSeconds.asStateFlow()

    // String flags
    private val _apiVersion = MutableStateFlow("v1")
    val apiVersion: StateFlow<String> = _apiVersion.asStateFlow()

    private val _welcomeMessage = MutableStateFlow("Welcome!")
    val welcomeMessage: StateFlow<String> = _welcomeMessage.asStateFlow()

    // JSON flags
    private val _onboardingConfig = MutableStateFlow(OnboardingConfig())
    val onboardingConfig: StateFlow<OnboardingConfig> = _onboardingConfig.asStateFlow()

    @Serializable
    data class OnboardingConfig(
        val steps: Int = 3,
        val skippable: Boolean = true,
        val showVideo: Boolean = false
    )

    init {
        setupDefaults()
    }

    private fun setupDefaults() {
        val defaults = mapOf(
            "dark_mode_enabled" to true,
            "new_checkout_flow" to false,
            "show_promotions" to true,
            "max_items_per_page" to 20L,
            "cache_ttl_seconds" to 300L,
            "api_version" to "v1",
            "welcome_message" to "Welcome!",
            "onboarding_config" to """{"steps":3,"skippable":true,"showVideo":false}"""
        )
        remoteConfig.setDefaultsAsync(defaults)

        // Fetch frequently during development
        val configSettings = remoteConfigSettings {
            minimumFetchIntervalInSeconds = if (BuildConfig.DEBUG) 0 else 3600
        }
        remoteConfig.setConfigSettingsAsync(configSettings)
    }

    suspend fun fetch() {
        try {
            remoteConfig.fetchAndActivate().await()
            updateValues()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateValues() {
        _darkModeEnabled.value = remoteConfig.getBoolean("dark_mode_enabled")
        _newCheckoutFlow.value = remoteConfig.getBoolean("new_checkout_flow")
        _showPromotions.value = remoteConfig.getBoolean("show_promotions")

        _maxItemsPerPage.value = remoteConfig.getLong("max_items_per_page").toInt()
        _cacheTTLSeconds.value = remoteConfig.getLong("cache_ttl_seconds").toInt()

        _apiVersion.value = remoteConfig.getString("api_version")
        _welcomeMessage.value = remoteConfig.getString("welcome_message")

        try {
            val jsonString = remoteConfig.getString("onboarding_config")
            _onboardingConfig.value = Json.decodeFromString(jsonString)
        } catch (e: Exception) {
            // Keep default value
        }
    }
}

// Usage example
// val newCheckout by FeatureFlags.newCheckoutFlow.collectAsState()
// if (newCheckout) {
//     NewCheckoutScreen()
// } else {
//     LegacyCheckoutScreen()
// }
```

## Firebase Console Setup

Add Remote Config parameters in Firebase Console:

| Parameter | Default | Condition |
|-----------|---------|-----------|
| `dark_mode_enabled` | `true` | - |
| `new_checkout_flow` | `false` | 10% rollout |
| `show_promotions` | `true` | - |

## A/B Testing Integration

```yaml
# Add to shared/feature-flags.yaml
flags:
  new_checkout_flow:
    type: bool
    default: false
    experiment:
      name: "checkout_experiment"
      variants:
        control: false
        treatment: true
      traffic_allocation: 50  # Expose to 50% of users
```
