import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_provider.dart';

/// Full-screen background for the student app: the student's chosen color
/// and/or wallpaper, plus two slowly drifting light blobs for an iOS-style
/// look. All values come from [AppearanceProvider] (device-local only).
class AppBackground extends StatefulWidget {
  const AppBackground({super.key});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imagePath = appearance.backgroundImagePath;
    final hasImage = !kIsWeb && imagePath != null;
    final intensity = appearance.animationIntensity;

    // No movement requested: stop the controller to save cycles.
    if (intensity <= 0.01 && _drift.isAnimating) _drift.stop();
    if (intensity > 0.01 && !_drift.isAnimating) _drift.repeat(reverse: true);

    final baseColor = appearance.backgroundColor ??
        (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA));

    return Container(
      color: baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          if (hasImage)
            // Readability scrim so text stays legible over any wallpaper.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x33000000),
                    Color(0x80000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            )
          else
            _buildDriftBlobs(isDark, intensity),
        ],
      ),
    );
  }

  Widget _buildDriftBlobs(bool isDark, double intensity) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        // Distance travelled scales with animation intensity (0 = still).
        final travel = 56.0 * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -110 + (travel * t),
              left: -70 + (travel * 0.6 * (1 - t)),
              child: _blob(
                isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8),
                isDark ? 0.40 : 0.30,
                300,
              ),
            ),
            Positioned(
              bottom: -130 + (travel * (1 - t)),
              right: -80 + (travel * 0.7 * t),
              child: _blob(
                isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD),
                isDark ? 0.34 : 0.28,
                340,
              ),
            ),
            Positioned(
              top: 320 + (travel * 0.5 * t),
              right: -120,
              child: _blob(
                isDark ? const Color(0xFF0EA5E9) : const Color(0xFF7DD3FC),
                isDark ? 0.22 : 0.20,
                260,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(Color color, double alpha, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
