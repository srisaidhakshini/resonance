import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/content_chunk.dart';
import '../models/study_content.dart';
import '../services/chunking_service.dart';
import '../services/content_processor_service.dart';
import '../services/embedding_service.dart';
import 'chat_provider.dart' show contentBoxProvider, embeddingServiceProvider;

final contentProcessorServiceProvider = Provider(
  (ref) => ContentProcessorService(),
);

final chunkingServiceProvider = Provider((ref) => ChunkingService());

class ContentNotifier extends StateNotifier<List<StudyContent>> {
  final Box<StudyContent> _box;
  final ContentProcessorService _processor;
  final ChunkingService _chunker;
  final EmbeddingService _embeddingService;

  ContentNotifier(this._box, this._processor, this._chunker, this._embeddingService)
    : super(_sorted(_box.values.toList()));

  static List<StudyContent> _sorted(List<StudyContent> items) =>
      items..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Ingest a user-picked file: extract text (OCR on mobile for photos),
  /// chunk it, embed the chunks, and persist as a new [StudyContent].
  Future<StudyContent> ingestFile(PlatformFile file) async {
    final extracted = await _processor.extractFromFile(file);
    return _ingestText(
      text: extracted.text,
      title: _titleFromFileName(file.name),
      sourceFileName: file.name,
      sourceType: extracted.sourceType,
    );
  }

  /// Ingest one of the pre-bundled sample chapters from assets.
  Future<StudyContent> ingestSampleAsset(String assetPath, String title) async {
    final raw = await rootBundle.loadString(assetPath);
    return _ingestText(
      text: raw,
      title: title,
      sourceFileName: assetPath.split('/').last,
      sourceType: ContentSourceType.text,
    );
  }

  Future<StudyContent> _ingestText({
    required String text,
    required String title,
    required String sourceFileName,
    required ContentSourceType sourceType,
  }) async {
    final rawChunks = _chunker.chunk(text);
    if (rawChunks.isEmpty) {
      throw Exception('No readable text found in this file.');
    }

    final embeddings = await _embeddingService.embedChunks(rawChunks);
    final chunks = <ContentChunk>[
      for (var i = 0; i < rawChunks.length; i++)
        ContentChunk(
          index: i,
          text: rawChunks[i],
          embedding: i < embeddings.length && embeddings[i].isNotEmpty
              ? embeddings[i]
              : null,
        ),
    ];

    final content = StudyContent(
      id: const Uuid().v4(),
      title: title,
      sourceFileName: sourceFileName,
      sourceType: sourceType,
      createdAt: DateTime.now(),
      chunks: chunks,
    );

    await _box.put(content.id, content);
    state = _sorted([content, ...state]);
    return content;
  }

  Future<void> deleteContent(String id) async {
    await _box.delete(id);
    state = state.where((c) => c.id != id).toList();
  }

  String _titleFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final withoutExt = dot > 0 ? fileName.substring(0, dot) : fileName;
    return withoutExt.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }
}

final contentNotifierProvider =
    StateNotifierProvider<ContentNotifier, List<StudyContent>>((ref) {
      final box = ref.watch(contentBoxProvider);
      final processor = ref.watch(contentProcessorServiceProvider);
      final chunker = ref.watch(chunkingServiceProvider);
      final embeddingService = ref.watch(embeddingServiceProvider);
      return ContentNotifier(box, processor, chunker, embeddingService);
    });
