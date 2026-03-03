import 'package:flutter/material.dart';

/// Semantic colors for detection UI overlays.
class DetectionTheme extends ThemeExtension<DetectionTheme> {
  const DetectionTheme({
    required this.overlayBoxColor,
    required this.overlayLabelBackground,
    required this.confidenceBarColor,
    required this.warningColor,
    required this.successColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  final Color overlayBoxColor;
  final Color overlayLabelBackground;
  final Color confidenceBarColor;
  final Color warningColor;
  final Color successColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  static const light = DetectionTheme(
    overlayBoxColor: Color(0xFF4CAF50),
    overlayLabelBackground: Color(0xCC000000),
    confidenceBarColor: Color(0xFF2196F3),
    warningColor: Color(0xFFFF9800),
    successColor: Color(0xFF4CAF50),
    surfaceColor: Color(0xFFF5F5F5),
    onSurfaceColor: Color(0xFF212121),
  );

  static const dark = DetectionTheme(
    overlayBoxColor: Color(0xFF81C784),
    overlayLabelBackground: Color(0xCC212121),
    confidenceBarColor: Color(0xFF64B5F6),
    warningColor: Color(0xFFFFB74D),
    successColor: Color(0xFF81C784),
    surfaceColor: Color(0xFF303030),
    onSurfaceColor: Color(0xFFFAFAFA),
  );

  @override
  DetectionTheme copyWith({
    Color? overlayBoxColor,
    Color? overlayLabelBackground,
    Color? confidenceBarColor,
    Color? warningColor,
    Color? successColor,
    Color? surfaceColor,
    Color? onSurfaceColor,
  }) {
    return DetectionTheme(
      overlayBoxColor: overlayBoxColor ?? this.overlayBoxColor,
      overlayLabelBackground:
          overlayLabelBackground ?? this.overlayLabelBackground,
      confidenceBarColor: confidenceBarColor ?? this.confidenceBarColor,
      warningColor: warningColor ?? this.warningColor,
      successColor: successColor ?? this.successColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
    );
  }

  @override
  DetectionTheme lerp(covariant DetectionTheme? other, double t) {
    if (other == null) return this;
    return DetectionTheme(
      overlayBoxColor:
          Color.lerp(overlayBoxColor, other.overlayBoxColor, t)!,
      overlayLabelBackground: Color.lerp(
        overlayLabelBackground,
        other.overlayLabelBackground,
        t,
      )!,
      confidenceBarColor:
          Color.lerp(confidenceBarColor, other.confidenceBarColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      onSurfaceColor:
          Color.lerp(onSurfaceColor, other.onSurfaceColor, t)!,
    );
  }
}
