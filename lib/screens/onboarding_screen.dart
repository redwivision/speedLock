import 'package:flutter/material.dart';
import '../data/native_bridge.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasPermission = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await NativeBridge.hasUsageStatsPermission();
    if (mounted) setState(() { _hasPermission = has; _checking = false; });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ──
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.08);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FFCC), Color(0xFF00B4D8)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00FFCC).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded, size: 56, color: Color(0xFF0D0D0D)),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Title ──
                const Text("SpeedLock",
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text("Lock apps instantly. Your device, your rules.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.5),
                ),
                const Spacer(),

                // ── Permission Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _hasPermission ? Icons.check_circle_rounded : Icons.shield_rounded,
                        color: _hasPermission ? const Color(0xFF00FFCC) : Colors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hasPermission ? "Permission Granted!" : "Usage Access Required",
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _hasPermission
                          ? "SpeedLock can now detect and lock apps."
                          : "SpeedLock needs to see which app is open to protect it.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      ),
                      if (!_hasPermission) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              await NativeBridge.requestUsageStatsPermission();
                              // Re-check after user returns
                              await Future.delayed(const Duration(seconds: 2));
                              _checkPermission();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Continue Button ──
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _hasPermission ? widget.onComplete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFCC),
                      foregroundColor: const Color(0xFF0D0D0D),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
