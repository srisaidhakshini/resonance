import 'package:flutter/foundation.dart';

/// Defines the capabilities for different hardware tiers
class ModelConfig {
  final String tierName; // e.g., "High Performance"
  final int contextSize; // nCtx (e.g., 2048 vs 4096)
  final int historyLimit; // keepRecentPairs (e.g., 3 vs 10)
  final int maxTokens; // nPredict (e.g., 256 vs 1024)
  final int threads; // nThreads
  final int nGpuLayers;
  final int batchSize;
  final bool enableSmartContext;
  final String systemPrompt;

  const ModelConfig({
    required this.tierName,
    required this.contextSize,
    required this.historyLimit,
    required this.maxTokens,
    this.threads = 4,
    this.nGpuLayers = 0,
    this.batchSize = 512,
    this.enableSmartContext = true,
    required this.systemPrompt,
  });

  ModelConfig copyWith({
    String? tierName,
    int? contextSize,
    int? historyLimit,
    int? maxTokens,
    int? threads,
    int? nGpuLayers,
    int? batchSize,
    bool? enableSmartContext,
    String? systemPrompt,
  }) {
    return ModelConfig(
      tierName: tierName ?? this.tierName,
      contextSize: contextSize ?? this.contextSize,
      historyLimit: historyLimit ?? this.historyLimit,
      maxTokens: maxTokens ?? this.maxTokens,
      threads: threads ?? this.threads,
      nGpuLayers: nGpuLayers ?? this.nGpuLayers,
      batchSize: batchSize ?? this.batchSize,
      enableSmartContext: enableSmartContext ?? this.enableSmartContext,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  factory ModelConfig.lowSpec() {
    return const ModelConfig(
      tierName: 'Efficiency Mode',
      contextSize: 2048,
      historyLimit: 3,
      maxTokens: 256,
      threads: 4,
      systemPrompt:
          'You are Mobileshiksha, a patient, knowledgeable, and encouraging offline AI tutor.',
    );
  }

  factory ModelConfig.midSpec() {
    return const ModelConfig(
      tierName: 'Balanced Mode',
      contextSize: 2048,
      historyLimit: 5,
      maxTokens: 384,
      threads: 4,
      systemPrompt:
          'You are Mobileshiksha, a patient, knowledgeable, and encouraging offline AI tutor.',
    );
  }

  factory ModelConfig.highSpec() {
    return const ModelConfig(
      tierName: 'Performance Mode',
      contextSize: 4096,
      historyLimit: 10,
      maxTokens: 512,
      threads: 4,
      systemPrompt:
          'You are Mobileshiksha, a patient, knowledgeable, and encouraging offline AI tutor.',
    );
  }
}

class DeviceProfiler {
  static Future<ModelConfig> getBestConfig() async {
    debugPrint('🌐 [WEB] Profiling Web Browser environment: High Performance');
    return ModelConfig.highSpec();
  }

  static Future<bool> hasEnoughMemory() async {
    return true;
  }
}
