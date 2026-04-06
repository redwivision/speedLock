import 'package:hive/hive.dart';

class AppConfigModel {
  final String packageName;
  final bool isLocked;
  final String profileId;

  AppConfigModel({
    required this.packageName,
    required this.isLocked,
    required this.profileId,
  });
}

class AppConfigModelAdapter extends TypeAdapter<AppConfigModel> {
  @override
  final int typeId = 1;

  @override
  AppConfigModel read(BinaryReader reader) {
    return AppConfigModel(
      packageName: reader.readString(),
      isLocked: reader.readBool(),
      profileId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, AppConfigModel obj) {
    writer.writeString(obj.packageName);
    writer.writeBool(obj.isLocked);
    writer.writeString(obj.profileId);
  }
}
