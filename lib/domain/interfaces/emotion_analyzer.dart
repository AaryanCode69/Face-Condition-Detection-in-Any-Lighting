import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';

abstract class EmotionAnalyzer {
  Future<EmotionResult> analyzeEmotion(FaceCrop faceCrop);
  Future<void> loadModel(String modelPath);

  Future<void> dispose();
  bool get isModelLoaded;
  List<EmotionType> get supportedEmotions;
}
