import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data for UI presentation
  final List<String> _profiles = ["Admin", "Family", "Guest"];
  String _activeProfile = "Admin";
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(loc.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Color(0xFF00FFCC)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildProfileSelector(loc),
          Expanded(
            child: _buildAppList(loc),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.black45,
        border: Border(bottom: BorderSide(color: Color(0xFF00FFCC), width: 2))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.profiles.toUpperCase(), style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _profiles.map((p) => _buildProfileTab(p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(String name) {
    final isActive = name == _activeProfile;
    return GestureDetector(
      onTap: () => setState(() => _activeProfile = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00FFCC) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          name, 
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }

  Widget _buildAppList(AppLocalizations loc) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        bool isLocked = index % 3 == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black26, 
              child: Icon(Icons.android, color: Color(0xFF00FFCC))
            ),
            title: Text("App \$index", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("com.example.app\$index", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Switch(
              value: isLocked,
              activeThumbColor: const Color(0xFF00FFCC),
              onChanged: (val) {},
            ),
          ),
        );
      },
    );
  }
}
