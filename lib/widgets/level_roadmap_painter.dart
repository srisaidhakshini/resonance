import 'package:flutter/material.dart';

/// CustomPainter that draws:
/// 1. A clean dotted grid background matching Image 2
/// 2. Stepped (orthogonal elbow) connecting pipes between the level nodes
///    with exact per-node routing matching the reference design.
class LevelRoadmapPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final bool isDark;
  final Color connectorColor;
  final Color dotColor;

  LevelRoadmapPainter({
    required this.nodePositions,
    required this.isDark,
    Color? connectorColor,
    Color? dotColor,
  })  : connectorColor = connectorColor ??
            (isDark ? const Color(0xFF00F5A0).withOpacity(0.35) : const Color(0xFFA5D8D0)),
        dotColor = dotColor ??
            (isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFD4E5E2));

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dotted grid background
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double spacing = 26.0;
    const double radius = 1.3;

    for (double x = 12.0; x < size.width; x += spacing) {
      for (double y = 12.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    // 2. Draw stepped orthogonal pipeline connecting the level nodes
    if (nodePositions.length < 5) return;

    final pipePaint = Paint()
      ..color = connectorColor
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = nodePositions[0]; // Level 1 (center-left)
    final p2 = nodePositions[1]; // Level 2 (right)
    final p3 = nodePositions[2]; // Level 3 (center)
    final p4 = nodePositions[3]; // Level 4 (left)
    final p5 = nodePositions[4]; // Level 5 (left, below Level 4)

    // Pipe 1: Level 1 -> Level 2 (Right from Level 1, then Down into Level 2)
    final path1 = Path();
    path1.moveTo(p1.dx + 28, p1.dy);
    path1.lineTo(p2.dx, p1.dy);
    path1.lineTo(p2.dx, p2.dy - 28);
    canvas.drawPath(path1, pipePaint);

    // Pipe 2: Level 2 -> Level 3 (Down from Level 2, then Left into Level 3)
    final path2 = Path();
    path2.moveTo(p2.dx, p2.dy + 28);
    path2.lineTo(p2.dx, p3.dy);
    path2.lineTo(p3.dx + 28, p3.dy);
    canvas.drawPath(path2, pipePaint);

    // Pipe 3: Level 3 -> Level 4 (Left from Level 3, then Down into Level 4)
    final path3 = Path();
    path3.moveTo(p3.dx - 28, p3.dy);
    path3.lineTo(p4.dx, p3.dy);
    path3.lineTo(p4.dx, p4.dy - 28);
    canvas.drawPath(path3, pipePaint);

    // Pipe 4: Level 4 -> Level 5 (Straight Down with clean dotted/dashed styling)
    const double dotRadius = 2.5;
    const double dotGap = 9.0;
    final dotPipePaint = Paint()
      ..color = connectorColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final startY = p4.dy + 56;
    final endY = p5.dy - 28;
    for (double y = startY; y <= endY; y += dotGap) {
      canvas.drawCircle(Offset(p4.dx, y), dotRadius, dotPipePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LevelRoadmapPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.isDark != isDark ||
        oldDelegate.connectorColor != connectorColor ||
        oldDelegate.dotColor != dotColor;
  }
}
