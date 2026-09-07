/// Web has no local llama.cpp bindings, so real embeddings aren't available
/// in-browser. [RetrievalService] on web falls back to keyword scoring
/// instead of calling this.
class EmbeddingService {
  EmbeddingService([dynamic downloadService]);

  Future<List<List<double>>> embedChunks(List<String> texts) async =>
      List.filled(texts.length, const <double>[]);

  Future<List<double>> embedQuery(String query) async => const <double>[];
}
