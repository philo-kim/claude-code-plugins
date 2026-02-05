---
description: Push notification setup (FCM)
argument-hint: [--setup | --handler]
---

# TwoPhone Push Notifications

Configure Firebase Cloud Messaging (FCM) for iOS/Android simultaneously.

## Commands

### Initial setup
```
/twophone push --setup
```

### Generate handler code
```
/twophone push --handler
```

## Prerequisites

1. Create Firebase project
2. Register iOS app → Download `GoogleService-Info.plist`
3. Register Android app → Download `google-services.json`

**File locations:**
```
shared/
├── firebase/
│   ├── GoogleService-Info.plist
│   └── google-services.json
```

## iOS Setup

### 1. SPM Dependency
```swift
// Add via Package.swift or Xcode
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]
```

### 2. AppDelegate Setup

**ios/MyApp/App/AppDelegate.swift:**
```swift
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // Request notification permission
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            print("Notification permission granted: \(granted)")
        }

        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return true
    }

    // Receive APNS token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Receive FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "none")")
        // Send token to server
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": fcmToken ?? ""]
        )
    }

    // Receive notification in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        completionHandler()
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        // Handle deep link
        if let deepLink = userInfo["deepLink"] as? String,
           let url = URL(string: deepLink) {
            // Handle deep link via Router
            NotificationCenter.default.post(
                name: Notification.Name("DeepLink"),
                object: nil,
                userInfo: ["url": url]
            )
        }
    }
}
```

### 3. SwiftUI App Connection

**ios/MyApp/MyAppApp.swift:**
```swift
import SwiftUI

@main
struct MyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Android Setup

### 1. Gradle Dependencies

**android/build.gradle.kts (project):**
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

**android/app/build.gradle.kts:**
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
}
```

### 2. FCM Service

**android/app/.../services/MyFirebaseMessagingService.kt:**
```kotlin
package com.example.myapp.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.example.myapp.MainActivity
import com.example.myapp.R

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Send token to server
        sendTokenToServer(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // Handle data message
        remoteMessage.data.isNotEmpty().let {
            handleDataMessage(remoteMessage.data)
        }

        // Show notification
        remoteMessage.notification?.let {
            showNotification(it.title, it.body, remoteMessage.data)
        }
    }

    private fun handleDataMessage(data: Map<String, String>) {
        val deepLink = data["deepLink"]
        // Deep link handling logic
    }

    private fun showNotification(title: String?, body: String?, data: Map<String, String>) {
        val channelId = "default_channel"
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        // Create channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Default",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        // Deep link intent
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            data["deepLink"]?.let { putExtra("deepLink", it) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun sendTokenToServer(token: String) {
        // API call to save token on server
    }
}
```

### 3. AndroidManifest.xml

```xml
<service
    android:name=".services.MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Notification Payload Format

Common format sent from server:
```json
{
  "to": "<fcm_token>",
  "notification": {
    "title": "New Message",
    "body": "John sent you a message."
  },
  "data": {
    "deepLink": "myapp://messages/123",
    "type": "message",
    "messageId": "123"
  }
}
```
