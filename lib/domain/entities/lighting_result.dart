import 'package:face_mood_light_detector/domain/enums/lighting_condition.dart';

class LightingResult {
  const LightingResult({
    required this.condition,
    required this.estimatedLux,
    required this.meanBrightness,
    this.overexposedPercent = 0,
    this.underexposedPercent = 0,
  });

  const LightingResult.balanced()
      : condition = LightingCondition.balanced,
        estimatedLux = 300,
        meanBrightness = 128,
        overexposedPercent = 0,
        underexposedPercent = 0;

  final LightingCondition condition;
  final double estimatedLux;

  /// Mean pixel brightness (0–255).
  final double meanBrightness;

  /// Fraction of overexposed pixels (Y > 240).
  final double overexposedPercent;

  /// Fraction of underexposed pixels (Y < 20).
  final double underexposedPercent;

  @override
  String toString() =>
      'LightingResult(${condition.label}, '
      'lux: ${estimatedLux.toStringAsFixed(0)}, '
      'mean: ${meanBrightness.toStringAsFixed(0)})';
}
