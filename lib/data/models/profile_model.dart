import 'package:hive/hive.dart';

class ProfileModel {
  final String id;
  final String name;
  final String pinCode;
  final bool biometricEnabled;

  ProfileModel({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.biometricEnabled,
  });
}

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  @override
  final int typeId = 0;

  @override
  ProfileModel read(BinaryReader reader) {
    return ProfileModel(
      id: reader.readString(),
      name: reader.readString(),
      pinCode: reader.readString(),
      biometricEnabled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.pinCode);
    writer.writeBool(obj.biometricEnabled);
  }
}
