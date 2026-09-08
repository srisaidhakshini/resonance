import 'dart:async';
import 'package:flutter/material.dart';

/// Plays the "Sprite jumps into the ECHO logo" cinematic (30 pre-rendered
/// frames from Blender). By default plays once and holds on the final
/// landed frame; set [loop] to true to hold briefly on the landing, then
/// replay it — handy for a "booting" animation during a long wait.
/// Calls [onComplete] once per completed cycle.
class EchoIntroWidget extends StatefulWidget {
  final double size;
  final bool loop;
  final Duration holdDuration;
  final VoidCallback? onComplete;

  const EchoIntroWidget({
    super.key,
    this.size = 320,
    this.loop = false,
    this.holdDuration = const Duration(milliseconds: 900),
    this.onComplete,
  });

  @override
  State<EchoIntroWidget> createState() => _EchoIntroWidgetState();
}

class _EchoIntroWidgetState extends State<EchoIntroWidget> {
  static const int _frameCount = 30;
  static const Duration _frameDuration = Duration(milliseconds: 83);

  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _precache();
    _startPlayback();
  }

  void _startPlayback() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameDuration, (timer) {
      if (!mounted) return;
      if (_frame < _frameCount - 1) {
        setState(() => _frame++);
      } else {
        timer.cancel();
        widget.onComplete?.call();
        if (widget.loop) {
          _timer = Timer(widget.holdDuration, () {
            if (!mounted) return;
            setState(() => _frame = 0);
            _startPlayback();
          });
        }
      }
    });
  }

  void _precache() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < _frameCount; i++) {
        precacheImage(
          AssetImage(
            'assets/mascot/intro/frame_${i.toString().padLeft(3, '0')}.png',
          ),
          context,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameStr = _frame.toString().padLeft(3, '0');
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image.asset(
        'assets/mascot/intro/frame_$frameStr.png',
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
