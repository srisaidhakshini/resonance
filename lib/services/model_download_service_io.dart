import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelDownloadService {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  // Base chat model. Qwen2.5-1.5B-Instruct (not the smaller 0.5B) - chosen
  // to stay compatible with the planned federated LoRA fine-tuning pipeline
  // (laptop training on the same HF base model, merge, re-quantize to GGUF)
  // without an inference-side rewrite later, since it's still the same
  // Qwen2 architecture/ChatML format already wired into llm_service_io.
  static const String modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf';
  static const String modelFileName = 'qwen.gguf';

  // Small embedding model, used for local retrieval over uploaded chapters.
  // Separate GGUF from the chat model - loaded via the raw Llama embeddings
  // API, not LlamaParent. See EmbeddingService.
  static const String embeddingModelUrl =
      'https://huggingface.co/second-state/All-MiniLM-L6-v2-Embedding-GGUF/resolve/main/all-MiniLM-L6-v2-Q8_0.gguf';
  static const String embeddingModelFileName = 'embedding.gguf';

  // File size validation
  static const int _minModelSize = 500 * 1024 * 1024; // 500MB minimum (real file ~1.1GB)
  static const int _minEmbeddingModelSize = 5 * 1024 * 1024; // 5MB minimum (real file ~25MB)

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/model');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return '${modelDir.path}/$modelFileName';
  }

  Future<String> getEmbeddingModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/model');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return '${modelDir.path}/$embeddingModelFileName';
  }

  Future<bool> isModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('model_downloaded_v1') ?? false;

    if (!flag) return false;

    final path = await getModelPath();
    final file = File(path);

    if (await file.exists()) {
      final fileSize = await file.length();
      return fileSize >= _minModelSize;
    }
    return false;
  }

  Future<bool> isEmbeddingModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('embedding_model_downloaded_v1') ?? false;

    if (!flag) return false;

    final path = await getEmbeddingModelPath();
    final file = File(path);

    if (await file.exists()) {
      final fileSize = await file.length();
      return fileSize >= _minEmbeddingModelSize;
    }
    return false;
  }

  /// True once everything needed for offline use (chat model + embedding
  /// model for grounded Q&A) is on disk. Gates onboarding completion.
  Future<bool> isReady() async =>
      await isModelDownloaded() && await isEmbeddingModelDownloaded();

  Future<void> downloadModel({
    required Function(int received, int total) onProgress,
  }) async {
    try {
      final path = await getModelPath();
      _cancelToken = CancelToken();

      await _dio.download(
        modelUrl,
        path,
        onReceiveProgress: onProgress,
        cancelToken: _cancelToken,
        deleteOnError: true,
      );

      // Validate file size
      final file = File(path);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize < _minModelSize) {
          await file.delete();
          throw Exception('Downloaded file is too small. Please try again.');
        }
      }

      // Mark as downloaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('model_downloaded_v1', true);
    } catch (e) {
      throw Exception('Failed to download model: $e');
    }
  }

  Future<void> downloadEmbeddingModel({
    required Function(int received, int total) onProgress,
  }) async {
    try {
      final path = await getEmbeddingModelPath();
      _cancelToken = CancelToken();

      await _dio.download(
        embeddingModelUrl,
        path,
        onReceiveProgress: onProgress,
        cancelToken: _cancelToken,
        deleteOnError: true,
      );

      final file = File(path);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize < _minEmbeddingModelSize) {
          await file.delete();
          throw Exception('Downloaded file is too small. Please try again.');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('embedding_model_downloaded_v1', true);
    } catch (e) {
      throw Exception('Failed to download embedding model: $e');
    }
  }

  Future<void> clearModel() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final embeddingPath = await getEmbeddingModelPath();
    final embeddingFile = File(embeddingPath);
    if (await embeddingFile.exists()) {
      await embeddingFile.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('model_downloaded_v1', false);
    await prefs.setBool('embedding_model_downloaded_v1', false);
  }

  Future<String> getModelSizeDisplay() async {
    try {
      final path = await getModelPath();
      final file = File(path);
      if (await file.exists()) {
        final sizeBytes = await file.length();
        final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
        return '${sizeMb}MB Used';
      }
    } catch (_) {}
    return '0MB Used';
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
