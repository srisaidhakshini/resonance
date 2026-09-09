import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A one-shot "Sprite launches skyward" lead-in shown once before the ECHO
/// logo cinematic on the splash screen: the Sprite arcs up off the bottom
/// of the screen along a slightly curved path, its own green washes out
/// sideways and then floods the whole screen, then — mischief in tow — it
/// darts back in from the side and settles center-stage. Calls
/// [onComplete] once, when the whole sequence (including the hand-off
/// fade) has finished.
class SpriteFlyInIntro extends StatefulWidget {
  final Color backgroundColor;
  final VoidCallback? onComplete;

  const SpriteFlyInIntro({
    super.key,
    required this.backgroundColor,
    this.onComplete,
  });

  @override
  State<SpriteFlyInIntro> createState() => _SpriteFlyInIntroState();
}

class _SpriteFlyInIntroState extends State<SpriteFlyInIntro>
    with SingleTickerProviderStateMixin {
  static const _spriteAsset = 'assets/mascot/idle/frame_000.png';
  // Sampled from the sprite's own body so the wash reads as "its" color.
  static const _green = Color(0xFF7BE86B);
  static const _greenDeep = Color(0xFF4FBF56);

  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheImage(const AssetImage(_spriteAsset), context);
    });
    _controller = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_fired) {
          _fired = true;
          widget.onComplete?.call();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end, {Curve curve = Curves.linear}) {
    final raw = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // --- Flight: arcs up off the bottom, bulging right, off the top. ---
            final flightT = _phase(0.0, 0.50, curve: Curves.easeInOutCubic);
            final flightPos = _quadBezier(
              Offset(w * 0.50, h * 1.15),
              Offset(w * 0.80, h * 0.52),
              Offset(w * 0.40, h * -0.05),
              flightT,
            );
            final flightScale = flightT < 0.5
                ? _lerp(0.75, 1.05, flightT / 0.5)
                : _lerp(1.05, 0.5, (flightT - 0.5) / 0.5);
            final flightWobble = math.sin(flightT * math.pi * 2.4) * 0.14;

            // --- Green wash: spreads sideways at the sprite's height, then floods vertically. ---
            final widthT = _phase(0.10, 0.34, curve: Curves.easeOut);
            final heightT = _phase(0.32, 0.52, curve: Curves.easeIn);
            final bandCenterY = _lerp(h * 0.86, h * 0.30, flightT);
            final bandWidth = w * widthT;
            final bandHeight = _lerp(h * 0.08, h * 1.8, heightT);

            // --- Mischievous side dash-in, with a playful overshoot bounce. ---
            final dashActive = _controller.value >= 0.58;
            final dashT = _phase(0.58, 0.86, curve: Curves.easeOutBack);
            final dashX = _lerp(w * 1.2, w * 0.5, dashT);
            final dashY = h * 0.42;
            final dashScale = _lerp(0.85, 1.0, dashT.clamp(0.0, 1.2));
            final dashRotation = math.sin(dashT * math.pi * 2.5) * (1 - dashT.clamp(0.0, 1.0)) * 0.3;

            // --- Hand-off: fade the wash back to the real splash background. ---
            final fadeT = _phase(0.86, 1.0, curve: Curves.easeIn);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: (w - bandWidth) / 2,
                  top: bandCenterY - bandHeight / 2,
                  width: bandWidth,
                  height: bandHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_green, _greenDeep],
                      ),
                    ),
                  ),
                ),
                if (!dashActive)
                  Positioned(
                    left: flightPos.dx - 55,
                    top: flightPos.dy - 55,
                    width: 110,
                    height: 110,
                    child: Transform.rotate(
                      angle: flightWobble,
                      child: Transform.scale(
                        scale: flightScale,
                        child: Image.asset(_spriteAsset, fit: BoxFit.contain),
                      ),
                    ),
                  )
                else
                  Positioned(
                    left: dashX - 65,
                    top: dashY - 65,
                    width: 130,
                    height: 130,
                    child: Transform.rotate(
                      angle: dashRotation,
                      child: Transform.scale(
                        scale: dashScale,
                        child: Image.asset(_spriteAsset, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                if (fadeT > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: fadeT,
                        child: ColoredBox(color: widget.backgroundColor),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
