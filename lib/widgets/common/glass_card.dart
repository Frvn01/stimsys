import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../providers/appearance_provider.dart';

/// Hairline border color for a glass surface: bright tints need a dark
/// outline in light mode (otherwise white glass disappears on white pages).
Color glassBorderColor(Color tint, double opacity, bool isDark) {
  if (isDark) {
    return Colors.white.withValues(alpha: (opacity * 0.35 + 0.12).clamp(0.08, 0.30));
  } else {
    final alpha = (opacity + 0.25).clamp(0.0, 1.0);
    if (tint.computeLuminance() > 0.5) {
      return Colors.black.withValues(alpha: 0.08);
    }
    return tint.withValues(alpha: alpha);
  }
}

/// iOS-style frosted glass card.
///
/// Blur strength, opacity, tint and animation speed all come from the
/// student's local [AppearanceProvider] settings, so the look can be
/// customized from Profile → Appearance.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Optional accent tint (e.g. a subject color). When null the student's
  /// chosen glass tint is used.
  final Color? tint;

  /// Multiplier applied to the student's glass opacity (use for smaller
  /// surfaces so they read lighter than full-size cards).
  final double opacityScale;

  /// Explicit blur override; when null the student's glass blur is used.
  final double? blur;

  /// Optional gradient fill (e.g. the attendance banner). When set it
  /// replaces the flat tint fill but keeps the blur/border/shadow.
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tint,
    this.opacityScale = 1.0,
    this.blur,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(22);
    final sigma = blur ?? appearance.glassBlur;
    final color = tint ?? appearance.glassTint;
    final opacity = (appearance.glassOpacity * opacityScale).clamp(0.0, 1.0);
    final duration = appearance.animateDuration(const Duration(milliseconds: 280));

    // Shadow lives on an unclipped wrapper so the drop shadow isn't cut off
    // by the ClipRRect (iOS-style soft lift under every card).
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradient == null
                  ? color.withValues(alpha: opacity)
                  : null,
              gradient: gradient,
              borderRadius: radius,
              border: Border.all(
                color: gradient != null
                    ? Colors.white.withValues(alpha: 0.30)
                    : glassBorderColor(color, opacity, isDark),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
