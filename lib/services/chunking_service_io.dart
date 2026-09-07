import 'package:llama_cpp_dart/llama_cpp_dart.dart' show TextChunker;

/// Wraps llama_cpp_dart's own TextChunker (the same class its RAG example
/// uses). Kept behind the io/web split - not because chunking itself needs
/// dart:io, but because `llama_cpp_dart`'s barrel file also pulls in its FFI
/// bindings, which fail to compile for web. See chunking_service_web.dart
/// for the dependency-free equivalent used there.
class ChunkingService {
  List<String> chunk(String text, {int maxChunkSize = 700, int overlapSentences = 1}) {
    return TextChunker(
      maxChunkSize: maxChunkSize,
      overlapSentences: overlapSentences,
    ).chunk(text);
  }
}
