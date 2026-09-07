import 'package:hive/hive.dart';
import 'content_chunk.dart';

part 'study_content.g.dart';

@HiveType(typeId: 4)
enum ContentSourceType {
  @HiveField(0)
  text,
  @HiveField(1)
  pdf,
  @HiveField(2)
  image,
}

@HiveType(typeId: 2)
class StudyContent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String sourceFileName;

  @HiveField(3)
  final ContentSourceType sourceType;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final List<ContentChunk> chunks;

  StudyContent({
    required this.id,
    required this.title,
    required this.sourceFileName,
    required this.sourceType,
    required this.createdAt,
    required this.chunks,
  });
}
