// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_chunk.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContentChunkAdapter extends TypeAdapter<ContentChunk> {
  @override
  final int typeId = 3;

  @override
  ContentChunk read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentChunk(
      index: fields[0] as int,
      text: fields[1] as String,
      embedding: (fields[2] as List?)?.cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContentChunk obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.index)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.embedding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentChunkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
