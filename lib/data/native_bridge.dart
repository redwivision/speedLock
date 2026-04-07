import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('com.redwivision.speedlock/service');

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      // Service may not be available on non-Android platforms
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }

  static Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod('checkUsageStatsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (_) {}
  }

  static Future<void> syncLockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('setLockedApps', {'apps': packageNames});
    } catch (_) {}
  }

  static Future<void> unlockApp(String packageName) async {
    try {
      await _channel.invokeMethod('unlockApp', {'package': packageName});
    } catch (_) {}
  }

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }
}
