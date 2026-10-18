# 06. Developer Guides — Development Setup & Environment

This guide walks through configuring a local development environment to build and run Inka.

---

## 📋 Prerequisites

- **Flutter SDK**: `>= 3.11.4` (Channel stable)
- **Dart SDK**: `>= 3.0.0 < 4.0.0`
- **Xcode**: 15+ (for iOS and macOS development)
- **Android Studio / Command Line Tools**: SDK 34, JDK 17
- **CocoaPods**: `gem install cocoapods`

---

## 🚀 Initial Workspace Setup

1. **Clone the repository**:
   ```bash
   git clone <repo-url> inka
   cd inka
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Hive TypeAdapters**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Verify Firebase Setup**:
   Ensure `google-services.json` is present in `android/app/` and `GoogleService-Info.plist` is present in `ios/Runner/`.

---

## 📱 Running on Devices

### macOS Desktop:
```bash
flutter run -d macos
```

### iOS Simulator / Device:
```bash
cd ios && pod install && cd ..
flutter run -d ios
```

### Android Emulator / Device:
```bash
flutter run -d android
```

### Web:
```bash
flutter run -d chrome
```

---

## ⚠️ Common Gotchas

1. **Hive Adapter Conflicts**:
   If you ever encounter `There is already a TypeAdapter for typeId ...`, ensure your adapter registration in `lib/main.dart` is wrapped with `if (!Hive.isAdapterRegistered(N))`.
2. **Missing Pods**:
   Run `cd ios && pod update && pod install && cd ..` if iOS builds report missing symbols for Google Sign-In or Firebase.
