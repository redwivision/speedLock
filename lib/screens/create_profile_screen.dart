import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/profile_repository.dart';
import '../data/models/profile_model.dart';

class CreateProfileScreen extends StatefulWidget {
  final VoidCallback onProfileCreated;
  const CreateProfileScreen({super.key, required this.onProfileCreated});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _error;

  final List<IconData> _avatarIcons = [
    Icons.person_rounded, Icons.face_rounded, Icons.child_care_rounded,
    Icons.school_rounded, Icons.work_rounded, Icons.star_rounded,
  ];
  int _selectedAvatar = 0;

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = "Give this profile a name");
      return;
    }
    if (pin.length < 4) {
      setState(() => _error = "PIN must be at least 4 digits");
      return;
    }
    if (pin != confirmPin) {
      setState(() => _error = "PINs don't match");
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await ProfileRepository.addProfile(ProfileModel(
      id: id,
      name: name,
      pinCode: pin,
      biometricEnabled: false,
    ));
    await ProfileRepository.setActiveProfileId(id);
    widget.onProfileCreated();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text("Create Profile",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text("Each person gets their own locked apps & PIN.",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
                const SizedBox(height: 36),

                // ── Avatar Picker ──
                Center(
                  child: Wrap(
                    spacing: 12, runSpacing: 12,
                    children: List.generate(_avatarIcons.length, (i) {
                      final isSelected = i == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.15),
                              width: 2,
                            ),
                          ),
                          child: Icon(_avatarIcons[i],
                            color: isSelected ? const Color(0xFF0D0D0D) : Colors.white.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Name Field ──
                _buildLabel("PROFILE NAME"),
                const SizedBox(height: 8),
                _buildTextField(_nameController, "e.g. Admin, Mom, Guest", false),
                const SizedBox(height: 24),

                // ── PIN Field ──
                _buildLabel("SET PIN"),
                const SizedBox(height: 8),
                _buildTextField(_pinController, "At least 4 digits", true),
                const SizedBox(height: 24),

                // ── Confirm PIN ──
                _buildLabel("CONFIRM PIN"),
                const SizedBox(height: 8),
                _buildTextField(_confirmPinController, "Re-enter your PIN", true),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Flexible(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 36),

                // ── Create Button ──
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFCC),
                      foregroundColor: const Color(0xFF0D0D0D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Create Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPin) {
    return TextField(
      controller: controller,
      obscureText: isPin,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      inputFormatters: isPin ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00FFCC), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
