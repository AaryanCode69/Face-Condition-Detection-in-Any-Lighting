import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:get/get.dart';

/// Phase 1 stub — fully implemented in Phase 4.
class EmotionController extends GetxController {
  final currentEmotion = EmotionType.neutral.obs;

  /// Confidence per emotion (0.0–1.0).
  final emotionConfidences = <EmotionType, double>{}.obs;
  final isAnalyzing = false.obs;

  /// Temporally smoothed to avoid rapid flickering.
  final smoothedEmotion = EmotionType.neutral.obs;


}
