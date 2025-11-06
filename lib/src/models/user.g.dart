// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as int?,
      name: fields[1] as String,
      password: fields[2] as String?,
      host: fields[3] as String?,
      token: fields[4] as String?,
      lastUpdateTime: fields[5] as DateTime?,
      loggedIn: fields[6] as bool,
      group: fields[7] as String?,
      email: fields[8] as String?,
      recommenderUuid: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.host)
      ..writeByte(4)
      ..write(obj.token)
      ..writeByte(5)
      ..write(obj.lastUpdateTime)
      ..writeByte(6)
      ..write(obj.loggedIn)
      ..writeByte(7)
      ..write(obj.group)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.recommenderUuid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      password: json['password'] as String?,
      host: json['host'] as String?,
      token: json['token'] as String?,
      lastUpdateTime: json['lastUpdateTime'] == null
          ? null
          : DateTime.parse(json['lastUpdateTime'] as String),
      loggedIn: json['loggedIn'] as bool? ?? false,
      group: json['group'] as String?,
      email: json['email'] as String?,
      recommenderUuid: json['recommenderUuid'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'password': instance.password,
      'host': instance.host,
      'token': instance.token,
      'lastUpdateTime': instance.lastUpdateTime?.toIso8601String(),
      'loggedIn': instance.loggedIn,
      'group': instance.group,
      'email': instance.email,
      'recommenderUuid': instance.recommenderUuid,
    };
