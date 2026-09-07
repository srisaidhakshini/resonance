import 'dart:math';
import '../models/content_chunk.dart';

/// No local embeddings on web (no llama.cpp bindings in-browser), so
/// retrieval falls back to term-overlap keyword scoring over chunk text.
/// Same signature as the io implementation so callers don't care which
/// backend ran.
class RetrievalService {
  RetrievalService([dynamic embeddingService]);

  Future<List<String>> retrieve({
    required String query,
    required List<ContentChunk> chunks,
    int topK = 4,
    int maxContextChars = 1500,
  }) async {
    if (chunks.isEmpty) return [];

    final queryTerms = _terms(query);
    if (queryTerms.isEmpty) return [];

    final scored = chunks
        .map((c) => MapEntry(c, _overlapScore(queryTerms, _terms(c.text))))
        .where((e) => e.value > 0)
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

  Set<String> _terms(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^\w]+'))
      .where((t) => t.length > 2)
      .toSet();

  double _overlapScore(Set<String> queryTerms, Set<String> chunkTerms) {
    if (chunkTerms.isEmpty) return 0.0;
    final overlap = queryTerms.intersection(chunkTerms).length;
    return overlap / sqrt(chunkTerms.length);
  }
}
