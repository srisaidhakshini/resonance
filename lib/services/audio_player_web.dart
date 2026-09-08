// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

html.AudioElement? _activeAudio;
dynamic _recognition;

void playAudioBytes(Uint8List bytes, {VoidCallback? onEnded}) {
  stopAudio();
  try {
    final blob = html.Blob([bytes], 'audio/mpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    _activeAudio = audio;
    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(url);
      _activeAudio = null;
      onEnded?.call();
    });
    audio.onError.listen((e) {
      html.Url.revokeObjectUrl(url);
      _activeAudio = null;
      onEnded?.call();
    });
    audio.play();
  } catch (e) {
    debugPrint('Web audio play error: $e');
    onEnded?.call();
  }
}

void stopAudio() {
  try {
    _activeAudio?.pause();
    _activeAudio = null;
  } catch (_) {}
  try {
    html.window.speechSynthesis?.cancel();
  } catch (_) {}
}

void speakNativeWeb(String text, {VoidCallback? onEnded}) {
  try {
    html.window.speechSynthesis?.cancel();
    final utterance = html.SpeechSynthesisUtterance(text);
    utterance.rate = 1.0;
    utterance.pitch = 1.0;
    utterance.lang = 'en-US';
    utterance.onEnd.listen((_) {
      onEnded?.call();
    });
    utterance.onError.listen((_) {
      onEnded?.call();
    });
    html.window.speechSynthesis?.speak(utterance);
  } catch (e) {
    debugPrint('Native web speak error: $e');
    onEnded?.call();
  }
}

void openExternalUrl(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (e) {
    debugPrint('Open external URL error: $e');
  }
}

/// Browser Web Speech Recognition API (Chrome, Edge, Safari native speech-to-text)
bool startNativeSpeechRecognition({
  required void Function(String text, bool isFinal) onResult,
  required VoidCallback onError,
  required VoidCallback onEnd,
}) {
  try {
    stopNativeSpeechRecognition();

    final speechRecognitionClass = js.context['webkitSpeechRecognition'] ?? js.context['SpeechRecognition'];
    if (speechRecognitionClass == null) {
      debugPrint('SpeechRecognition not supported by browser.');
      return false;
    }

    _recognition = js.JsObject(speechRecognitionClass);
    _recognition['continuous'] = false;
    _recognition['interimResults'] = true;
    _recognition['lang'] = 'en-US';

    _recognition['onresult'] = (event) {
      try {
        final results = event['results'];
        if (results != null && results['length'] > 0) {
          final lastResult = results[results['length'] - 1];
          final transcript = lastResult[0]['transcript']?.toString() ?? '';
          final isFinal = lastResult['isFinal'] == true;
          onResult(transcript, isFinal);
        }
      } catch (e) {
        debugPrint('STT result parse error: $e');
      }
    };

    _recognition['onerror'] = (event) {
      debugPrint('STT error event: $event');
      onError();
    };

    _recognition['onend'] = () {
      onEnd();
    };

    _recognition.callMethod('start');
    return true;
  } catch (e) {
    debugPrint('Start speech recognition failed: $e');
    onError();
    return false;
  }
}

void stopNativeSpeechRecognition() {
  try {
    _recognition?.callMethod('stop');
  } catch (_) {}
  _recognition = null;
}
