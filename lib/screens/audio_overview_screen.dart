import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

class AudioOverviewScreen extends StatefulWidget {
  final AudioOverviewTrack? initialTrack;

  const AudioOverviewScreen({super.key, this.initialTrack});

  @override
  State<AudioOverviewScreen> createState() => _AudioOverviewScreenState();
}

class _AudioOverviewScreenState extends State<AudioOverviewScreen> with TickerProviderStateMixin {
  late List<AudioOverviewTrack> _tracks;
  late AudioOverviewTrack _currentTrack;
  final VoiceService _voiceService = VoiceService();
  final ScrollController _scrollController = ScrollController();

  int _activeTurnIndex = 0;
  bool _isPlaying = false;
  bool _isTransitioning = false;
  int _viewMode = 0; // 0: Live Studio Show, 1: Full Script Overview
  double _playbackSpeed = 0.5; // Flutter TTS rate: 0.5 is normal 1.0x speed
  String _selectedGrade = 'All';

  late AnimationController _waveController;
  late AnimationController _pulseController;
  Timer? _speechPollTimer;

  @override
  void initState() {
    super.initState();
    _tracks = StudioPreTemplates.getSamplePodcasts();
    _currentTrack = widget.initialTrack ?? _tracks.first;
    _voiceService.initialize();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _initUserClass();
  }

  Future<void> _initUserClass() async {
    if (widget.initialTrack != null) return;
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
          final matching = _tracks.where((d) => d.gradeLevel == userGrade).toList();
          if (matching.isNotEmpty) {
            _currentTrack = matching.first;
            _activeTurnIndex = 0;
            _isPlaying = false;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _stopPlayback();
    _waveController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _speechPollTimer?.cancel();
    super.dispose();
  }

  List<AudioOverviewTrack> get _filteredTracks {
    if (_selectedGrade == 'All') return _tracks;
    return _tracks.where((t) => t.gradeLevel == _selectedGrade).toList();
  }

  void _switchTrack(AudioOverviewTrack track) {
    _stopPlayback();
    setState(() {
      _currentTrack = track;
      _activeTurnIndex = 0;
      _isTransitioning = false;
    });
  }

  // Calculate approximate start timestamp string for turn (e.g. "0:24")
  String _getTimestampForTurn(int index) {
    int totalSeconds = 0;
    for (int i = 0; i < index && i < _currentTrack.transcript.length; i++) {
      final words = _currentTrack.transcript[i].dialogue.split(RegExp(r'\s+')).length;
      totalSeconds += (words / 2.5).round();
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getTotalDuration() {
    int totalSeconds = 0;
    for (final turn in _currentTrack.transcript) {
      final words = turn.dialogue.split(RegExp(r'\s+')).length;
      totalSeconds += (words / 2.5).round();
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startPlayback({int fromIndex = 0}) async {
    if (_currentTrack.transcript.isEmpty) return;
    final startIndex = fromIndex.clamp(0, _currentTrack.transcript.length - 1);

    setState(() {
      _isPlaying = true;
      _activeTurnIndex = startIndex;
      _isTransitioning = false;
    });

    _playTurn(startIndex);
  }

  Future<void> _playTurn(int index) async {
    if (!_isPlaying || !mounted) return;

    if (index >= _currentTrack.transcript.length) {
      setState(() {
        _isPlaying = false;
        _isTransitioning = false;
      });
      return;
    }

    setState(() {
      _activeTurnIndex = index;
      _isTransitioning = false;
    });

    _scrollToActiveTurn(index);

    final turn = _currentTrack.transcript[index];

    // Speak with distinct pitch for Host A (Alex) vs Host B (Jamie)
    await _voiceService.speakHostTurn(
      text: turn.dialogue,
      isHostA: turn.isHostA,
      messageId: 'podcast_turn_$index',
      rate: _playbackSpeed,
    );

    // Calculate approximate natural speaking duration as fallback/guard
    final wordCount = turn.dialogue.split(RegExp(r'\s+')).length;
    final estimatedSeconds = (wordCount / 2.5 / (_playbackSpeed * 2)).clamp(2.5, 35.0);

    // Wait until speech is complete or estimated duration passes
    _speechPollTimer?.cancel();
    int elapsedMs = 0;
    const intervalMs = 200;
    final maxWaitMs = (estimatedSeconds * 1000).toInt();

    _speechPollTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      elapsedMs += intervalMs;
      final stillSpeaking = _voiceService.isSpeaking;

      if ((!stillSpeaking && elapsedMs > 1400) || elapsedMs >= maxWaitMs) {
        timer.cancel();
        if (!_isPlaying || !mounted) return;

        // Natural co-host banter breath before next speaker chimes in
        setState(() {
          _isTransitioning = true;
        });

        await Future.delayed(const Duration(milliseconds: 650));
        if (!_isPlaying || !mounted) return;

        _playTurn(index + 1);
      }
    });
  }

  Future<void> _stopPlayback() async {
    _speechPollTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isTransitioning = false;
    });
    await _voiceService.stopSpeaking();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_activeTurnIndex >= _currentTrack.transcript.length - 1) {
        // Replay from beginning
        _startPlayback(fromIndex: 0);
      } else {
        _startPlayback(fromIndex: _activeTurnIndex);
      }
    }
  }

  void _nextTurn() {
    if (_activeTurnIndex < _currentTrack.transcript.length - 1) {
      _stopPlayback();
      _startPlayback(fromIndex: _activeTurnIndex + 1);
    }
  }

  void _previousTurn() {
    if (_activeTurnIndex > 0) {
      _stopPlayback();
      _startPlayback(fromIndex: _activeTurnIndex - 1);
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 0.5) {
        _playbackSpeed = 0.6; // 1.2x
      } else if (_playbackSpeed == 0.6) {
        _playbackSpeed = 0.75; // 1.5x
      } else {
        _playbackSpeed = 0.5; // 1.0x
      }
    });
    if (_isPlaying) {
      _playTurn(_activeTurnIndex);
    }
  }

  String get _speedLabel {
    if (_playbackSpeed == 0.6) return '1.2x';
    if (_playbackSpeed == 0.75) return '1.5x';
    return '1.0x';
  }

  void _scrollToActiveTurn(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final targetOffset = (index * 130.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTrack.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTurn = _currentTrack.transcript.isNotEmpty && _activeTurnIndex < _currentTrack.transcript.length
        ? _currentTrack.transcript[_activeTurnIndex]
        : null;
    final isHostASpeaking = _isPlaying && currentTurn != null && currentTurn.isHostA;
    final isHostBSpeaking = _isPlaying && currentTurn != null && !currentTurn.isHostA;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1618) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            _stopPlayback();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppColors.lightDestructive : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: AppColors.lightDestructive.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _isPlaying ? 'LIVE BROADCAST IN SESSION' : 'ECHO PODCAST STUDIO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _isPlaying ? AppColors.lightDestructive : theme.accent,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
            Text(
              _currentTrack.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Episode Switcher Dropdown Menu
          PopupMenuButton<AudioOverviewTrack>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.podcasts_rounded, size: 16, color: theme.accent),
                  const SizedBox(width: 5),
                  Text(
                    'Episodes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.accent,
                    ),
                  ),
                ],
              ),
            ),
            tooltip: 'Choose Episode',
            onSelected: _switchTrack,
            itemBuilder: (context) => _filteredTracks.map((t) {
              final isSelected = t.id == _currentTrack.id;
              return PopupMenuItem<AudioOverviewTrack>(
                value: t,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      size: 16,
                      color: isSelected ? theme.accent : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected ? theme.accent : null,
                            ),
                          ),
                          Text(
                            t.topic,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.gradeLevel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Grade Filter Chips Row
            Container(
              height: 38,
              margin: const EdgeInsets.only(top: 4, bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: StudioPreTemplates.allGrades.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final grade = StudioPreTemplates.allGrades[i];
                  final isSelected = grade == _selectedGrade;
                  return ChoiceChip(
                    label: Text(
                      grade,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: isDark ? const Color(0xFF162529) : Colors.white,
                    selectedColor: theme.accent,
                    side: BorderSide(
                      color: isSelected ? theme.accent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (_) {
                      setState(() {
                        _selectedGrade = grade;
                        final filtered = _filteredTracks;
                        if (filtered.isNotEmpty && !filtered.any((t) => t.id == _currentTrack.id)) {
                          _switchTrack(filtered.first);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Visible Episode / Track Selector Chips Bar
            if (_filteredTracks.length > 1)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredTracks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final t = _filteredTracks[idx];
                    final isCurrent = t.id == _currentTrack.id;
                    return InkWell(
                      onTap: () => _switchTrack(t),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.accent.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF162529) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? theme.accent
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 14,
                              color: isCurrent ? theme.accent : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent
                                    ? theme.accent
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.gradeLevel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Segmented Mode Selector: Live Podcast Studio vs Script Overview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142226) : const Color(0xFFE9EEF4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: '🎙️ Live Podcast Show',
                      isSelected: _viewMode == 0,
                      theme: theme,
                      isDark: isDark,
                      onTap: () => setState(() => _viewMode = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: '📜 Script Overview',
                      isSelected: _viewMode == 1,
                      theme: theme,
                      isDark: isDark,
                      onTap: () => setState(() => _viewMode = 1),
                    ),
                  ),
                ],
              ),
            ),

            // Central Podcast Stage (Alex vs Jamie)
            _buildPodcastStage(
              context,
              theme,
              isDark,
              isHostASpeaking,
              isHostBSpeaking,
            ),

            // Dynamic Content: Live Dialogue Back-and-Forth Stream vs Full Script
            Expanded(
              child: _viewMode == 0
                  ? _buildLiveBackAndForthView(theme, isDark, isHostASpeaking, isHostBSpeaking)
                  : _buildFullScriptView(theme, isDark),
            ),

            // Modern Bottom Player Bar
            _buildBottomPlayerBar(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required StudioTheme theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF22363B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  /// Interactive Studio Stage: Alex & Jamie facing each other with Equalizer
  Widget _buildPodcastStage(
    BuildContext context,
    StudioTheme theme,
    bool isDark,
    bool isHostASpeaking,
    bool isHostBSpeaking,
  ) {
    const hostAColor = Color(0xFF6366F1); // Indigo / Periwinkle (Alex)
    const hostBColor = Color(0xFF0EA5E9); // Cyan / Teal (Jamie)

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132225) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPlaying
              ? theme.accent.withValues(alpha: 0.45)
              : (isDark ? const Color(0xFF22383D) : const Color(0xFFE2E8F0)),
          width: _isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isPlaying
                ? theme.accent.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // HOST A: Alex (Lead Analyst)
          _buildHostBooth(
            name: 'Alex',
            persona: 'Lead Analyst',
            color: hostAColor,
            isSpeaking: isHostASpeaking,
            isDark: isDark,
            alignment: CrossAxisAlignment.start,
          ),

          // CENTER EQUALIZER & BROADCAST STATUS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? (isHostASpeaking ? hostAColor.withValues(alpha: 0.12) : hostBColor.withValues(alpha: 0.12))
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isPlaying
                          ? (isHostASpeaking ? '🎙️ Alex Speaking' : '🎙️ Jamie Speaking')
                          : '⚡ Dynamic Co-Host Banter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isPlaying
                            ? (isHostASpeaking ? hostAColor : hostBColor)
                            : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Animated Soundwave Frequency Bars
                  SizedBox(
                    height: 26,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(16, (i) {
                            double height = 4.0;
                            if (_isPlaying) {
                              final waveOffset = (_waveController.value * 6.28) + (i * 0.4);
                              height = (6.0 + 16.0 * (0.5 + 0.5 * ((waveOffset % 3.14) / 3.14))).clamp(4.0, 24.0);
                            }
                            return Container(
                              width: 3.2,
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 1.4),
                              decoration: BoxDecoration(
                                color: _isPlaying
                                    ? (isHostASpeaking ? hostAColor : hostBColor)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPlaying
                        ? 'Back-and-Forth Dialogue'
                        : 'Tap any bubble to jump host',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HOST B: Jamie (Curious Inquiry)
          _buildHostBooth(
            name: 'Jamie',
            persona: 'Curious Inquiry',
            color: hostBColor,
            isSpeaking: isHostBSpeaking,
            isDark: isDark,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _buildHostBooth({
    required String name,
    required String persona,
    required Color color,
    required bool isSpeaking,
    required bool isDark,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isSpeaking)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final pulseScale = 1.0 + (_pulseController.value * 0.25);
                  return Container(
                    width: 52 * pulseScale,
                    height: 52 * pulseScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.7 - (_pulseController.value * 0.5)),
                        width: 2.2,
                      ),
                    ),
                  );
                },
              ),
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: isSpeaking ? 0.22 : 0.12),
              child: Icon(
                Icons.record_voice_over_rounded,
                color: color,
                size: 24,
              ),
            ),
            if (isSpeaking)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132225) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSpeaking ? color : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
        Text(
          persona,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// Live Back-and-Forth Dialogue Stream with active highlighting and banter transitions
  Widget _buildLiveBackAndForthView(
    StudioTheme theme,
    bool isDark,
    bool isHostASpeaking,
    bool isHostBSpeaking,
  ) {
    final transcript = _currentTrack.transcript;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      itemCount: transcript.length + (_isTransitioning ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTransitioning && index == _activeTurnIndex + 1) {
          final nextTurn = index < transcript.length ? transcript[index] : null;
          final nextSpeaker = nextTurn?.speakerName ?? 'Co-Host';
          return _buildBanterTransitionIndicator(nextSpeaker, theme, isDark);
        }

        final realIndex = index > _activeTurnIndex && _isTransitioning ? index - 1 : index;
        if (realIndex >= transcript.length) return const SizedBox.shrink();

        final turn = transcript[realIndex];
        final isActive = realIndex == _activeTurnIndex && _isPlaying;
        final timestamp = _getTimestampForTurn(realIndex);

        return _buildPodcastTurnCard(
          turn: turn,
          turnIndex: realIndex,
          isActive: isActive,
          timestamp: timestamp,
          theme: theme,
          isDark: isDark,
        );
      },
    );
  }

  /// Back-and-Forth speech bubble aligned to the host's side
  Widget _buildPodcastTurnCard({
    required PodcastTurn turn,
    required int turnIndex,
    required bool isActive,
    required String timestamp,
    required StudioTheme theme,
    required bool isDark,
  }) {
    final isHostA = turn.isHostA;
    const hostAColor = Color(0xFF6366F1);
    const hostBColor = Color(0xFF0EA5E9);
    final hostColor = isHostA ? hostAColor : hostBColor;

    return GestureDetector(
      onTap: () {
        _stopPlayback();
        _startPlayback(fromIndex: turnIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: EdgeInsets.only(
          top: 7,
          bottom: 7,
          left: isHostA ? 0 : 34,
          right: isHostA ? 34 : 0,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? hostColor.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark
                  ? const Color(0xFF142327)
                  : (isHostA ? Colors.white : const Color(0xFFF8FAFC))),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isHostA ? 4 : 18),
            bottomRight: Radius.circular(isHostA ? 18 : 4),
          ),
          border: Border.all(
            color: isActive
                ? hostColor
                : (isDark ? const Color(0xFF22393D) : const Color(0xFFE2E8F0)),
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? hostColor.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isActive ? 12 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker Info Header
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: hostColor.withValues(alpha: 0.18),
                  child: Text(
                    isHostA ? 'A' : 'J',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: hostColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  turn.speakerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: hostColor,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: hostColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isHostA ? 'Analyst' : 'Curious Host',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: hostColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: hostColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'ON MIC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  timestamp,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Spoken Dialogue Text
            Text(
              turn.dialogue,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Natural podcast banter transition indicator
  Widget _buildBanterTransitionIndicator(String nextSpeaker, StudioTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF182A2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$nextSpeaker is chiming in...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: theme.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full Script View: Clean, structured study document
  Widget _buildFullScriptView(StudioTheme theme, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _currentTrack.transcript.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final turn = _currentTrack.transcript[index];
        final isHostA = turn.isHostA;
        final hostColor = isHostA ? const Color(0xFF6366F1) : const Color(0xFF0EA5E9);
        final timestamp = _getTimestampForTurn(index);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142327) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF22383D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: hostColor.withValues(alpha: 0.18),
                    child: Text(
                      isHostA ? 'A' : 'J',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hostColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    turn.speakerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hostColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timestamp,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                turn.dialogue,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Sleek Bottom Player Bar with scrub dots, controls, and speed selector
  Widget _buildBottomPlayerBar(StudioTheme theme, bool isDark) {
    final totalTurns = _currentTrack.transcript.length;
    final totalDuration = _getTotalDuration();
    final currentTimestamp = _getTimestampForTurn(_activeTurnIndex);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF122125) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF223A3E) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline Scrub Dots & Timestamp Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTimestamp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.accent,
                ),
              ),
              // Scrub Dots
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalTurns, (i) {
                      final isTurnActive = i == _activeTurnIndex;
                      final isTurnPast = i < _activeTurnIndex;
                      final isHostA = _currentTrack.transcript[i].isHostA;
                      final dotColor = isHostA ? const Color(0xFF6366F1) : const Color(0xFF0EA5E9);

                      return GestureDetector(
                        onTap: () {
                          _stopPlayback();
                          _startPlayback(fromIndex: i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isTurnActive ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isTurnActive
                                ? dotColor
                                : (isTurnPast
                                    ? dotColor.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Text(
                totalDuration,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Player Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed Pill Button
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2C30) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF263D42) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    'Speed $_speedLabel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: theme.accent,
                    ),
                  ),
                ),
              ),

              // Playback Controls: Prev Turn, Big Play/Pause, Next Turn
              Row(
                children: [
                  IconButton(
                    onPressed: _activeTurnIndex > 0 ? _previousTurn : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 28,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    tooltip: 'Previous Co-Host',
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.accent,
                            theme.accent.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _activeTurnIndex < totalTurns - 1 ? _nextTurn : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 28,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    tooltip: 'Next Co-Host',
                  ),
                ],
              ),

              // Replay Episode Button
              IconButton(
                onPressed: () => _startPlayback(fromIndex: 0),
                icon: const Icon(Icons.replay_rounded),
                iconSize: 22,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                tooltip: 'Replay from start',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
