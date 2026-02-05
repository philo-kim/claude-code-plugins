---
description: Sync design system (colors, typography, spacing)
argument-hint: [design-tokens.yaml | --from-figma <url>]
---

# TwoPhone Design System

Apply design tokens to iOS and Android simultaneously.

## Input Sources

1. **YAML/JSON file** (default): `shared/design-tokens.yaml`
2. **Figma URL**: `--from-figma <figma-url>` (using Figma MCP)

## Design Token File Format

**shared/design-tokens.yaml:**
```yaml
colors:
  primary:
    default: "#007AFF"
    light: "#5AC8FA"
    dark: "#0051D4"
  secondary:
    default: "#5856D6"
  background:
    primary: "#FFFFFF"
    secondary: "#F2F2F7"
  text:
    primary: "#000000"
    secondary: "#8E8E93"
  error: "#FF3B30"
  success: "#34C759"
  warning: "#FF9500"

typography:
  largeTitle:
    size: 34
    weight: bold
    lineHeight: 41
  title1:
    size: 28
    weight: bold
    lineHeight: 34
  title2:
    size: 22
    weight: bold
    lineHeight: 28
  headline:
    size: 17
    weight: semibold
    lineHeight: 22
  body:
    size: 17
    weight: regular
    lineHeight: 22
  caption:
    size: 12
    weight: regular
    lineHeight: 16

spacing:
  xs: 4
  sm: 8
  md: 16
  lg: 24
  xl: 32
  xxl: 48

radius:
  sm: 4
  md: 8
  lg: 12
  xl: 16
  full: 9999
```

## iOS Output

**ios/MyApp/Resources/Colors.swift:**
```swift
import SwiftUI

extension Color {
    // MARK: - Primary
    static let primaryDefault = Color(hex: "#007AFF")
    static let primaryLight = Color(hex: "#5AC8FA")
    static let primaryDark = Color(hex: "#0051D4")

    // MARK: - Secondary
    static let secondaryDefault = Color(hex: "#5856D6")

    // MARK: - Background
    static let backgroundPrimary = Color(hex: "#FFFFFF")
    static let backgroundSecondary = Color(hex: "#F2F2F7")

    // MARK: - Text
    static let textPrimary = Color(hex: "#000000")
    static let textSecondary = Color(hex: "#8E8E93")

    // MARK: - Semantic
    static let error = Color(hex: "#FF3B30")
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**ios/MyApp/Resources/Typography.swift:**
```swift
import SwiftUI

extension Font {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}
```

**ios/MyApp/Resources/Spacing.swift:**
```swift
import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let full: CGFloat = 9999
}
```

## Android Output

**android/app/.../ui/theme/Color.kt:**
```kotlin
package com.example.myapp.ui.theme

import androidx.compose.ui.graphics.Color

// Primary
val PrimaryDefault = Color(0xFF007AFF)
val PrimaryLight = Color(0xFF5AC8FA)
val PrimaryDark = Color(0xFF0051D4)

// Secondary
val SecondaryDefault = Color(0xFF5856D6)

// Background
val BackgroundPrimary = Color(0xFFFFFFFF)
val BackgroundSecondary = Color(0xFFF2F2F7)

// Text
val TextPrimary = Color(0xFF000000)
val TextSecondary = Color(0xFF8E8E93)

// Semantic
val Error = Color(0xFFFF3B30)
val Success = Color(0xFF34C759)
val Warning = Color(0xFFFF9500)
```

**android/app/.../ui/theme/Type.kt:**
```kotlin
package com.example.myapp.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val AppTypography = Typography(
    displayLarge = TextStyle(
        fontSize = 34.sp,
        fontWeight = FontWeight.Bold,
        lineHeight = 41.sp
    ),
    headlineLarge = TextStyle(
        fontSize = 28.sp,
        fontWeight = FontWeight.Bold,
        lineHeight = 34.sp
    ),
    headlineMedium = TextStyle(
        fontSize = 22.sp,
        fontWeight = FontWeight.Bold,
        lineHeight = 28.sp
    ),
    titleLarge = TextStyle(
        fontSize = 17.sp,
        fontWeight = FontWeight.SemiBold,
        lineHeight = 22.sp
    ),
    bodyLarge = TextStyle(
        fontSize = 17.sp,
        fontWeight = FontWeight.Normal,
        lineHeight = 22.sp
    ),
    labelSmall = TextStyle(
        fontSize = 12.sp,
        fontWeight = FontWeight.Normal,
        lineHeight = 16.sp
    )
)
```

**android/app/.../ui/theme/Spacing.kt:**
```kotlin
package com.example.myapp.ui.theme

import androidx.compose.ui.unit.dp

object Spacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
    val xxl = 48.dp
}

object Radius {
    val sm = 4.dp
    val md = 8.dp
    val lg = 12.dp
    val xl = 16.dp
    val full = 9999.dp
}
```

## Figma Integration

When using `--from-figma` option:

1. Call Figma MCP's `get_variable_defs` tool
2. Extract colors and typography from variable definitions
3. Generate `shared/design-tokens.yaml`
4. Generate iOS/Android code

```
/twophone design-system --from-figma https://figma.com/design/abc123/MyDesign
```
