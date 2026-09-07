import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/study_content.dart';
import 'content_processor_types.dart';

export 'content_processor_types.dart';

/// Extracts raw text from an uploaded file. PDFs and text files work on
/// every io platform (mobile + desktop); OCR for photos/scanned pages is
/// gated to Android/iOS since it's backed by Google ML Kit, which has no
/// desktop implementation.
class ContentProcessorService {
  bool get supportsOcr => Platform.isAndroid || Platform.isIOS;

  Future<ExtractedContent> extractFromFile(PlatformFile file) async {
    final extension = (file.extension ?? '').toLowerCase();

    if (extension == 'txt') {
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      return ExtractedContent(
        text: utf8.decode(bytes, allowMalformed: true),
        sourceType: ContentSourceType.text,
      );
    }

    if (extension == 'pdf') {
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      return ExtractedContent(
        text: _extractPdfText(bytes),
        sourceType: ContentSourceType.pdf,
      );
    }

    if (kImageExtensions.contains(extension)) {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        throw UnsupportedContentException(
          'Photo scanning (OCR) needs Android or iOS. On this platform, '
          'upload a PDF or .txt file instead.',
        );
      }
      if (file.path == null) {
        throw UnsupportedContentException('Could not read the selected photo.');
      }
      return ExtractedContent(
        text: await _extractImageText(file.path!),
        sourceType: ContentSourceType.image,
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

  Future<String> _extractImageText(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
