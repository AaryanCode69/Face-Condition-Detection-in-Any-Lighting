import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:face_mood_light_detector/domain/interfaces/emotion_analyzer.dart';

/// Phase 1 stub — implemented in Phase 4.
class TfliteEmotionEngine implements EmotionAnalyzer {
  @override
  bool get isModelLoaded => false;

  @override
  Future<void> loadModel(String modelPath) async {
    // TODO(phase4): Load FER+ .tflite model via tflite_flutter.
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
