# SpeedLock

A zero-cost, lightweight, and highly optimized Android app locker designed heavily around multi-profile support. It features instant sub-100ms locking speeds via `UsageStatsManager` tracking without relying on slow or battery-draining Accessibility services.

## Core Features
*   **Multi-Profile Encrypted DB**: Built on top of **Hive** with 256-bit AES encryption tightly coupled with `flutter_secure_storage`. Supports secure transitions between distinct profiles.
*   **Event-Driven Instant Detection**: Replaces constant intensive polling loops with a native Kotlin foreground service (`LockService`). Augments `UsageStatsManager` with `BroadcastReceiver` triggers (Screen On/Off and Boot checks) to drastically cut down battery drain while guaranteeing <100ms lock response speeds. 
*   **Battery and Doze Safeties**: Employs `WorkManager` for routine health checks and `BootReceiver` hooks, ensuring the service maintains priority across Android reboots. Built specifically to survive Android 12+ FGS constraints using the `specialUse` permission type.
*   **Localization Support**: Ships with robust fallback systems via `intl gen-l10n`, actively including native **Amharic (am)** dictionary configurations.
*   **Cyberpunk Interface**: Comes bundled with a futuristic fast-responding Cyberpunk locking UI (`LockScreen`) that prioritizes performance and immediate UX feedback.

## Technology Stack
- **Framework**: Flutter ^3.11.0
- **Language**: Dart / Android Native Kotlin
- **Database**: Hive (`hive_flutter`)
- **Key Storage**: `flutter_secure_storage`
- **Background Execution**: `workmanager`
- **Permissions**: `permission_handler`, `device_info_plus`

## Requirements
*   **Operating System**: Android 6.0+ (`minSdk` 24)

## Getting Started

Follow these simple steps to run the app on your Android emulator or physical device!

### 1. Build and Run the App
1. Connect your Android device or start your Emulator.
2. Open your terminal in the project folder and run:
   ```bash
   flutter run
   ```
3. This will compile the application and install it onto your device.

### 2. Grant Essential Android Permissions
Since SpeedLock relies on detecting other running apps safely, you must grant it two special Android permissions manually. Once the app is installed:

- **Enable Usage Access**: 
  - Go to your Android phone's **Settings**.
  - Search for **"Usage Access"**.
  - Find **SpeedLock** in the list and toggle it **ON**.
  *(This allows our background engine to detect when another app is launched in <100ms).*

- **Enable Display Over Other Apps**: 
  - Search for **"Display over other apps"** or **"Draw over other apps"** in your phone's Settings.
  - Find **SpeedLock** and toggle it **ON**.
  *(This allows SpeedLock to draw the locking screen seamlessly over the apps you want to protect).*

### 3. Setup Your Profiles
- Open SpeedLock.
- Use the **Dashboard** to switch between your profiles (Admin, Family, Guest).
- Flip the switch next to any app you want to lock, and the Native Service will immediately begin protecting it!
