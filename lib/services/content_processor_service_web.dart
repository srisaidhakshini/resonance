import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/study_content.dart';
import 'content_processor_types.dart';

export 'content_processor_types.dart';

/// Web build: text-layer PDF/text extraction only. No OCR (ML Kit has no
/// browser implementation) — matches the mobile-first OCR scope decision.
class ContentProcessorService {
  bool get supportsOcr => false;

  Future<ExtractedContent> extractFromFile(PlatformFile file) async {
    final extension = (file.extension ?? '').toLowerCase();
    final bytes = file.bytes;

    if (extension == 'txt') {
      if (bytes == null) {
        throw UnsupportedContentException('Could not read the selected file.');
      }
      return ExtractedContent(
        text: utf8.decode(bytes, allowMalformed: true),
        sourceType: ContentSourceType.text,
      );
    }

    if (extension == 'pdf') {
      if (bytes == null) {
        throw UnsupportedContentException('Could not read the selected file.');
      }
      return ExtractedContent(
        text: _extractPdfText(bytes),
        sourceType: ContentSourceType.pdf,
      );
    }

    if (kImageExtensions.contains(extension)) {
      throw UnsupportedContentException(
        'Photo scanning (OCR) needs Android or iOS. On web, upload a PDF '
        'or .txt file instead.',
      );
    }

    throw UnsupportedContentException('Unsupported file type: .$extension');
  }

  String _extractPdfText(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  Future<String> extractTextFromImagePath(String path) async {
    return '';
  }
}
