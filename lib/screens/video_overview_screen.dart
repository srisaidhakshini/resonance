import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/studio_items.dart';
import '../services/voice_service.dart';

/// Kinetic-typography "video overview": an autoplaying, TTS-narrated
/// sequence of title+bullet segments, in the spirit of NotebookLM's video
/// overview but built from plain Flutter animations instead of a
/// generative image/video model (which is far too heavy to run on-device).
class VideoOverviewScreen extends StatefulWidget {
  final KineticVideoScript? initialScript;

  const VideoOverviewScreen({super.key, this.initialScript});

  @override
  State<VideoOverviewScreen> createState() => _VideoOverviewScreenState();
}

class _VideoOverviewScreenState extends State<VideoOverviewScreen> with TickerProviderStateMixin {
  late List<KineticVideoScript> _scripts;
  late KineticVideoScript _currentScript;
  final VoiceService _voiceService = VoiceService();

  int _activeSegmentIndex = 0;
  bool _isPlaying = false;
  String _selectedGrade = 'All';

  late AnimationController _revealController;
  Timer? _speechPollTimer;

  @override
  void initState() {
    super.initState();
    _scripts = StudioPreTemplates.getSampleVideoScripts();
    _currentScript = widget.initialScript ?? _scripts.first;
    _voiceService.initialize();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: 1.0, // segment 1 shows fully revealed before playback starts
    );

    if (widget.initialScript == null) {
      _initUserClass();
    }
  }

  Future<void> _initUserClass() async {
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
          final matching = _scripts.where((s) => s.gradeLevel == userGrade).toList();
          if (matching.isNotEmpty) {
            _currentScript = matching.first;
            _activeSegmentIndex = 0;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _stopPlayback();
    _revealController.dispose();
    _speechPollTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  List<KineticVideoScript> get _filteredScripts {
    if (_selectedGrade == 'All') return _scripts;
    return _scripts.where((s) => s.gradeLevel == _selectedGrade).toList();
  }

  void _switchScript(KineticVideoScript script) {
    _stopPlayback();
    setState(() {
      _currentScript = script;
      _activeSegmentIndex = 0;
    });
  }

  Future<void> _startPlayback({int fromIndex = 0}) async {
    if (_currentScript.segments.isEmpty) return;
    final startIndex = fromIndex.clamp(0, _currentScript.segments.length - 1);

    await WakelockPlus.enable();
    setState(() {
      _isPlaying = true;
      _activeSegmentIndex = startIndex;
    });

    _playSegment(startIndex);
  }

  Future<void> _playSegment(int index) async {
    if (!_isPlaying || !mounted) return;

    if (index >= _currentScript.segments.length) {
      setState(() => _isPlaying = false);
      await WakelockPlus.disable();
      return;
    }

    setState(() => _activeSegmentIndex = index);
    _revealController
      ..reset()
      ..forward();

    final segment = _currentScript.segments[index];
    await _voiceService.speakText(segment.narration, messageId: 'video_seg_$index');

    // Estimate a natural narration duration as fallback/guard, mirroring
    // AudioOverviewScreen's approach since flutter_tts gives no reliable
    // per-word completion callback on this setup.
    final wordCount = segment.narration.split(RegExp(r'\s+')).length;
    final estimatedSeconds = (wordCount / 2.5).clamp(3.0, 20.0);

    _speechPollTimer?.cancel();
    int elapsedMs = 0;
    const intervalMs = 200;
    final maxWaitMs = (estimatedSeconds * 1000).toInt();

    _speechPollTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      elapsedMs += intervalMs;
      final stillSpeaking = _voiceService.isSpeaking;

      if ((!stillSpeaking && elapsedMs > 900) || elapsedMs >= maxWaitMs) {
        timer.cancel();
        if (!_isPlaying || !mounted) return;
        await Future.delayed(const Duration(milliseconds: 400));
        if (!_isPlaying || !mounted) return;
        _playSegment(index + 1);
      }
    });
  }

  Future<void> _stopPlayback() async {
    _speechPollTimer?.cancel();
    if (mounted) setState(() => _isPlaying = false);
    await _voiceService.stopSpeaking();
    await WakelockPlus.disable();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_activeSegmentIndex >= _currentScript.segments.length - 1) {
        _startPlayback(fromIndex: 0);
      } else {
        _startPlayback(fromIndex: _activeSegmentIndex);
      }
    }
  }

  void _nextSegment() {
    if (_activeSegmentIndex < _currentScript.segments.length - 1) {
      _stopPlayback();
      _startPlayback(fromIndex: _activeSegmentIndex + 1);
    }
  }

  void _previousSegment() {
    if (_activeSegmentIndex > 0) {
      _stopPlayback();
      _startPlayback(fromIndex: _activeSegmentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentScript.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final segment = _currentScript.segments.isNotEmpty && _activeSegmentIndex < _currentScript.segments.length
        ? _currentScript.segments[_activeSegmentIndex]
        : null;

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
                    color: _isPlaying ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _isPlaying ? 'PLAYING VIDEO OVERVIEW' : 'ECHO VIDEO STUDIO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _isPlaying ? const Color(0xFFEF4444) : theme.accent,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
            Text(
              _currentScript.title,
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
          PopupMenuButton<KineticVideoScript>(
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
                  Icon(Icons.movie_filter_rounded, size: 16, color: theme.accent),
                  const SizedBox(width: 5),
                  Text(
                    'Videos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.accent,
                    ),
                  ),
                ],
              ),
            ),
            tooltip: 'Choose Video',
            onSelected: _switchScript,
            itemBuilder: (context) => _filteredScripts.map((s) {
              final isSelected = s.id == _currentScript.id;
              return PopupMenuItem<KineticVideoScript>(
                value: s,
                child: Text(
                  s.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: isSelected ? theme.accent : null,
                  ),
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
            if (widget.initialScript == null)
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
                          final filtered = _filteredScripts;
                          if (filtered.isNotEmpty && !filtered.any((s) => s.id == _currentScript.id)) {
                            _switchScript(filtered.first);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

            Expanded(
              child: segment == null
                  ? const SizedBox.shrink()
                  : _buildKineticStage(segment, theme, isDark),
            ),

            _buildBottomPlayerBar(theme, isDark),
          ],
        ),
      ),
    );
  }

  /// The animated title+bullets stage. Title reveals first (slide up +
  /// fade), then each bullet staggers in shortly after, all driven off a
  /// single [_revealController] sliced with [Interval] - the same
  /// single-controller technique `FlashcardsScreen` uses for its flip,
  /// just with more slices for the staggered bullets.
  Widget _buildKineticStage(VideoSegment segment, StudioTheme theme, bool isDark) {
    final bulletCount = segment.bulletPoints.length;

    return Container(
      key: ValueKey(_activeSegmentIndex),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132225) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF22383D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, _) {
          final titleAnim = CurvedAnimation(
            parent: _revealController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: titleAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - titleAnim.value)),
                  child: Text(
                    segment.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ...List.generate(bulletCount, (i) {
                final start = 0.45 + (i * (0.5 / bulletCount));
                final end = (start + 0.5 / bulletCount).clamp(0.0, 1.0);
                final bulletAnim = CurvedAnimation(
                  parent: _revealController,
                  curve: Interval(start.clamp(0.0, 1.0), end, curve: Curves.easeOutCubic),
                );
                return Opacity(
                  opacity: bulletAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - bulletAnim.value)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 10),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Text(
                              segment.bulletPoints[i],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomPlayerBar(StudioTheme theme, bool isDark) {
    final totalSegments = _currentScript.segments.length;

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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSegments, (i) {
              final isSegActive = i == _activeSegmentIndex;
              final isSegPast = i < _activeSegmentIndex;
              return GestureDetector(
                onTap: () {
                  _stopPlayback();
                  _startPlayback(fromIndex: i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSegActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isSegActive
                        ? theme.accent
                        : (isSegPast
                            ? theme.accent.withValues(alpha: 0.4)
                            : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _activeSegmentIndex > 0 ? _previousSegment : null,
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 28,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accent.withValues(alpha: 0.85)],
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
                onPressed: _activeSegmentIndex < totalSegments - 1 ? _nextSegment : null,
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 28,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
