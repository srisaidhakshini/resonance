import '../models/study_content.dart';

class ExtractedContent {
  final String text;
  final ContentSourceType sourceType;

  ExtractedContent({required this.text, required this.sourceType});
}

/// Thrown when a picked file can't be processed on the current platform
/// (e.g. a photo for OCR on web/desktop) or has an unrecognized extension.
class UnsupportedContentException implements Exception {
  final String message;
  UnsupportedContentException(this.message);

  @override
  String toString() => message;
}

const kImageExtensions = ['jpg', 'jpeg', 'png'];
