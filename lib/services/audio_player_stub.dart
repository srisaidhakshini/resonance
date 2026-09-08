import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'voice_service.dart';

/// Native (Android/iOS/desktop) counterpart of audio_player_web.dart.
/// Plays ElevenLabs audio bytes via audioplayers and falls back to the
/// on-device VoiceService (flutter_tts) instead of browser-only APIs.

final AudioPlayer _player = AudioPlayer();
StreamSubscription<void>? _playerCompleteSub;
VoidCallback? _speakingListener;

void _clearSpeakingListener() {
  if (_speakingListener != null) {
    VoiceService().isSpeakingNotifier.removeListener(_speakingListener!);
    _speakingListener = null;
  }
}

void playAudioBytes(Uint8List bytes, {VoidCallback? onEnded}) {
  stopAudio();
  _playerCompleteSub = _player.onPlayerComplete.listen((_) {
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    onEnded?.call();
  });
  _player.play(BytesSource(bytes)).catchError((e) {
    debugPrint('Native audio play error: $e');
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    onEnded?.call();
  });
}

void stopAudio() {
  _playerCompleteSub?.cancel();
  _playerCompleteSub = null;
  _player.stop();
  _clearSpeakingListener();
  VoiceService().stopSpeaking();
}

void speakNativeWeb(String text, {VoidCallback? onEnded}) {
  final voice = VoiceService();
  _clearSpeakingListener();
  voice.stopSpeaking();

  void listener() {
    if (!voice.isSpeaking) {
      voice.isSpeakingNotifier.removeListener(listener);
      _speakingListener = null;
      onEnded?.call();
    }
  }

  _speakingListener = listener;
  voice.isSpeakingNotifier.addListener(listener);
  voice.speakText(text);
}

void openExternalUrl(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((e) {
    debugPrint('Open external URL error: $e');
    return false;
  });
}

bool startNativeSpeechRecognition({
  required void Function(String text, bool isFinal) onResult,
  required VoidCallback onError,
  required VoidCallback onEnd,
}) {
  return false;
}

void stopNativeSpeechRecognition() {}
