// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmDataAdapter extends TypeAdapter<AlarmData> {
  @override
  final int typeId = 0;

  @override
  AlarmData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmData()
      ..id = fields[0] as int
      ..hour = fields[1] as int
      ..minute = fields[2] as int
      ..title = fields[3] as String
      ..body = fields[4] as String
      ..soundAssetPath = fields[5] as String
      ..loopAudio = fields[6] as bool
      ..vibrate = fields[7] as bool
      ..enabled = fields[8] as bool
      ..repeatEveryday = fields[9] as bool;
  }

  @override
  void write(BinaryWriter writer, AlarmData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.soundAssetPath)
      ..writeByte(6)
      ..write(obj.loopAudio)
      ..writeByte(7)
      ..write(obj.vibrate)
      ..writeByte(8)
      ..write(obj.enabled)
      ..writeByte(9)
      ..write(obj.repeatEveryday);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
