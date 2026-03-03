import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:face_mood_light_detector/domain/interfaces/emotion_analyzer.dart';

class TfliteEmotionEngine implements EmotionAnalyzer {
  @override
  bool get isModelLoaded => false;

  @override
  Future<void> loadModel(String modelPath) async {
    throw UnimplementedError('TFLite emotion engine not yet implemented');
  }

  @override
  Future<EmotionResult> analyzeEmotion(FaceCrop faceCrop) async {
    throw UnimplementedError('TFLite emotion engine not yet implemented');
  }

  @override
  Future<void> dispose() async {}

  @override
  List<EmotionType> get supportedEmotions => const [];
}
