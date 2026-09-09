import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A signature ambient mesh background that gives screens an ultra-premium,
/// glowing depth in both Light Mode (soft mint & ice cyan) and Dark Mode
/// (midnight obsidian & electric spirit mint).
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Ambient Radial Gradient Base
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070B11) : AppColors.lightBackground,
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.6),
                radius: 1.4,
                colors: isDark
                    ? const [
                        Color(0xFF0C2422), // Deep spirit teal
                        Color(0xFF0A1821), // Dark cyan slate
                        Color(0xFF070B11), // Midnight obsidian base
                      ]
                    : const [
                        Color(0xFFE8F6F2), // Soft luminous spirit mint
                        Color(0xFFF0F6F8), // Soft ice cyan
                        Color(0xFFF7F9F7), // Clean light base
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // 2. Glowing Ambient Mint Mesh Sphere (Top Right)
        Positioned(
          top: -70,
          right: -50,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF00F5A0).withOpacity(0.14),
                          const Color(0xFF0EA5E9).withOpacity(0.07),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFF10B981).withOpacity(0.10),
                          const Color(0xFF0EA5E9).withOpacity(0.05),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
        ),

        // 3. Glowing Ambient Cyan Mesh Sphere (Mid / Bottom Left)
        Positioned(
          bottom: 120,
          left: -70,
          child: IgnorePointer(
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF10B981).withOpacity(0.12),
                          const Color(0xFF38BDF8).withOpacity(0.06),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFF38BDF8).withOpacity(0.08),
                          const Color(0xFF00F5A0).withOpacity(0.05),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
        ),

        // 4. Forefront Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
