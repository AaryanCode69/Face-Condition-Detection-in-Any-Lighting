import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/interfaces/face_detection_engine.dart';

/// Phase 1 stub — implemented in Phase 3.
class MlKitFaceDetectionEngine implements FaceDetectionEngine {
  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize(FaceDetectionConfig config) async {
    // TODO(phase3): Initialise MLKit FaceDetector with performance/accuracy.
    throw UnimplementedError('ML Kit engine not yet implemented');
  }

  @override
  Future<List<FaceDetectionResult>> detectFaces(CameraFrame frame) async {
    throw UnimplementedError('ML Kit engine not yet implemented');
  }

  @override
  Future<void> dispose() async {}

  @override
  Stream<EngineStatus> get statusStream => const Stream.empty();
}
