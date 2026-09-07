import 'package:hive/hive.dart';

part 'content_chunk.g.dart';

@HiveType(typeId: 3)
class ContentChunk extends HiveObject {
  @HiveField(0)
  final int index;

  @HiveField(1)
  final String text;

  // Null on platforms without local embeddings (e.g. web), where retrieval
  // falls back to keyword scoring over `text` instead.
  @HiveField(2)
  final List<double>? embedding;

  ContentChunk({required this.index, required this.text, this.embedding});
}
