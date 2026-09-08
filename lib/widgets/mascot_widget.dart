import 'dart:async';
import 'package:flutter/material.dart';

/// Emotional states the Sprite mascot can react with, each backed by a
/// pre-rendered PNG frame sequence in `assets/mascot/<state>/`.
enum MascotState { idle, thinking, correct, wrong }

const Map<MascotState, int> _mascotFrameCounts = {
  MascotState.idle: 29,
  MascotState.thinking: 23,
  MascotState.correct: 20,
  MascotState.wrong: 16,
};

const Map<MascotState, String> _mascotFolders = {
  MascotState.idle: 'idle',
  MascotState.thinking: 'thinking',
  MascotState.correct: 'correct',
  MascotState.wrong: 'wrong',
};

const Set<MascotState> _loopingStates = {MascotState.idle, MascotState.thinking};

/// Plays the Sprite mascot's frame-sequence animation for a given
/// [MascotState]. Idle/thinking loop continuously; correct/wrong play once
/// and then invoke [onReactionComplete].
class MascotWidget extends StatefulWidget {
  final MascotState state;
  final double size;
  final VoidCallback? onReactionComplete;

  const MascotWidget({
    super.key,
    required this.state,
    this.size = 140,
    this.onReactionComplete,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> {
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _precache(widget.state);
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _precache(widget.state);
      _frame = 0;
      _startAnimation();
    }
  }

  void _precache(MascotState state) {
    final folder = _mascotFolders[state]!;
    final total = _mascotFrameCounts[state]!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < total; i++) {
        precacheImage(
          AssetImage('assets/mascot/$folder/frame_${i.toString().padLeft(3, '0')}.png'),
          context,
        );
      }
    });
  }

  void _startAnimation() {
    _timer?.cancel();
    final total = _mascotFrameCounts[widget.state]!;
    _timer = Timer.periodic(const Duration(milliseconds: 83), (timer) {
      if (!mounted) return;
      setState(() {
        _frame++;
        if (_frame >= total) {
          if (_loopingStates.contains(widget.state)) {
            _frame = 0;
          } else {
            _frame = total - 1;
            timer.cancel();
            widget.onReactionComplete?.call();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = _mascotFolders[widget.state]!;
    final frameStr = _frame.toString().padLeft(3, '0');
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image.asset(
        'assets/mascot/$folder/frame_$frameStr.png',
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
