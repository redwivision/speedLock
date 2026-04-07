import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/app_lock_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<_AppInfo> _apps = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      const channel = MethodChannel('com.redwivision.speedlock/service');
      final List<dynamic>? raw = await channel.invokeMethod('getInstalledApps');
      if (raw != null && mounted) {
        setState(() {
          _apps = raw.map((a) => _AppInfo(
            packageName: a['packageName']?.toString() ?? '',
            appName: a['appName']?.toString() ?? '',
          )).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback for emulator / non-android
    if (mounted) {
      setState(() {
        _apps = [
          _AppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp'),
          _AppInfo(packageName: 'com.instagram.android', appName: 'Instagram'),
          _AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook'),
          _AppInfo(packageName: 'com.google.android.youtube', appName: 'YouTube'),
          _AppInfo(packageName: 'com.twitter.android', appName: 'X (Twitter)'),
          _AppInfo(packageName: 'org.telegram.messenger', appName: 'Telegram'),
          _AppInfo(packageName: 'com.snapchat.android', appName: 'Snapchat'),
          _AppInfo(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
          _AppInfo(packageName: 'com.google.android.gm', appName: 'Gmail'),
          _AppInfo(packageName: 'com.android.chrome', appName: 'Chrome'),
        ];
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String pkg, bool lock) async {
    await AppLockStore.setLocked(pkg, lock);
    setState(() {}); // Rebuild just this widget
  }

  List<_AppInfo> get _filtered {
    if (_search.isEmpty) return _apps;
    final q = _search.toLowerCase();
    return _apps.where((a) => a.appName.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q)).toList();
  }

  int get _lockedCount => _apps.where((a) => AppLockStore.isLocked(a.packageName)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)))
        : CustomScrollView(slivers: [

          // ── Header ──
          SliverAppBar(
            expandedHeight: 120, floating: false, pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text("SpeedLock",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [const Color(0xFF00FFCC).withValues(alpha: 0.12), const Color(0xFF0D0D0D)],
                  ),
                ),
              ),
            ),
          ),

          // ── Status Card ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF00FFCC).withValues(alpha: 0.10),
                  const Color(0xFF00B4D8).withValues(alpha: 0.06),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FFCC).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00FFCC)),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF0D0D0D), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Protection Active",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text("$_lockedCount app${_lockedCount == 1 ? '' : 's'} locked",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFCC).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("$_lockedCount",
                    style: const TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ]),
            ),
          )),

          // ── Search Bar ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search apps...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3)),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )),

          // ── Apps Label ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text("INSTALLED APPS",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          )),

          // ── App List ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final app = _filtered[index];
                final locked = AppLockStore.isLocked(app.packageName);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: locked
                        ? const Color(0xFF00FFCC).withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: locked
                          ? const Color(0xFF00FFCC).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: locked
                            ? const Color(0xFF00FFCC).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Icon(
                          locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: locked ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.35),
                          size: 20),
                      ),
                      title: Text(app.appName,
                        style: TextStyle(
                          color: locked ? Colors.white : Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(app.packageName,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                      trailing: Switch.adaptive(
                        value: locked,
                        activeTrackColor: const Color(0xFF00FFCC).withValues(alpha: 0.35),
                        activeColor: const Color(0xFF00FFCC),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        onChanged: (val) => _toggle(app.packageName, val),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ]),
    );
  }
}

class _AppInfo {
  final String packageName;
  final String appName;
  _AppInfo({required this.packageName, required this.appName});
}
