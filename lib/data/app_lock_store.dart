import 'hive_manager.dart';
import 'native_bridge.dart';

class AppLockStore {
  /// Check if a specific app is locked
  static bool isLocked(String packageName) {
    return HiveManager.lockedAppsBox.get(packageName) ?? false;
  }

  /// Toggle lock state for a specific app and sync to native service
  static Future<void> setLocked(String packageName, bool locked) async {
    await HiveManager.lockedAppsBox.put(packageName, locked);
    await _syncToNative();
  }

  /// Get all locked package names
  static List<String> getLockedPackageNames() {
    final box = HiveManager.lockedAppsBox;
    return box.keys
        .cast<String>()
        .where((key) => box.get(key) == true)
        .toList();
  }

  /// Push the current locked list to the native Kotlin LockService
  static Future<void> _syncToNative() async {
    final locked = getLockedPackageNames();
    await NativeBridge.syncLockedApps(locked);
  }

  /// Call this on app startup to make sure native side is in sync
  static Future<void> syncOnStartup() async {
    await _syncToNative();
  }
}
