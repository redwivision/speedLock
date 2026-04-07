import 'package:hive_flutter/hive_flutter.dart';
import 'secure_storage_helper.dart';

class HiveManager {
  static late Box<bool> lockedAppsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    final encryptionKey = await SecureStorageHelper.getHiveEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    lockedAppsBox = await Hive.openBox<bool>('locked_apps', encryptionCipher: cipher);
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
