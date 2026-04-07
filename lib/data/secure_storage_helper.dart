import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyHiveEncryption = 'hive_encryption_key';
  static const _keyUserPin = 'user_pin';
  static const _keySetupComplete = 'setup_complete';

  static Future<List<int>> getHiveEncryptionKey() async {
    String? keyString = await _storage.read(key: _keyHiveEncryption);
    if (keyString == null) {
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyHiveEncryption, value: base64UrlEncode(key));
      return key;
    }
    return base64Url.decode(keyString);
  }

  static Future<String?> getUserPin() async {
    try {
      return await _storage.read(key: _keyUserPin);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setUserPin(String pin) async {
    await _storage.write(key: _keyUserPin, value: pin);
  }

  static Future<bool> isSetupComplete() async {
    try {
      final val = await _storage.read(key: _keySetupComplete);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSetupComplete() async {
    await _storage.write(key: _keySetupComplete, value: 'true');
  }
}
