import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated breathing guide that expands during inhale, holds, then contracts.
class BreathingCircle extends StatelessWidget {
  final Animation<double> animation;
  final String phaseLabel;
  final Color phaseColor;

  const BreathingCircle({
    super.key,
    required this.animation,
    required this.phaseLabel,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 0.5 + animation.value * 0.5;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 220 * scale,
                    height: 220 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withAlpha(40),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Main circle
                  Container(
                    width: 200 * scale,
                    height: 200 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          phaseColor.withAlpha(60),
                          phaseColor.withAlpha(25),
                        ],
                      ),
                      border: Border.all(
                        color: phaseColor.withAlpha(120),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        phaseLabel,
                        style: AppTypography.h2.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
