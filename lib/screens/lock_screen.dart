import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/profile_repository.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _loading = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() { _loading = true; _error = null; });
    final activeId = await ProfileRepository.getActiveProfileId();
    if (activeId == null) {
      setState(() { _loading = false; _error = "No active profile"; });
      return;
    }

    final profile = ProfileRepository.getProfile(activeId);
    if (profile == null) {
      setState(() { _loading = false; _error = "Profile not found"; });
      return;
    }

    if (_pinController.text == profile.pinCode) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      setState(() { _loading = false; _error = "Wrong PIN"; _pinController.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Lock Icon ──
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FFCC).withValues(alpha: 0.4), width: 2),
                  ),
                  child: Icon(Icons.lock_rounded,
                    size: 42,
                    color: _error != null ? Colors.redAccent : const Color(0xFF00FFCC),
                  ),
                ),
                const SizedBox(height: 24),

                const Text("Locked",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text("Enter your PIN to continue",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                ),
                const SizedBox(height: 40),

                // ── PIN Input ──
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final offset = _shakeController.isAnimating
                      ? 10 * (0.5 - _shakeController.value) * (_shakeController.value < 0.5 ? 1 : -1)
                      : 0.0;
                    return Transform.translate(offset: Offset(offset, 0), child: child);
                  },
                  child: TextField(
                    controller: _pinController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, letterSpacing: 12, fontSize: 28, fontWeight: FontWeight.w300),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    obscureText: true,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    onSubmitted: (_) => _verifyPin(),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      hintText: '• • • •',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 8, fontSize: 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _error != null ? Colors.redAccent : const Color(0xFF00FFCC),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 28),

                // ── Unlock Button ──
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFCC),
                      foregroundColor: const Color(0xFF0D0D0D),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D0D0D)))
                      : const Text("UNLOCK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
