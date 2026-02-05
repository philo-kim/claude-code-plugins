---
description: Asset management (image, icon synchronization)
argument-hint: [--icons | --images | --app-icon | --all]
---

# TwoPhone Asset Management

Convert and synchronize images and icons for iOS and Android.

## Asset Source Directory

```
shared/
├── assets/
│   ├── images/           # General images
│   │   ├── logo.png      # Base resolution (3x or xxhdpi)
│   │   ├── banner.png
│   │   └── placeholder.png
│   ├── icons/            # Icons
│   │   ├── home.svg      # SVG recommended
│   │   ├── profile.svg
│   │   └── settings.svg
│   └── app-icon/         # App icon
│       └── icon.png      # 1024x1024 original
```

## Commands

### Sync all
```
/twophone assets --all
```

### Images only
```
/twophone assets --images
```

### Icons only
```
/twophone assets --icons
```

### App icon
```
/twophone assets --app-icon
```

## Image Processing

### Input
- `shared/assets/images/logo.png` (3x base, e.g., 300x300)

### iOS Output
```
ios/MyApp/Resources/Assets.xcassets/Images/logo.imageset/
├── Contents.json
├── logo@1x.png    (100x100)
├── logo@2x.png    (200x200)
└── logo@3x.png    (300x300)
```

**Contents.json:**
```json
{
  "images": [
    { "filename": "logo@1x.png", "idiom": "universal", "scale": "1x" },
    { "filename": "logo@2x.png", "idiom": "universal", "scale": "2x" },
    { "filename": "logo@3x.png", "idiom": "universal", "scale": "3x" }
  ],
  "info": { "version": 1, "author": "twophone" }
}
```

### Android Output
```
android/app/src/main/res/
├── drawable-mdpi/logo.png      (100x100)
├── drawable-hdpi/logo.png      (150x150)
├── drawable-xhdpi/logo.png     (200x200)
├── drawable-xxhdpi/logo.png    (300x300)
└── drawable-xxxhdpi/logo.png   (400x400)
```

## Icon Processing

### SVG Recommended
When using SVG files:
- iOS: PDF or SVG (Xcode 12+)
- Android: Vector Drawable (XML)

### iOS Output
```
ios/MyApp/Resources/Assets.xcassets/Icons/home.imageset/
├── Contents.json
└── home.pdf
```

### Android Output
**android/app/src/main/res/drawable/ic_home.xml:**
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#000000"
        android:pathData="M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z"/>
</vector>
```

## App Icon Generation

### Input
- `shared/assets/app-icon/icon.png` (1024x1024)

### iOS Output
```
ios/MyApp/Resources/Assets.xcassets/AppIcon.appiconset/
├── Contents.json
├── icon-20@2x.png      (40x40)
├── icon-20@3x.png      (60x60)
├── icon-29@2x.png      (58x58)
├── icon-29@3x.png      (87x87)
├── icon-40@2x.png      (80x80)
├── icon-40@3x.png      (120x120)
├── icon-60@2x.png      (120x120)
├── icon-60@3x.png      (180x180)
└── icon-1024.png       (1024x1024)
```

### Android Output
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png         (48x48)
├── mipmap-hdpi/ic_launcher.png         (72x72)
├── mipmap-xhdpi/ic_launcher.png        (96x96)
├── mipmap-xxhdpi/ic_launcher.png       (144x144)
├── mipmap-xxxhdpi/ic_launcher.png      (192x192)
└── mipmap-anydpi-v26/
    └── ic_launcher.xml                  (Adaptive icon)
```

## SF Symbols ↔ Material Icons Mapping

Icon name mapping table:

| Meaning | SF Symbols | Material Icons |
|---------|------------|----------------|
| Home | `house.fill` | `home` |
| Search | `magnifyingglass` | `search` |
| Settings | `gearshape.fill` | `settings` |
| Profile | `person.fill` | `person` |
| Notifications | `bell.fill` | `notifications` |
| Favorite | `heart.fill` | `favorite` |
| Share | `square.and.arrow.up` | `share` |
| Add | `plus` | `add` |
| Close | `xmark` | `close` |
| Back | `chevron.left` | `arrow_back` |

### Usage Generation

**iOS:**
```swift
Image(systemName: "house.fill")
```

**Android:**
```kotlin
Icon(Icons.Filled.Home, contentDescription = "Home")
```

## Final Report

```
✅ Asset sync complete

Images:
  - logo.png → iOS 3 sizes, Android 5 sizes generated
  - banner.png → iOS 3 sizes, Android 5 sizes generated

Icons:
  - home.svg → iOS PDF, Android Vector Drawable
  - profile.svg → iOS PDF, Android Vector Drawable

App icon:
  - iOS: 9 sizes generated
  - Android: 5 sizes + Adaptive icon

⚠️ Warnings:
  - placeholder.png resolution too low (1x only)
```
