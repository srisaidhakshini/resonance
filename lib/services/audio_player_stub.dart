import 'package:flutter/foundation.dart';

void playAudioBytes(Uint8List bytes, {VoidCallback? onEnded}) {
  onEnded?.call();
}

void stopAudio() {}

void speakNativeWeb(String text, {VoidCallback? onEnded}) {
  onEnded?.call();
}

void openExternalUrl(String url) {}

bool startNativeSpeechRecognition({
  required void Function(String text, bool isFinal) onResult,
  required VoidCallback onError,
  required VoidCallback onEnd,
}) {
  return false;
}

void stopNativeSpeechRecognition() {}
