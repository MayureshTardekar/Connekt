import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  /// If true (default), the background is rendered as a Stack with the child
  /// on top. Set [absorbGestures] to false for modal sheets where drag-to-dismiss
  /// must pass through the decorative glows.
  final bool absorbGestures;

  const PremiumBackground({
    super.key,
    required this.child,
    this.absorbGestures = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background base color
    final baseColor = isDark ? const Color(0xFF0B0812) : theme.scaffoldBackgroundColor;

    // Light mode glows (subtle) or Dark mode glows (Midnight Purple)
    final glow1Color = isDark 
        ? const Color(0xFF9047FF).withValues(alpha: 0.12)
        : const Color(0xFFD1C4E9).withValues(alpha: 0.3); // Subtle lavender
    
    final glow2Color = isDark
        ? const Color(0xFF6B3DFF).withValues(alpha: 0.1)
        : const Color(0xFFE1F5FE).withValues(alpha: 0.3); // Subtle light blue

    final glows = [
      // Base background
      Positioned.fill(
        child: IgnorePointer(
          child: Container(color: baseColor),
        ),
      ),

      // Top-left glow
      Positioned(
        top: -200,
        left: -150,
        child: IgnorePointer(
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glow1Color, Colors.transparent],
                stops: const [0.1, 1.0],
              ),
            ),
          ),
        ),
      ),

      // Bottom-right glow
      Positioned(
        bottom: -150,
        right: -150,
        child: IgnorePointer(
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glow2Color, Colors.transparent],
                stops: const [0.1, 1.0],
              ),
            ),
          ),
        ),
      ),

      if (isDark)
        // Center subtle ambient (Dark mode only)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.2,
          child: IgnorePointer(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

      child,
    ];

    return Stack(children: glows);
  }
}
