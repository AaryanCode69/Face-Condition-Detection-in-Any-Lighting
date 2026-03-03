import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';

class FaceDetectionConfig {
  const FaceDetectionConfig({
    this.minFaceSize = 0.1,
    this.performanceMode = false,
    this.enableLandmarks = true,
    this.enableTracking = true,
    this.confidenceThreshold = 0.5,
  });

  /// Relative to image (0.0–1.0).
  final double minFaceSize;
  final bool performanceMode;
  final bool enableLandmarks;
  final bool enableTracking;
  final double confidenceThreshold;

  FaceDetectionConfig copyWith({
    double? minFaceSize,
    bool? performanceMode,
    bool? enableLandmarks,
    bool? enableTracking,
    double? confidenceThreshold,
  }) {
    return FaceDetectionConfig(
      minFaceSize: minFaceSize ?? this.minFaceSize,
      performanceMode: performanceMode ?? this.performanceMode,
      enableLandmarks: enableLandmarks ?? this.enableLandmarks,
      enableTracking: enableTracking ?? this.enableTracking,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
    );
  }
}

enum EngineStatus {
  uninitialized,
  initializing,
  ready,
  error,
  disposed,
}

abstract class FaceDetectionEngine {
  Future<List<FaceDetectionResult>> detectFaces(CameraFrame frame);

  /// Must be called before [detectFaces].
  Future<void> initialize(FaceDetectionConfig config);
  Future<void> dispose();

  bool get isInitialized;
  Stream<EngineStatus> get statusStream;
}
