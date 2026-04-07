import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'data/hive_manager.dart';
import 'data/profile_repository.dart';
import 'data/native_bridge.dart';
import 'background/work_manager_helper.dart';
import 'screens/onboarding_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveManager.init();
  await ProfileRepository.init(HiveManager.profilesBox, HiveManager.appsBox);
  await WorkManagerHelper.init();

  // Start the native lock service
  await NativeBridge.startService();

  // Sync locked apps for the active profile on startup
  final activeId = await ProfileRepository.getActiveProfileId();
  if (activeId != null) {
    final locked = ProfileRepository.getLockedPackageNames(activeId);
    await NativeBridge.syncLockedApps(locked);
  }

  runApp(const SpeedLockApp());
}

class SpeedLockApp extends StatelessWidget {
  const SpeedLockApp({super.key});

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
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  String _screen = 'loading';

  @override
  void initState() {
    super.initState();
    _determineScreen();
  }

  Future<void> _determineScreen() async {
    final profiles = ProfileRepository.getAllProfiles();
    if (profiles.isEmpty) {
      setState(() => _screen = 'onboarding');
    } else {
      setState(() => _screen = 'dashboard');
    }
  }

  void _goTo(String screen) {
    setState(() => _screen = screen);
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case 'loading':
        return const Scaffold(
          backgroundColor: Color(0xFF0D0D0D),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC))),
        );
      case 'onboarding':
        return OnboardingScreen(onComplete: () => _goTo('create_profile'));
      case 'create_profile':
        return CreateProfileScreen(onProfileCreated: () => _goTo('dashboard'));
      case 'dashboard':
        return const DashboardScreen();
      default:
        return const DashboardScreen();
    }
  }
}
