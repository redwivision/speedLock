import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/native_bridge.dart';
import '../data/secure_storage_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _step = 0; // 0 = welcome, 1 = permission, 2 = set pin
  bool _hasPermission = false;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await NativeBridge.hasUsageStatsPermission();
    if (mounted) setState(() => _hasPermission = has);
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    if (pin.length < 4) {
      setState(() => _pinError = "PIN must be at least 4 digits");
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = "PINs don't match");
      return;
    }
    await SecureStorageHelper.setUserPin(pin);
    await SecureStorageHelper.markSetupComplete();
    widget.onComplete();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _step == 0 ? _welcomeStep()
                 : _step == 1 ? _permissionStep()
                 : _pinStep(),
          ),
        ),
      ),
    );
  }

  // ── Step 0: Welcome ──
  Widget _welcomeStep() {
    return Column(children: [
      const Spacer(flex: 2),
      AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.08), child: child,
        ),
        child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF00FFCC), Color(0xFF00B4D8)]),
            boxShadow: [BoxShadow(color: const Color(0xFF00FFCC).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.lock_rounded, size: 56, color: Color(0xFF0D0D0D)),
        ),
      ),
      const SizedBox(height: 32),
      const Text("SpeedLock", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 3)),
      const SizedBox(height: 12),
      Text("Lock any app instantly.\nYour phone, your rules.", textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, height: 1.6),
      ),
      const Spacer(),
      _bigButton("Let's Go", () => setState(() => _step = 1)),
      const Spacer(),
    ]);
  }

  // ── Step 1: Permission ──
  Widget _permissionStep() {
    return Column(children: [
      const Spacer(flex: 2),
      Icon(_hasPermission ? Icons.check_circle_rounded : Icons.shield_rounded,
        color: _hasPermission ? const Color(0xFF00FFCC) : Colors.amber, size: 72),
      const SizedBox(height: 24),
      Text(_hasPermission ? "Permission Granted!" : "One Quick Step",
        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
        _hasPermission
          ? "SpeedLock can now detect which app you open."
          : "SpeedLock needs Usage Access to detect which app is on top and lock it instantly.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
      ),
      const Spacer(),
      if (!_hasPermission)
        _bigButton("Open Settings", () async {
          await NativeBridge.requestUsageStatsPermission();
          await Future.delayed(const Duration(seconds: 2));
          _checkPermission();
        }, color: Colors.amber),
      if (!_hasPermission) const SizedBox(height: 14),
      _bigButton(
        _hasPermission ? "Continue" : "I'll Do It Later",
        () => setState(() => _step = 2),
        color: _hasPermission ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.15),
        textColor: _hasPermission ? const Color(0xFF0D0D0D) : Colors.white.withValues(alpha: 0.5),
      ),
      const Spacer(),
    ]);
  }

  // ── Step 2: Set PIN ──
  Widget _pinStep() {
    return SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        const Text("Set Your PIN", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("This PIN will unlock all your protected apps.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        const SizedBox(height: 40),
        _label("ENTER PIN"),
        const SizedBox(height: 8),
        _pinField(_pinController, "At least 4 digits"),
        const SizedBox(height: 24),
        _label("CONFIRM PIN"),
        const SizedBox(height: 8),
        _pinField(_confirmPinController, "Re-enter your PIN"),
        if (_pinError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text(_pinError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
            ]),
          ),
        ],
        const SizedBox(height: 36),
        _bigButton("Start Protecting", _savePin),
      ],
    ));
  }

  // ── Helpers ──
  Widget _bigButton(String text, VoidCallback onTap, {Color? color, Color? textColor}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF00FFCC),
          foregroundColor: textColor ?? const Color(0xFF0D0D0D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5));

  Widget _pinField(TextEditingController c, String hint) => TextField(
    controller: c, obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14, letterSpacing: 1),
      filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00FFCC), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    ),
  );
}
