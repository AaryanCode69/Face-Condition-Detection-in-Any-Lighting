import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/entities/lighting_result.dart';
import 'package:face_mood_light_detector/domain/enums/lighting_condition.dart';

abstract class LightingAnalyzer {
  LightingResult analyzeLighting(CameraFrame frame);

  /// [histogram] should have 256 bins (0–255).
  LightingResult analyzeLightingFromHistogram(List<int> histogram);

  LightingCondition classify(double estimatedLux);
}
