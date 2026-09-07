// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyContentAdapter extends TypeAdapter<StudyContent> {
  @override
  final int typeId = 2;

  @override
  StudyContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyContent(
      id: fields[0] as String,
      title: fields[1] as String,
      sourceFileName: fields[2] as String,
      sourceType: fields[3] as ContentSourceType,
      createdAt: fields[4] as DateTime,
      chunks: (fields[5] as List).cast<ContentChunk>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudyContent obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sourceFileName)
      ..writeByte(3)
      ..write(obj.sourceType)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.chunks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentSourceTypeAdapter extends TypeAdapter<ContentSourceType> {
  @override
  final int typeId = 4;

  @override
  ContentSourceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentSourceType.text;
      case 1:
        return ContentSourceType.pdf;
      case 2:
        return ContentSourceType.image;
      default:
        return ContentSourceType.text;
    }
  }

  @override
  void write(BinaryWriter writer, ContentSourceType obj) {
    switch (obj) {
      case ContentSourceType.text:
        writer.writeByte(0);
        break;
      case ContentSourceType.pdf:
        writer.writeByte(1);
        break;
      case ContentSourceType.image:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentSourceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
