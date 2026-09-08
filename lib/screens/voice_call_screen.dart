import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/call_tutor_service.dart';
import '../services/voice_service.dart';
import '../services/web_audio_player.dart';

class VoiceCallScreen extends StatefulWidget {
  final String topic;
  final String grade;
  final bool isTwilioDirectCall;
  final String? phoneNumber;

  const VoiceCallScreen({
    super.key,
    required this.topic,
    required this.grade,
    this.isTwilioDirectCall = false,
    this.phoneNumber,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  final CallTutorService _callService = CallTutorService.instance;
  final VoiceService _voiceService = VoiceService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textInputCtrl = TextEditingController();

  late AnimationController _pulseAnimCtrl;
  late AnimationController _waveAnimCtrl;

  Timer? _callTimer;
  int _callSeconds = 0;
  bool _isMuted = false;
  bool _isListening = false;
  bool _isSpeakerOn = true;
  bool _isEchoSpeaking = false;
  bool _isStudentSpeaking = false;
  bool _showTextPad = false;
  String _callStatus = 'Connecting...';

  final List<CallTurn> _turns = [];

  @override
  void initState() {
    super.initState();

    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _voiceService.initialize();

    // Start Call Flow
    _startCallFlow();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseAnimCtrl.dispose();
    _waveAnimCtrl.dispose();
    _scrollController.dispose();
    _textInputCtrl.dispose();
    _voiceService.stopSpeaking();
    stopAudio();
    super.dispose();
  }

  void _startCallFlow() {
    setState(() => _callStatus = 'Ringing Echo Tutor...');

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _callStatus = 'Connected • ElevenLabs Live Audio';
      });

      // Start call timer
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _callSeconds++);
      });

      // Echo's opening greeting
      final greeting = "Hello! This is Echo, your AI tutor powered by ElevenLabs. I'm right here with you to solve your doubts in ${widget.topic}. What concept or question can we break down together?";
      _tutorSpeak(greeting);
    });
  }

  void _tutorSpeak(String text) async {
    if (!mounted) return;
    setState(() {
      _isEchoSpeaking = true;
      _isStudentSpeaking = false;
      _turns.add(
        CallTurn(
          speaker: 'tutor',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    if (!_isSpeakerOn) {
      if (mounted) setState(() => _isEchoSpeaking = false);
      return;
    }

    // 1. Try ElevenLabs voice audio first
    try {
      final audioBytes = await _callService.synthesizeElevenLabsVoice(text: text);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        playAudioBytes(
          audioBytes,
          onEnded: () {
            if (mounted) setState(() => _isEchoSpeaking = false);
          },
        );
        return;
      }
    } catch (e) {
      debugPrint('ElevenLabs voice note: $e');
    }

    // 2. High-fidelity browser speech synthesis (always works, clear loud voice)
    speakNativeWeb(
      text,
      onEnded: () {
        if (mounted) setState(() => _isEchoSpeaking = false);
      },
    );
  }

  void _studentAsk(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    stopAudio();
    _voiceService.stopSpeaking();

    setState(() {
      _isStudentSpeaking = true;
      _isEchoSpeaking = false;
      _turns.add(
        CallTurn(
          speaker: 'student',
          text: clean,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    // Socratic tutor reply after natural conversational latency
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final reply = _callService.generateTutorResponse(
        studentSpeech: clean,
        topic: widget.topic,
        grade: widget.grade,
        history: _turns,
      );
      _tutorSpeak(reply);
    });
  }

  String _interimSpeech = '';

  void _toggleMicrophone() async {
    if (_isListening) {
      stopNativeSpeechRecognition();
      await _voiceService.stopListening();
      if (_interimSpeech.trim().isNotEmpty) {
        final speech = _interimSpeech;
        _interimSpeech = '';
        _studentAsk(speech);
      }
      setState(() => _isListening = false);
    } else {
      stopAudio();
      _voiceService.stopSpeaking();
      _interimSpeech = '';
      setState(() {
        _isListening = true;
        _isMuted = false;
      });

      // Try browser Web Speech Recognition first (Chrome, Edge, Safari native)
      final nativeStarted = startNativeSpeechRecognition(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            _interimSpeech = text;
          });
          if (isFinal && text.trim().isNotEmpty) {
            _interimSpeech = '';
            setState(() => _isListening = false);
            _studentAsk(text);
          }
        },
        onError: () {
          if (mounted) setState(() => _isListening = false);
        },
        onEnd: () {
          if (mounted && _isListening) {
            if (_interimSpeech.trim().isNotEmpty) {
              final text = _interimSpeech;
              _interimSpeech = '';
              setState(() => _isListening = false);
              _studentAsk(text);
            } else {
              setState(() => _isListening = false);
            }
          }
        },
      );

      if (!nativeStarted) {
        // Fallback to voice_service STT
        final ok = await _voiceService.startListening(
          onResult: (words) {
            if (words.trim().isNotEmpty) {
              _studentAsk(words);
              _voiceService.stopListening();
              setState(() => _isListening = false);
            }
          },
        );

        if (!ok && mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speak your doubt or click any prompt chip below!'),
              backgroundColor: Color(0xFF0D9488),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    _callTimer?.cancel();
    _voiceService.stopSpeaking();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF131F24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF14B8A6), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Call Completed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Duration: ${_formatDuration(_callSeconds)} • ${_turns.length} conversational turns',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Key Takeaway: Active verbal discussion on ${widget.topic} boosts neural recall by up to 2.4x.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF2DD4BF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(
                  'Back to Study Studio',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Call Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        _callStatus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF14B8A6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(_callSeconds),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.grade,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Direct ElevenLabs Agent Connection Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: InkWell(
                onTap: () => openExternalUrl(
                  'https://elevenlabs.io/app/talk-to?agent_id=agent_2001m1z227myfw4s8197yntgxggf',
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C2426),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF2DD4BF), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Direct ElevenLabs Agent (Official Cloud Session)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, color: Color(0xFF2DD4BF), size: 12),
                    ],
                  ),
                ),
              ),
            ),

            if (widget.isTwilioDirectCall)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2DD4BF), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Carrier Call to ${widget.phoneNumber ?? "your phone"}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Speak into your phone earpiece or microphone. Follow the live conversation transcript below!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Center Animated Pulsing Avatar
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Outer Pulse Rings
                  AnimatedBuilder(
                    animation: _pulseAnimCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + (_isEchoSpeaking ? _pulseAnimCtrl.value * 0.28 : 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9488).withValues(
                              alpha: _isEchoSpeaking ? 0.22 : 0.07,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnimCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + (_isEchoSpeaking ? _pulseAnimCtrl.value * 0.16 : 0.04);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9488).withValues(
                              alpha: _isEchoSpeaking ? 0.35 : 0.12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Core Avatar Circle
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        (_isEchoSpeaking || _isStudentSpeaking || _isListening)
                            ? Icons.graphic_eq_rounded
                            : Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  // Status Label
                  Positioned(
                    bottom: 12,
                    child: Column(
                      children: [
                        Text(
                          'Echo AI Tutor',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.topic,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Live Speech Transcripts & Dialogue Turns
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.subtitles_rounded,
                          size: 14,
                          color: const Color(0xFF14B8A6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE CONVERSATION TRANSCRIPT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _turns.isEmpty
                          ? Center(
                              child: Text(
                                'Tap a doubt below or speak into your microphone...',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              itemCount: _turns.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final turn = _turns[i];
                                final isTutor = turn.speaker == 'tutor';
                                return Align(
                                  alignment: isTutor ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isTutor
                                          ? const Color(0xFF13282D)
                                          : const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isTutor ? 4 : 16),
                                        bottomRight: Radius.circular(isTutor ? 16 : 4),
                                      ),
                                      border: Border.all(
                                        color: isTutor
                                            ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isTutor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isTutor ? 'Echo Tutor' : 'You',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: isTutor ? const Color(0xFF2DD4BF) : Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          turn.text,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            height: 1.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Live speech listening status / recognized text
            if (_isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _interimSpeech.isEmpty ? 'Listening to your voice... Speak your question' : _interimSpeech,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Quick Suggestion Doubt Prompts
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPromptChip("Can you explain this with a real-life example?"),
                  _buildPromptChip("What is the governing formula?"),
                  _buildPromptChip("Why does this law hold true?"),
                  _buildPromptChip("What are common exam mistakes in this?"),
                  _buildPromptChip("Can we test a numerical problem?"),
                ],
              ),
            ),

            // Text Input Box (if user prefers typing during call)
            if (_showTextPad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textInputCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Type your doubt here...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                          filled: true,
                          fillColor: const Color(0xFF162529),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (val) {
                          _studentAsk(val);
                          _textInputCtrl.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF14B8A6)),
                      onPressed: () {
                        _studentAsk(_textInputCtrl.text);
                        _textInputCtrl.clear();
                      },
                    ),
                  ],
                ),
              ),

            // 5. Bottom Phone Call Controls (Mute, Keyboard, Speaker, End Call)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speak / Microphone
                  _buildCallBtn(
                    icon: _isListening
                        ? Icons.graphic_eq_rounded
                        : (_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                    label: _isListening ? 'Listening...' : (_isMuted ? 'Unmute' : 'Speak'),
                    isActive: _isListening,
                    activeColor: const Color(0xFF10B981),
                    onTap: _toggleMicrophone,
                  ),

                  // Keypad / Type Doubt
                  _buildCallBtn(
                    icon: Icons.keyboard_rounded,
                    label: 'Type',
                    isActive: _showTextPad,
                    onTap: () {
                      setState(() => _showTextPad = !_showTextPad);
                    },
                  ),

                  // Speaker
                  _buildCallBtn(
                    icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    label: 'Speaker',
                    isActive: _isSpeakerOn,
                    onTap: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                        if (!_isSpeakerOn) {
                          stopAudio();
                          _voiceService.stopSpeaking();
                        }
                      });
                    },
                  ),

                  // Red End Call Button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66EF4444),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _studentAsk(prompt),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14242B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                prompt,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF5EEAD4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final bg = isActive
        ? (activeColor ?? const Color(0xFF14B8A6)).withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.08);
    final border = isActive
        ? (activeColor ?? const Color(0xFF14B8A6))
        : Colors.white.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border, width: 1.5),
            ),
            child: Icon(icon, color: isActive ? (activeColor ?? const Color(0xFF14B8A6)) : Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

