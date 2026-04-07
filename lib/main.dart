import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'data/hive_manager.dart';
import 'data/app_lock_store.dart';
import 'data/native_bridge.dart';
import 'data/secure_storage_helper.dart';
import 'background/work_manager_helper.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveManager.init();
  await WorkManagerHelper.init();
  await NativeBridge.startService();
  await AppLockStore.syncOnStartup();

  final setupDone = await SecureStorageHelper.isSetupComplete();

  runApp(SpeedLockApp(setupDone: setupDone));
}

class SpeedLockApp extends StatelessWidget {
  final bool setupDone;
  const SpeedLockApp({super.key, this.setupDone = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FFCC),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        useMaterial3: true,
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('am')],
      home: _AppRouter(setupDone: setupDone),
    );
  }
}

class _AppRouter extends StatefulWidget {
  final bool setupDone;
  const _AppRouter({required this.setupDone});

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late bool _showDashboard;

  @override
  void initState() {
    super.initState();
    _showDashboard = widget.setupDone;

    NativeBridge.setMethodCallHandler((call) async {
      if (call.method == 'showLockScreen') {
        final String pkg = call.arguments as String;
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LockScreen(lockedApp: pkg),
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showDashboard) {
      return const DashboardScreen();
    }
    return OnboardingScreen(
      onComplete: () => setState(() => _showDashboard = true),
    );
  }
}
