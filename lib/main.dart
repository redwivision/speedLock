import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import 'data/hive_manager.dart';
import 'background/work_manager_helper.dart';
import 'screens/lock_screen.dart';

import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await HiveManager.init();
  await WorkManagerHelper.init();

  // Initialize MethodChannel to start Service
  const channel = MethodChannel('com.redwivision.speedlock/service');
  try {
    await channel.invokeMethod('startService');
  } catch (e) {
    debugPrint("Failed to start LockService: \$e");
  }

  runApp(const SpeedLockApp());
}

class SpeedLockApp extends StatelessWidget {
  const SpeedLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedLock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FFCC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      home: const DashboardScreen(),
    );
  }
}


