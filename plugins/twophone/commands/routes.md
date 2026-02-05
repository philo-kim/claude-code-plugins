---
description: Deep link/routing synchronization
argument-hint: [routes.yaml | --add <path>]
---

# TwoPhone Routing

Configure deep links and in-app routing for iOS/Android simultaneously.

## Route Definition File

**shared/routes.yaml:**
```yaml
# App URL scheme
scheme: myapp
# Universal Links / App Links domain
domain: example.com

# Route definitions
routes:
  # Tab screens
  home:
    path: /
    screen:
      ios: HomeView
      android: HomeScreen

  profile:
    path: /profile
    screen:
      ios: ProfileView
      android: ProfileScreen

  settings:
    path: /settings
    screen:
      ios: SettingsView
      android: SettingsScreen

  # Routes with parameters
  user_detail:
    path: /users/:userId
    params:
      userId: string
    screen:
      ios: UserDetailView
      android: UserDetailScreen

  product_detail:
    path: /products/:productId
    params:
      productId: int
    screen:
      ios: ProductDetailView
      android: ProductDetailScreen

  # Query parameters
  search:
    path: /search
    query:
      q: string
      category: string?
    screen:
      ios: SearchView
      android: SearchScreen

  # Auth required
  checkout:
    path: /checkout
    auth: required
    screen:
      ios: CheckoutView
      android: CheckoutScreen

  # External deep link only
  reset_password:
    path: /reset-password
    params:
      token: string
    deeplink_only: true
    screen:
      ios: ResetPasswordView
      android: ResetPasswordScreen
```

## iOS Output

**ios/MyApp/Navigation/Router.swift:**
```swift
import SwiftUI

enum Route: Hashable {
    case home
    case profile
    case settings
    case userDetail(userId: String)
    case productDetail(productId: Int)
    case search(query: String?, category: String?)
    case checkout
    case resetPassword(token: String)
}

@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    // Deep link handling
    func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        let path = components.path
        let queryItems = components.queryItems ?? []

        switch path {
        case "/":
            navigate(to: .home)
        case "/profile":
            navigate(to: .profile)
        case "/settings":
            navigate(to: .settings)
        case _ where path.hasPrefix("/users/"):
            let userId = String(path.dropFirst("/users/".count))
            navigate(to: .userDetail(userId: userId))
        case _ where path.hasPrefix("/products/"):
            if let productId = Int(path.dropFirst("/products/".count)) {
                navigate(to: .productDetail(productId: productId))
            }
        case "/search":
            let q = queryItems.first { $0.name == "q" }?.value
            let category = queryItems.first { $0.name == "category" }?.value
            navigate(to: .search(query: q, category: category))
        case "/checkout":
            navigate(to: .checkout)
        case _ where path.hasPrefix("/reset-password"):
            if let token = queryItems.first(where: { $0.name == "token" })?.value {
                navigate(to: .resetPassword(token: token))
            }
        default:
            return false
        }
        return true
    }
}

// View destination mapping
extension Route {
    @ViewBuilder
    var destination: some View {
        switch self {
        case .home:
            HomeView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .userDetail(let userId):
            UserDetailView(userId: userId)
        case .productDetail(let productId):
            ProductDetailView(productId: productId)
        case .search(let query, let category):
            SearchView(query: query, category: category)
        case .checkout:
            CheckoutView()
        case .resetPassword(let token):
            ResetPasswordView(token: token)
        }
    }
}
```

**Info.plist additions (URL Schemes):**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

**Associated Domains (Universal Links):**
```
applinks:example.com
```

## Android Output

**android/app/.../navigation/Routes.kt:**
```kotlin
package com.example.myapp.navigation

sealed class Route(val route: String) {
    object Home : Route("/")
    object Profile : Route("/profile")
    object Settings : Route("/settings")

    data class UserDetail(val userId: String) : Route("/users/{userId}") {
        companion object {
            const val ROUTE = "/users/{userId}"
            fun createRoute(userId: String) = "/users/$userId"
        }
    }

    data class ProductDetail(val productId: Int) : Route("/products/{productId}") {
        companion object {
            const val ROUTE = "/products/{productId}"
            fun createRoute(productId: Int) = "/products/$productId"
        }
    }

    data class Search(val query: String? = null, val category: String? = null) : Route("/search") {
        companion object {
            const val ROUTE = "/search?q={q}&category={category}"
        }
    }

    object Checkout : Route("/checkout")

    data class ResetPassword(val token: String) : Route("/reset-password") {
        companion object {
            const val ROUTE = "/reset-password?token={token}"
        }
    }
}
```

**android/app/.../navigation/NavGraph.kt:**
```kotlin
package com.example.myapp.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink
import com.example.myapp.features.home.HomeScreen
import com.example.myapp.features.profile.ProfileScreen
// ... other imports

@Composable
fun AppNavGraph(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Route.Home.route) {

        composable(Route.Home.route) {
            HomeScreen()
        }

        composable(Route.Profile.route) {
            ProfileScreen()
        }

        composable(Route.Settings.route) {
            SettingsScreen()
        }

        composable(
            route = Route.UserDetail.ROUTE,
            arguments = listOf(navArgument("userId") { type = NavType.StringType }),
            deepLinks = listOf(
                navDeepLink { uriPattern = "myapp://users/{userId}" },
                navDeepLink { uriPattern = "https://example.com/users/{userId}" }
            )
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getString("userId") ?: return@composable
            UserDetailScreen(userId = userId)
        }

        composable(
            route = Route.ProductDetail.ROUTE,
            arguments = listOf(navArgument("productId") { type = NavType.IntType }),
            deepLinks = listOf(
                navDeepLink { uriPattern = "myapp://products/{productId}" },
                navDeepLink { uriPattern = "https://example.com/products/{productId}" }
            )
        ) { backStackEntry ->
            val productId = backStackEntry.arguments?.getInt("productId") ?: return@composable
            ProductDetailScreen(productId = productId)
        }

        composable(
            route = Route.Search.ROUTE,
            arguments = listOf(
                navArgument("q") { type = NavType.StringType; nullable = true },
                navArgument("category") { type = NavType.StringType; nullable = true }
            )
        ) { backStackEntry ->
            val query = backStackEntry.arguments?.getString("q")
            val category = backStackEntry.arguments?.getString("category")
            SearchScreen(query = query, category = category)
        }

        composable(Route.Checkout.route) {
            CheckoutScreen()
        }

        composable(
            route = Route.ResetPassword.ROUTE,
            deepLinks = listOf(
                navDeepLink { uriPattern = "myapp://reset-password?token={token}" },
                navDeepLink { uriPattern = "https://example.com/reset-password?token={token}" }
            )
        ) { backStackEntry ->
            val token = backStackEntry.arguments?.getString("token") ?: return@composable
            ResetPasswordScreen(token = token)
        }
    }
}
```

**AndroidManifest.xml additions:**
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myapp" />
</intent-filter>

<!-- App Links -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="example.com" />
</intent-filter>
```

## Add Route

```
/twophone routes --add /orders/:orderId
```

→ Adds to routes.yaml + regenerates code
