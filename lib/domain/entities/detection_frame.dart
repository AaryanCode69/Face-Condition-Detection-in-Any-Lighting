import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/entities/lighting_result.dart';

/// Composite result for a single processed camera frame:
/// face detection + emotion + lighting bundled together.
class DetectionFrame {
  const DetectionFrame({
    required this.faces,
    required this.emotion,
    required this.lighting,
    required this.timestamp,
    required this.processingTimeMs,
  });

  DetectionFrame.empty()
      : faces = const [],
        emotion = const EmotionResult.unknown(),
        lighting = const LightingResult.balanced(),
        timestamp = DateTime.now().microsecondsSinceEpoch,
        processingTimeMs = 0;

  final List<FaceDetectionResult> faces;

  /// Emotion for the primary (first) face.
  final EmotionResult emotion;
  final LightingResult lighting;

  /// Camera capture timestamp in microseconds.
  final int timestamp;

  /// Total pipeline latency in ms.
  final int processingTimeMs;

  int get faceCount => faces.length;
  bool get hasFaces => faces.isNotEmpty;

  /// Largest / most confident face, if any.
  FaceDetectionResult? get primaryFace => hasFaces ? faces.first : null;

  @override
  String toString() =>
      'DetectionFrame(faces: $faceCount, '
      'emotion: ${emotion.dominantEmotion.label}, '
      'lighting: ${lighting.condition.label}, '
      'time: ${processingTimeMs}ms)';
}
