import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      const channel = MethodChannel('com.redwivision.speedlock/service');
      // Ensure native LockService is running as a fallback 
      await channel.invokeMethod('startService');
    } catch (e) {
      print("WorkManager error: \$e");
    }
    return Future.value(true);
  });
}

class WorkManagerHelper {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      "speedlock-periodic",
      "ensureServiceRunning",
      frequency: const Duration(minutes: 15),
    );
  }
}
