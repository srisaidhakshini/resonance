/// Dependency-free reimplementation of llama_cpp_dart's TextChunker
/// (paragraph -> sentence splitting with sentence-level overlap, then
/// merging of undersized chunks). Kept as a standalone copy - rather than
/// importing llama_cpp_dart - because that package's barrel file also pulls
/// in FFI bindings that fail to compile for web. Produces the same chunk
/// boundaries as the io path for identical input.
class ChunkingService {
  List<String> chunk(String text, {int maxChunkSize = 700, int overlapSentences = 1}) {
    final paragraphSplitter = RegExp(r'\n\s*\n');
    final sentenceSplitter = RegExp(r'(?<=[.!?])\s+');

    final paragraphs = text
        .split(paragraphSplitter)
        .map((p) => p.replaceAll('\n', ' ').trim())
        .where((p) => p.isNotEmpty);

    final chunks = <String>[];

    for (final paragraph in paragraphs) {
      final sentences = paragraph
          .split(sentenceSplitter)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      var currentChunk = <String>[];
      var currentLength = 0;

      for (final sentence in sentences) {
        if (currentLength + sentence.length > maxChunkSize && currentChunk.isNotEmpty) {
          chunks.add(currentChunk.join(' '));
          final overlapStart = currentChunk.length > overlapSentences
              ? currentChunk.length - overlapSentences
              : 0;
          currentChunk = currentChunk.sublist(overlapStart);
          currentLength = currentChunk.join(' ').length;
        }
        currentChunk.add(sentence);
        currentLength += sentence.length + 1;
      }

      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk.join(' '));
      }
    }

    return _mergeSmallChunks(chunks, maxChunkSize);
  }

  List<String> _mergeSmallChunks(List<String> chunks, int maxChunkSize) {
    final merged = <String>[];
    final current = StringBuffer();

    for (final chunk in chunks) {
      if (current.isEmpty) {
        current.write(chunk);
      } else if (current.length + chunk.length + 1 <= maxChunkSize) {
        current.write(' $chunk');
      } else {
        merged.add(current.toString());
        current
          ..clear()
          ..write(chunk);
      }
    }

    if (current.isNotEmpty) {
      merged.add(current.toString());
    }

    return merged;
  }
}
