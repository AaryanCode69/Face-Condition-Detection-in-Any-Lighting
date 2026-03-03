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

  final double meanBrightness;
  final double overexposedPercent;
  final double underexposedPercent;

  @override
  String toString() =>
      'LightingResult(${condition.label}, '
      'lux: ${estimatedLux.toStringAsFixed(0)}, '
      'mean: ${meanBrightness.toStringAsFixed(0)})';
}
