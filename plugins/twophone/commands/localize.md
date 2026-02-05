---
description: Localization/i18n synchronization
argument-hint: [strings.yaml | --add-key <key> | --add-language <code>]
---

# TwoPhone Localization

Generate iOS/Android localization files simultaneously from a single source file.

## Source File

**shared/strings.yaml:**
```yaml
# Default language (fallback)
_default: en

# Supported languages
_languages:
  - en
  - ko
  - ja

# String definitions
common:
  app_name:
    en: "MyApp"
    ko: "마이앱"
    ja: "マイアプリ"
  ok:
    en: "OK"
    ko: "확인"
    ja: "OK"
  cancel:
    en: "Cancel"
    ko: "취소"
    ja: "キャンセル"
  error:
    en: "Error"
    ko: "오류"
    ja: "エラー"

auth:
  login:
    title:
      en: "Login"
      ko: "로그인"
      ja: "ログイン"
    email_placeholder:
      en: "Email"
      ko: "이메일"
      ja: "メールアドレス"
    password_placeholder:
      en: "Password"
      ko: "비밀번호"
      ja: "パスワード"
    button:
      en: "Sign In"
      ko: "로그인"
      ja: "サインイン"
    forgot_password:
      en: "Forgot Password?"
      ko: "비밀번호를 잊으셨나요?"
      ja: "パスワードをお忘れですか？"

  register:
    title:
      en: "Create Account"
      ko: "회원가입"
      ja: "アカウント作成"

home:
  welcome:
    en: "Welcome, %@!"          # %@ = placeholder
    ko: "%@님, 환영합니다!"
    ja: "ようこそ、%@さん！"
  items_count:
    en: "%d items"              # %d = number
    ko: "%d개 항목"
    ja: "%d件"

errors:
  network:
    en: "Network error. Please try again."
    ko: "네트워크 오류입니다. 다시 시도해주세요."
    ja: "ネットワークエラーです。もう一度お試しください。"
  invalid_email:
    en: "Please enter a valid email."
    ko: "올바른 이메일을 입력해주세요."
    ja: "有効なメールアドレスを入力してください。"
```

## iOS Output

**ios/MyApp/Resources/en.lproj/Localizable.strings:**
```
/* Common */
"common.app_name" = "MyApp";
"common.ok" = "OK";
"common.cancel" = "Cancel";
"common.error" = "Error";

/* Auth - Login */
"auth.login.title" = "Login";
"auth.login.email_placeholder" = "Email";
"auth.login.password_placeholder" = "Password";
"auth.login.button" = "Sign In";
"auth.login.forgot_password" = "Forgot Password?";

/* Auth - Register */
"auth.register.title" = "Create Account";

/* Home */
"home.welcome" = "Welcome, %@!";
"home.items_count" = "%d items";

/* Errors */
"errors.network" = "Network error. Please try again.";
"errors.invalid_email" = "Please enter a valid email.";
```

**ios/MyApp/Resources/ko.lproj/Localizable.strings:**
```
/* Common */
"common.app_name" = "마이앱";
"common.ok" = "확인";
"common.cancel" = "취소";
"common.error" = "오류";

/* Auth - Login */
"auth.login.title" = "로그인";
"auth.login.email_placeholder" = "이메일";
"auth.login.password_placeholder" = "비밀번호";
"auth.login.button" = "로그인";
"auth.login.forgot_password" = "비밀번호를 잊으셨나요?";

/* Auth - Register */
"auth.register.title" = "회원가입";

/* Home */
"home.welcome" = "%@님, 환영합니다!";
"home.items_count" = "%d개 항목";

/* Errors */
"errors.network" = "네트워크 오류입니다. 다시 시도해주세요.";
"errors.invalid_email" = "올바른 이메일을 입력해주세요.";
```

**ios/MyApp/Resources/Strings.swift (Type-safe access):**
```swift
import Foundation

enum L10n {
    enum Common {
        static let appName = NSLocalizedString("common.app_name", comment: "")
        static let ok = NSLocalizedString("common.ok", comment: "")
        static let cancel = NSLocalizedString("common.cancel", comment: "")
        static let error = NSLocalizedString("common.error", comment: "")
    }

    enum Auth {
        enum Login {
            static let title = NSLocalizedString("auth.login.title", comment: "")
            static let emailPlaceholder = NSLocalizedString("auth.login.email_placeholder", comment: "")
            static let passwordPlaceholder = NSLocalizedString("auth.login.password_placeholder", comment: "")
            static let button = NSLocalizedString("auth.login.button", comment: "")
            static let forgotPassword = NSLocalizedString("auth.login.forgot_password", comment: "")
        }
        enum Register {
            static let title = NSLocalizedString("auth.register.title", comment: "")
        }
    }

    enum Home {
        static func welcome(_ name: String) -> String {
            String(format: NSLocalizedString("home.welcome", comment: ""), name)
        }
        static func itemsCount(_ count: Int) -> String {
            String(format: NSLocalizedString("home.items_count", comment: ""), count)
        }
    }

    enum Errors {
        static let network = NSLocalizedString("errors.network", comment: "")
        static let invalidEmail = NSLocalizedString("errors.invalid_email", comment: "")
    }
}
```

## Android Output

**android/app/src/main/res/values/strings.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Common -->
    <string name="common_app_name">MyApp</string>
    <string name="common_ok">OK</string>
    <string name="common_cancel">Cancel</string>
    <string name="common_error">Error</string>

    <!-- Auth - Login -->
    <string name="auth_login_title">Login</string>
    <string name="auth_login_email_placeholder">Email</string>
    <string name="auth_login_password_placeholder">Password</string>
    <string name="auth_login_button">Sign In</string>
    <string name="auth_login_forgot_password">Forgot Password?</string>

    <!-- Auth - Register -->
    <string name="auth_register_title">Create Account</string>

    <!-- Home -->
    <string name="home_welcome">Welcome, %1$s!</string>
    <string name="home_items_count">%1$d items</string>

    <!-- Errors -->
    <string name="errors_network">Network error. Please try again.</string>
    <string name="errors_invalid_email">Please enter a valid email.</string>
</resources>
```

**android/app/src/main/res/values-ko/strings.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="common_app_name">마이앱</string>
    <string name="common_ok">확인</string>
    <string name="common_cancel">취소</string>
    <string name="common_error">오류</string>

    <string name="auth_login_title">로그인</string>
    <string name="auth_login_email_placeholder">이메일</string>
    <string name="auth_login_password_placeholder">비밀번호</string>
    <string name="auth_login_button">로그인</string>
    <string name="auth_login_forgot_password">비밀번호를 잊으셨나요?</string>

    <string name="auth_register_title">회원가입</string>

    <string name="home_welcome">%1$s님, 환영합니다!</string>
    <string name="home_items_count">%1$d개 항목</string>

    <string name="errors_network">네트워크 오류입니다. 다시 시도해주세요.</string>
    <string name="errors_invalid_email">올바른 이메일을 입력해주세요.</string>
</resources>
```

## Additional Commands

### Add new key
```
/twophone localize --add-key "settings.notifications.title"
```
→ Adds key to strings.yaml + requests translation

### Add new language
```
/twophone localize --add-language zh
```
→ Adds Chinese language support

## Validation

Detect missing translations:
```
⚠️ Missing translations found:

auth.login.forgot_password:
  - ja: (missing)

settings.theme:
  - ko: (missing)
  - ja: (missing)
```
