import 'dart:math';
import '../models/content_chunk.dart';
import 'embedding_service.dart';

/// Ranks a chapter's chunks against a question using cosine similarity over
/// locally computed embeddings, returning the top-K chunk texts within a
/// character budget so the caller can safely inject them into the model's
/// (often small) context window.
class RetrievalService {
  final EmbeddingService _embeddingService;

  RetrievalService(this._embeddingService);

  /// Below this cosine similarity a chunk is considered unrelated to the
  /// query rather than just "the best of a bad lot". all-MiniLM-L6-v2
  /// cosine scores for genuinely relevant passages typically land 0.4+;
  /// unrelated text usually sits under 0.3. 0.35 filters clear mismatches
  /// while still tolerating loosely-phrased questions.
  static const double defaultMinSimilarity = 0.35;

  Future<List<String>> retrieve({
    required String query,
    required List<ContentChunk> chunks,
    int topK = 4,
    int maxContextChars = 1500,
    double minSimilarity = defaultMinSimilarity,
  }) async {
    if (chunks.isEmpty) return [];

    final queryEmbedding = await _embeddingService.embedQuery(query);
    if (queryEmbedding.isEmpty) return [];

    final scored =
        chunks
            .where((c) => c.embedding != null && c.embedding!.isNotEmpty)
            .map(
              (c) =>
                  MapEntry(c, _cosineSimilarity(queryEmbedding, c.embedding!)),
            )
            .where((e) => e.value >= minSimilarity)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return _withinBudget(
      scored.take(topK).map((e) => e.key.text),
      maxContextChars,
    );
  }

  List<String> _withinBudget(Iterable<String> texts, int maxChars) {
    final result = <String>[];
    var remaining = maxChars;
    for (final text in texts) {
      if (remaining <= 0) break;
      result.add(text.length > remaining ? text.substring(0, remaining) : text);
      remaining -= text.length;
    }
    return result;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;

    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA < 1e-10 || normB < 1e-10) return 0.0;
    return dotProduct / (normA * normB);
  }
}
