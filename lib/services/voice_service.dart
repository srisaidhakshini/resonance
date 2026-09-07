import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Singleton service managing offline Text-To-Speech and Speech-To-Text
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String? _currentlySpeakingMessageId;

  // Callbacks and streams
  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentlySpeakingIdNotifier =
      ValueNotifier<String?>(null);

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String? get currentlySpeakingMessageId => _currentlySpeakingMessageId;

  /// Initializes both TTS and STT engines
  Future<void> initialize() async {
    await _initTts();
    await _initStt();
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        isSpeakingNotifier.value = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentlySpeakingMessageId = null;
        isSpeakingNotifier.value = false;
        currentlySpeakingIdNotifier.value = null;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _currentlySpeakingMessageId = null;
        isSpeakingNotifier.value = false;
        currentlySpeakingIdNotifier.value = null;
      });

      _tts.setErrorHandler((dynamic msg) {
        _isSpeaking = false;
        _currentlySpeakingMessageId = null;
        isSpeakingNotifier.value = false;
        currentlySpeakingIdNotifier.value = null;
        if (kDebugMode) print('🔊 [TTS] Error: $msg');
      });

      _isTtsInitialized = true;
      if (kDebugMode) print('🔊 [TTS] Engine ready');
    } catch (e) {
      if (kDebugMode) print('🔊 [TTS] Init failed: $e');
    }
  }

  Future<bool> _initStt() async {
    if (_isSttInitialized) return true;
    try {
      _isSttInitialized = await _stt.initialize(
        onError: (val) {
          if (kDebugMode) print('🎙️ [STT] Error: ${val.errorMsg}');
          _isListening = false;
          isListeningNotifier.value = false;
        },
        onStatus: (status) {
          if (kDebugMode) print('🎙️ [STT] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            isListeningNotifier.value = false;
          }
        },
      );
      if (kDebugMode) print('🎙️ [STT] Engine ready: $_isSttInitialized');
      return _isSttInitialized;
    } catch (e) {
      if (kDebugMode) print('🎙️ [STT] Init error: $e');
      return false;
    }
  }

  /// Starts listening to the microphone and streams transcribed text
  Future<bool> startListening({
    required Function(String recognizedWords) onResult,
  }) async {
    if (!_isSttInitialized) {
      final ready = await _initStt();
      if (!ready) return false;
    }

    // Stop speaking if currently speaking
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      await _stt.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            isListeningNotifier.value = false;
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );

      _isListening = true;
      isListeningNotifier.value = true;
      return true;
    } catch (e) {
      if (kDebugMode) print('🎙️ [STT] Failed to start listening: $e');
      _isListening = false;
      isListeningNotifier.value = false;
      return false;
    }
  }

  /// Stops speech-to-text listening
  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    _isListening = false;
    isListeningNotifier.value = false;
  }

  /// Speaks aloud the given markdown/text content using offline TTS
  Future<void> speakText(String text, {String? messageId}) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }

    // If currently speaking this message, toggle off
    if (_isSpeaking && _currentlySpeakingMessageId == messageId) {
      await stopSpeaking();
      return;
    }

    // If speaking another message, stop first
    if (_isSpeaking) {
      await stopSpeaking();
    }

    final cleanText = _cleanTextForSpeech(text);
    if (cleanText.isEmpty) return;

    _currentlySpeakingMessageId = messageId;
    currentlySpeakingIdNotifier.value = messageId;

    try {
      await _tts.setPitch(1.0);
      await _tts.speak(cleanText);
    } catch (e) {
      if (kDebugMode) print('🔊 [TTS] Speak error: $e');
      _isSpeaking = false;
      _currentlySpeakingMessageId = null;
      isSpeakingNotifier.value = false;
      currentlySpeakingIdNotifier.value = null;
    }
  }

  /// Speaks a podcast host turn with distinct audio persona pitches
  Future<void> speakHostTurn({
    required String text,
    required bool isHostA,
    String? messageId,
    double rate = 0.5,
  }) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }
    await stopSpeaking();

    final cleanText = _cleanTextForSpeech(text);
    if (cleanText.isEmpty) return;

    _currentlySpeakingMessageId = messageId;
    currentlySpeakingIdNotifier.value = messageId;

    try {
      // Alex (Host A): 0.85 deeper pitch
      // Jamie (Host B): 1.20 brighter curious pitch
      final pitch = isHostA ? 0.85 : 1.22;
      await _tts.setPitch(pitch);
      await _tts.setSpeechRate(rate);
      await _tts.speak(cleanText);
    } catch (e) {
      if (kDebugMode) print('🔊 [TTS] Host speak error: $e');
      _isSpeaking = false;
      _currentlySpeakingMessageId = null;
      isSpeakingNotifier.value = false;
      currentlySpeakingIdNotifier.value = null;
    }
  }

  /// Stops text-to-speech immediately
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    _currentlySpeakingMessageId = null;
    isSpeakingNotifier.value = false;
    currentlySpeakingIdNotifier.value = null;
  }

  /// Removes code blocks, LaTeX, markdown tokens, and URLs for natural speech
  String _cleanTextForSpeech(String raw) {
    String text = raw;

    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' Code example omitted. ');

    // Remove inline code
    text = text.replaceAll(RegExp(r'`[^`]*`'), '');

    // Remove markdown headers
    text = text.replaceAll(RegExp(r'#+\s*'), '');

    // Remove bold and italics
    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');

    // Remove blockquotes and math callouts
    text = text.replaceAll(RegExp(r'>\s*'), '');

    // Remove URLs
    text = text.replaceAll(RegExp(r'https?:\/\/\S+'), '');

    // Normalize common math symbols into readable words
    text = text.replaceAll('+', ' plus ');
    text = text.replaceAll('−', ' minus ');
    text = text.replaceAll('-', ' minus ');
    text = text.replaceAll('×', ' times ');
    text = text.replaceAll('÷', ' divided by ');
    text = text.replaceAll('=', ' equals ');
    text = text.replaceAll('√', ' square root of ');
    text = text.replaceAll('²', ' squared ');
    text = text.replaceAll('³', ' cubed ');

    // Clean whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }
}
