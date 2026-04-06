import 'package:hive_flutter/hive_flutter.dart';
import 'secure_storage_helper.dart';
import 'models/profile_model.dart';
import 'models/app_config_model.dart';

class HiveManager {
  static late Box<ProfileModel> profilesBox;
  static late Box<AppConfigModel> appsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ProfileModelAdapter());
    Hive.registerAdapter(AppConfigModelAdapter());

    final encryptionKey = await SecureStorageHelper.getHiveEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    profilesBox = await Hive.openBox<ProfileModel>('profiles', encryptionCipher: cipher);
    appsBox = await Hive.openBox<AppConfigModel>('app_configs', encryptionCipher: cipher);
  }
  
  static Future<void> close() async {
    await Hive.close();
  }
}
