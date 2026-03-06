import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/interfaces/emotion_analyzer.dart';
import 'package:face_mood_light_detector/domain/interfaces/face_detection_engine.dart';

/// Coordinates face detection and emotion engine calls and provides a
/// clean API for the pipeline service.
class DetectionRepository {
  DetectionRepository({
    required FaceDetectionEngine faceEngine,
    required EmotionAnalyzer emotionAnalyzer,
    required AppLogger logger,
  })  : _faceEngine = faceEngine,
        _emotionAnalyzer = emotionAnalyzer,
        _logger = logger;

  final FaceDetectionEngine _faceEngine;
  final EmotionAnalyzer _emotionAnalyzer;
  final AppLogger _logger;
  static const String _tag = 'DetectionRepo';

  bool _isFaceInitialized = false;
  bool _isEmotionInitialized = false;

  bool get isFaceInitialized => _isFaceInitialized;
  bool get isEmotionInitialized => _isEmotionInitialized;
  bool get isInitialized => _isFaceInitialized;

  Future<void> initialize({
    FaceDetectionConfig config = const FaceDetectionConfig(),
  }) async {
    if (_isFaceInitialized) return;

    try {
      await _faceEngine.initialize(config);
      _isFaceInitialized = true;
      _logger.info(_tag, 'Face detection engine initialized');
    } on Exception catch (e, st) {
      _logger.error(_tag, 'Failed to initialize face engine: $e', st);
      throw ModelLoadException(
        message: 'Face detection engine init failed: $e',
        stackTrace: st,
      );
    }
  }

  /// Loads the emotion model. Called separately so face detection can
  /// start immediately while the emotion model loads in the background.
  ///
  /// Returns `true` if the model loaded successfully.
  Future<bool> initializeEmotion({required String modelPath}) async {
    if (_isEmotionInitialized) return true;

    try {
      await _emotionAnalyzer.loadModel(modelPath);
      _isEmotionInitialized = true;
      _logger.info(_tag, 'Emotion analyzer initialized');
      return true;
    } on Exception catch (e, st) {
      _logger.warning(
        _tag,
        'Failed to initialize emotion analyzer: $e',
      );
      // Non-fatal — face detection still works without emotion.
      _isEmotionInitialized = false;
      _logger.error(_tag, 'Emotion init error (non-fatal)', st);
      return false;
    }
  }

  /// Returns an empty list if the engine is not initialized.
  Future<List<FaceDetectionResult>> detectFaces(CameraFrame frame) async {
    if (!_isFaceInitialized) {
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

  /// Analyses the emotion from a [FaceCrop].
  ///
  /// Returns [EmotionResult.unknown] if the model isn't loaded.
  Future<EmotionResult> analyzeEmotion(FaceCrop faceCrop) async {
    if (!_isEmotionInitialized) {
      return const EmotionResult.unknown();
    }

    try {
      return await _emotionAnalyzer.analyzeEmotion(faceCrop);
    } on InferenceException {
      rethrow;
    } on Exception catch (e, st) {
      _logger.warning(_tag, 'Emotion analysis failed: $e');
      throw InferenceException(
        message: 'Emotion analysis error: $e',
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
    await _emotionAnalyzer.dispose();
    _isFaceInitialized = false;
    _isEmotionInitialized = false;
    _logger.info(_tag, 'DetectionRepository disposed');
  }
}
