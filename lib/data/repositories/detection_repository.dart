import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/interfaces/face_detection_engine.dart';

/// Coordinates face detection engine calls and provides a clean API
/// for the pipeline service.
class DetectionRepository {
  DetectionRepository({
    required FaceDetectionEngine faceEngine,
    required AppLogger logger,
  })  : _faceEngine = faceEngine,
        _logger = logger;

  final FaceDetectionEngine _faceEngine;
  final AppLogger _logger;
  static const String _tag = 'DetectionRepo';

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({
    FaceDetectionConfig config = const FaceDetectionConfig(),
  }) async {
    if (_isInitialized) return;

    try {
      await _faceEngine.initialize(config);
      _isInitialized = true;
      _logger.info(_tag, 'Face detection engine initialized');
    } on Exception catch (e, st) {
      _logger.error(_tag, 'Failed to initialize face engine: $e', st);
      throw ModelLoadException(
        message: 'Face detection engine init failed: $e',
        stackTrace: st,
      );
    }
  }

  /// Returns an empty list if the engine is not initialized.
  Future<List<FaceDetectionResult>> detectFaces(CameraFrame frame) async {
    if (!_isInitialized) {
      _logger.warning(_tag, 'detectFaces called before initialization');
      return const [];
    }

    try {
      final faces = await _faceEngine.detectFaces(frame);
      return _sortBySize(faces);
    } on Exception catch (e, st) {
      _logger.warning(_tag, 'Face detection failed: $e');
      throw InferenceException(
        message: 'Face detection inference error: $e',
        stackTrace: st,
      );
    }
  }

  /// Sorts faces by bounding box area, largest first.
  List<FaceDetectionResult> _sortBySize(List<FaceDetectionResult> faces) {
    if (faces.length <= 1) return faces;

    return List<FaceDetectionResult>.from(faces)
      ..sort((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaB.compareTo(areaA); // Descending — largest first.
      });
  }

  Future<void> dispose() async {
    await _faceEngine.dispose();
    _isInitialized = false;
    _logger.info(_tag, 'DetectionRepository disposed');
  }
}
