import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'model_download_service.dart';

/// Computes sentence embeddings locally via a small dedicated GGUF embedding
/// model (separate from the chat model). Uses the raw synchronous [Llama]
/// class (not [LlamaParent]) since embedding is a one-shot FFI call, not a
/// streaming generation, and runs it inside [Isolate.run] so a multi-page
/// chapter doesn't block the UI thread.
class EmbeddingService {
  final ModelDownloadService _downloadService;

  EmbeddingService(this._downloadService);

  Future<List<List<double>>> embedChunks(List<String> texts) async {
    if (texts.isEmpty) return [];
    final modelPath = await _downloadService.getEmbeddingModelPath();
    return Isolate.run(() => _embedBatch(modelPath, texts));
  }

  Future<List<double>> embedQuery(String query) async {
    final modelPath = await _downloadService.getEmbeddingModelPath();
    final results = await Isolate.run(() => _embedBatch(modelPath, [query]));
    return results.first;
  }

  static List<List<double>> _embedBatch(String modelPath, List<String> texts) {
    final contextParams = ContextParams()
      ..embeddings = true
      ..poolingType = LlamaPoolingType.mean
      ..nCtx = 512
      ..nThreads = 4
      ..nThreadsBatch = 4;

    final embedder = Llama(
      modelPath,
      ModelParams(),
      contextParams,
      SamplerParams(),
    );

    try {
      return texts.map((text) => embedder.getEmbeddings(text)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ [EMBED] Failed to embed batch: $e');
      rethrow;
    } finally {
      embedder.dispose();
    }
  }
}
