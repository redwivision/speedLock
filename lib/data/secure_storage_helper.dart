import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyHiveEncryption = 'hive_encryption_key';
  static const _keyActiveProfile = 'active_profile_id';

  static Future<List<int>> getHiveEncryptionKey() async {
    String? keyString = await _storage.read(key: _keyHiveEncryption);
    if (keyString == null) {
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyHiveEncryption, value: base64UrlEncode(key));
      return key;
    }
    return base64Url.decode(keyString);
  }

  static Future<String?> getActiveProfileId() async {
    return await _storage.read(key: _keyActiveProfile);
  }

  static Future<void> setActiveProfileId(String id) async {
    await _storage.write(key: _keyActiveProfile, value: id);
  }
}
