import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/entities/lighting_result.dart';
import 'package:face_mood_light_detector/domain/enums/lighting_condition.dart';
import 'package:face_mood_light_detector/domain/interfaces/lighting_analyzer.dart';

class HistogramLightingEngine implements LightingAnalyzer {
  @override
  LightingResult analyzeLighting(CameraFrame frame) {
    return const LightingResult.balanced();
  }

  @override
  LightingResult analyzeLightingFromHistogram(List<int> histogram) {
    return const LightingResult.balanced();
  }

  @override
  LightingCondition classify(double estimatedLux) {
    return LightingCondition.balanced;
  }
}
