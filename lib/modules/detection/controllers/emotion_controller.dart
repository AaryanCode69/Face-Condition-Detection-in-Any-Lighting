import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:get/get.dart';

class EmotionController extends GetxController {
  final currentEmotion = EmotionType.neutral.obs;

  final emotionConfidences = <EmotionType, double>{}.obs;
  final isAnalyzing = false.obs;
  final smoothedEmotion = EmotionType.neutral.obs;


}
