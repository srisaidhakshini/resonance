import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ModelDownloadService {
  static const String modelUrl = 'Web Educational Assistant Engine';
  static const String modelFileName = 'qwen_web.gguf';

  Future<String> getModelPath() async {
    return 'web_in_memory_model';
  }

  Future<bool> isModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('model_downloaded_v1') ?? true;
  }

  Future<void> downloadModel({
    required Function(int received, int total) onProgress,
  }) async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress(i * 10, 100);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('model_downloaded_v1', true);
  }

  Future<void> clearModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('model_downloaded_v1', false);
  }

  Future<String> getModelSizeDisplay() async {
    return '1.5GB (Web Engine)';
  }

  void cancelDownload() {}

  // Web has no local embedding model (no llama.cpp bindings in-browser);
  // RetrievalService falls back to keyword scoring instead. Reported as
  // already "downloaded" so onboarding doesn't wait on it.
  Future<String> getEmbeddingModelPath() async => 'web_no_embedding_model';

  Future<bool> isEmbeddingModelDownloaded() async => true;

  Future<void> downloadEmbeddingModel({
    required Function(int received, int total) onProgress,
  }) async {}

  Future<bool> isReady() async => isModelDownloaded();
}
