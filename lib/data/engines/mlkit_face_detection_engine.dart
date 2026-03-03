import 'dart:async';

import 'package:face_mood_light_detector/data/mappers/camera_image_mapper.dart';
import 'package:face_mood_light_detector/data/mappers/result_mapper.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/interfaces/face_detection_engine.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as mlkit;

/// Concrete [FaceDetectionEngine] backed by Google ML Kit.
class MlKitFaceDetectionEngine implements FaceDetectionEngine {
  mlkit.FaceDetector? _detector;
  bool _initialized = false;

  final StreamController<EngineStatus> _statusController =
      StreamController<EngineStatus>.broadcast();

  @override
  bool get isInitialized => _initialized;

  @override
  Stream<EngineStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize(FaceDetectionConfig config) async {
    _statusController.add(EngineStatus.initializing);

    try {
      _detector = mlkit.FaceDetector(
        options: mlkit.FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: config.enableLandmarks,
          enableTracking: config.enableTracking,
          minFaceSize: config.minFaceSize,
          performanceMode: config.performanceMode
              ? mlkit.FaceDetectorMode.fast
              : mlkit.FaceDetectorMode.accurate,
        ),
      );
      _initialized = true;
      _statusController.add(EngineStatus.ready);
    } on Exception catch (_) {
      _initialized = false;
      _statusController.add(EngineStatus.error);
      rethrow;
    }
  }

  @override
  Future<List<FaceDetectionResult>> detectFaces(CameraFrame frame) async {
    if (!_initialized || _detector == null) {
      throw StateError(
        'MlKitFaceDetectionEngine not initialized. '
        'Call initialize() first.',
      );
    }

    final inputImage = CameraImageMapper.toMlKitInputImage(frame);
    final mlFaces = await _detector!.processImage(inputImage);

    return mlFaces
        .where(
          (f) =>
              (f.headEulerAngleY ?? 0).abs() < 60 &&
              _meetsConfidence(f),
        )
        .map(ResultMapper.fromMlKitFace)
        .toList();
  }

  bool _meetsConfidence(mlkit.Face face) {
    final probs = <double>[
      if (face.smilingProbability != null) face.smilingProbability!,
      if (face.leftEyeOpenProbability != null) face.leftEyeOpenProbability!,
      if (face.rightEyeOpenProbability != null) face.rightEyeOpenProbability!,
    ];

    if (probs.isEmpty) return true;
    return true;
  }

  @override
  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _initialized = false;
    _statusController.add(EngineStatus.disposed);
    await _statusController.close();
  }
}
