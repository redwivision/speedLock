import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/profile_repository.dart';
import '../data/models/profile_model.dart';
import '../data/native_bridge.dart';
import '../l10n/app_localizations.dart';
import 'create_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ProfileModel> _profiles = [];
  String? _activeProfileId;
  List<Map<String, String>> _installedApps = [];
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadInstalledApps();
  }

  Future<void> _loadProfiles() async {
    final profiles = ProfileRepository.getAllProfiles();
    final activeId = await ProfileRepository.getActiveProfileId();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _activeProfileId = activeId ?? (profiles.isNotEmpty ? profiles.first.id : null);
      });
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      const channel = MethodChannel('com.redwivision.speedlock/service');
      final List<dynamic>? apps = await channel.invokeMethod('getInstalledApps');
      if (apps != null && mounted) {
        setState(() {
          _installedApps = apps.map((a) => {
            'packageName': a['packageName']?.toString() ?? '',
            'appName': a['appName']?.toString() ?? a['packageName']?.toString() ?? '',
          }).toList();
          _loadingApps = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback: show some common apps so the UI isn't empty
    if (mounted) {
      setState(() {
        _installedApps = [
          {'packageName': 'com.whatsapp', 'appName': 'WhatsApp'},
          {'packageName': 'com.instagram.android', 'appName': 'Instagram'},
          {'packageName': 'com.facebook.katana', 'appName': 'Facebook'},
          {'packageName': 'com.google.android.youtube', 'appName': 'YouTube'},
          {'packageName': 'com.twitter.android', 'appName': 'X (Twitter)'},
          {'packageName': 'org.telegram.messenger', 'appName': 'Telegram'},
          {'packageName': 'com.snapchat.android', 'appName': 'Snapchat'},
          {'packageName': 'com.zhiliaoapp.musically', 'appName': 'TikTok'},
          {'packageName': 'com.google.android.gm', 'appName': 'Gmail'},
          {'packageName': 'com.android.chrome', 'appName': 'Chrome'},
        ];
        _loadingApps = false;
      });
    }
  }

  Future<void> _toggleLock(String packageName, bool lock) async {
    if (_activeProfileId == null) return;
    await ProfileRepository.toggleAppLock(_activeProfileId!, packageName, lock);
    final locked = ProfileRepository.getLockedPackageNames(_activeProfileId!);
    await NativeBridge.syncLockedApps(locked);
    setState(() {});
  }

  Future<void> _switchProfile(String id) async {
    await ProfileRepository.setActiveProfileId(id);
    final locked = ProfileRepository.getLockedPackageNames(id);
    await NativeBridge.syncLockedApps(locked);
    setState(() => _activeProfileId = id);
  }

  void _addProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateProfileScreen(onProfileCreated: () {
        Navigator.of(context).pop();
        _loadProfiles();
      }),
    ));
  }

  ProfileModel? get _activeProfile {
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(loc?.appTitle ?? 'SpeedLock',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF00FFCC).withValues(alpha: 0.15), const Color(0xFF0D0D0D)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Color(0xFF00FFCC), size: 20),
                ),
                onPressed: _addProfile,
              ),
              const SizedBox(width: 12),
            ],
          ),

          // ── Profile Chips ──
          SliverToBoxAdapter(
            child: _profiles.isEmpty
              ? const SizedBox()
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((loc?.profiles ?? 'PROFILES').toUpperCase(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _profiles.map((p) {
                            final isActive = p.id == _activeProfileId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () => _switchProfile(p.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isActive ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_rounded, size: 16,
                                        color: isActive ? const Color(0xFF0D0D0D) : Colors.white.withValues(alpha: 0.5)),
                                      const SizedBox(width: 6),
                                      Text(p.name,
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF0D0D0D) : Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600, fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
          ),

          // ── Status Bar ──
          SliverToBoxAdapter(
            child: _activeProfile == null ? const SizedBox() : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF00FFCC).withValues(alpha: 0.12),
                    const Color(0xFF00B4D8).withValues(alpha: 0.08),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FFCC).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00FFCC),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF0D0D0D), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Active: \${_activeProfile!.name}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text("\${ProfileRepository.getLockedPackageNames(_activeProfileId!).length} apps locked",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  )),
                ]),
              ),
            ),
          ),

          // ── Section Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text((loc?.apps ?? 'APPS').toUpperCase(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
              ),
            ),
          ),

          // ── App List ──
          if (_loadingApps)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: _installedApps.length,
                itemBuilder: (context, index) {
                  final app = _installedApps[index];
                  final pkg = app['packageName']!;
                  final name = app['appName']!;
                  final isLocked = _activeProfileId != null && ProfileRepository.isAppLocked(_activeProfileId!, pkg);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLocked
                          ? const Color(0xFF00FFCC).withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLocked
                            ? const Color(0xFF00FFCC).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isLocked
                              ? const Color(0xFF00FFCC).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                          ),
                          child: Icon(
                            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: isLocked ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.4),
                            size: 22,
                          ),
                        ),
                        title: Text(name,
                          style: TextStyle(
                            color: isLocked ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(pkg,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Switch.adaptive(
                          value: isLocked,
                          activeTrackColor: const Color(0xFF00FFCC).withValues(alpha: 0.4),
                          activeColor: const Color(0xFF00FFCC),
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                          onChanged: (val) => _toggleLock(pkg, val),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
