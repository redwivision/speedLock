import 'package:hive_flutter/hive_flutter.dart';
import 'models/profile_model.dart';
import 'models/app_config_model.dart';
import 'secure_storage_helper.dart';

class ProfileRepository {
  static late Box<ProfileModel> _profilesBox;
  static late Box<AppConfigModel> _appsBox;

  static Future<void> init(Box<ProfileModel> profilesBox, Box<AppConfigModel> appsBox) async {
    _profilesBox = profilesBox;
    _appsBox = appsBox;
  }

  // ── Profiles ──
  static List<ProfileModel> getAllProfiles() {
    return _profilesBox.values.toList();
  }

  static ProfileModel? getProfile(String id) {
    try {
      return _profilesBox.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> addProfile(ProfileModel profile) async {
    await _profilesBox.put(profile.id, profile);
  }

  static Future<void> deleteProfile(String id) async {
    await _profilesBox.delete(id);
    // Also delete all app configs for this profile
    final keys = _appsBox.keys.where((k) => k.toString().startsWith(id)).toList();
    for (final key in keys) {
      await _appsBox.delete(key);
    }
  }

  static Future<String?> getActiveProfileId() async {
    return await SecureStorageHelper.getActiveProfileId();
  }

  static Future<void> setActiveProfileId(String id) async {
    await SecureStorageHelper.setActiveProfileId(id);
  }

  // ── App Configs ──
  static List<AppConfigModel> getLockedAppsForProfile(String profileId) {
    return _appsBox.values.where((a) => a.profileId == profileId && a.isLocked).toList();
  }

  static bool isAppLocked(String profileId, String packageName) {
    final key = '\${profileId}_\$packageName';
    final config = _appsBox.get(key);
    return config?.isLocked ?? false;
  }

  static Future<void> toggleAppLock(String profileId, String packageName, bool locked) async {
    final key = '\${profileId}_\$packageName';
    await _appsBox.put(key, AppConfigModel(
      packageName: packageName,
      isLocked: locked,
      profileId: profileId,
    ));
  }

  static List<String> getLockedPackageNames(String profileId) {
    return _appsBox.values
        .where((a) => a.profileId == profileId && a.isLocked)
        .map((a) => a.packageName)
        .toList();
  }
}
