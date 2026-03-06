import 'dart:async';

import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/inference_timer.dart';
import 'package:face_mood_light_detector/data/mappers/camera_image_mapper.dart';
import 'package:face_mood_light_detector/data/mappers/result_mapper.dart';
import 'package:face_mood_light_detector/data/repositories/detection_repository.dart';
import 'package:face_mood_light_detector/domain/entities/detection_frame.dart';
import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/entities/lighting_result.dart';
import 'package:face_mood_light_detector/domain/interfaces/detection_pipeline.dart';
import 'package:face_mood_light_detector/services/camera_service.dart';
import 'package:face_mood_light_detector/services/frame_throttle_service.dart';

/// Wires camera frames through face detection → emotion → lighting.
class DetectionPipelineService implements DetectionPipeline {
  DetectionPipelineService({
    required CameraService cameraService,
    required DetectionRepository detectionRepository,
    required FrameThrottleService throttleService,
    required InferenceTimer inferenceTimer,
    required AppConfig appConfig,
    required AppLogger logger,
  })  : _cameraService = cameraService,
        _detectionRepository = detectionRepository,
        _throttleService = throttleService,
        _inferenceTimer = inferenceTimer,
        _appConfig = appConfig,
        _logger = logger;

  final CameraService _cameraService;
  final DetectionRepository _detectionRepository;
  final FrameThrottleService _throttleService;
  final InferenceTimer _inferenceTimer;
  final AppConfig _appConfig;
  final AppLogger _logger;
  static const String _tag = 'Pipeline';

  final StreamController<DetectionFrame> _resultController =
      StreamController<DetectionFrame>.broadcast();

  StreamSubscription<CameraFrame>? _frameSubscription;
  bool _isRunning = false;
  bool _isProcessingFrame = false;
  int _consecutiveFailures = 0;
  bool _circuitOpen = false;

  int _processedFrames = 0;
  int _totalLatencyMs = 0;

  @override
  Stream<DetectionFrame> get resultStream => _resultController.stream;

  bool get isRunning => _isRunning;

  @override
  PipelineMetrics get metrics {
    final avgLatency =
        _processedFrames > 0 ? _totalLatencyMs ~/ _processedFrames : 0;
    return PipelineMetrics(
      detectionFps: _throttleService.processedFrames /
          (_processedFrames > 0 ? 1 : 1).toDouble(),
      faceDetectionLatencyMs: _inferenceTimer.faceDetectionMs,
      emotionLatencyMs: _inferenceTimer.emotionMs,
      totalLatencyMs: avgLatency,
      frameDropRate: _throttleService.dropRate,
    );
  }

  @override
  Future<void> start() async {
    if (_isRunning) return;

    _logger.info(_tag, 'Starting detection pipeline');

    await _detectionRepository.initialize();

    // Load emotion model in background with retries — non-blocking.
    // Face detection starts immediately; emotion results appear once loaded.
    unawaited(_loadEmotionModelWithRetry());

    _frameSubscription = _cameraService.frameStream.listen(
      _onFrame,
      onError: _onFrameError,
    );

    _isRunning = true;
    _consecutiveFailures = 0;
    _circuitOpen = false;
    _logger.info(_tag, 'Detection pipeline started');
  }

  @override
  Future<void> pause() async {
    _isRunning = false;
    _isProcessingFrame = false;
    _logger.debug(_tag, 'Pipeline paused');
  }

  @override
  Future<void> resume() async {
    _isRunning = true;
    _isProcessingFrame = false;
    _consecutiveFailures = 0;
    _circuitOpen = false;
    _logger.debug(_tag, 'Pipeline resumed');
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _isProcessingFrame = false;
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    _throttleService.reset();
    _logger.info(_tag, 'Detection pipeline stopped');
  }

  @override
  void updateConfig(PipelineConfig config) {
    _throttleService.targetFps = config.targetFps;
    _logger.debug(
      _tag,
      'Config updated: fps=${config.targetFps}, '
          'threshold=${config.faceConfidenceThreshold}',
    );
  }

  /// Processes a single camera frame through the detection pipeline.
  Future<void> _onFrame(CameraFrame frame) async {
    if (!_isRunning || _circuitOpen) return;

    // Guard against overlapping async calls — Stream.listen does NOT
    // await async callbacks, so multiple _onFrame calls can be in flight.
    if (_isProcessingFrame) return;

    // Drop frames if the pipeline is busy or rate-limited.
    if (!_throttleService.shouldProcessFrame()) return;

    _isProcessingFrame = true;
    _throttleService.markBusy();
    // Signal back-pressure to CameraService so the camera callback
    // returns immediately and does not fill the native buffer queue.
    _cameraService.isFrameBusy = true;
    _inferenceTimer.start();

    try {
      // Stage 1: Face detection.
      final faces = await _detectionRepository.detectFaces(frame);
      _inferenceTimer.recordFaceDetection();

      // Stage 2: Emotion analysis on the primary (largest) face.
      var emotion = const EmotionResult.unknown();
      if (faces.isNotEmpty && _detectionRepository.isEmotionInitialized) {
        try {
          final primaryFace = faces.first;
          final faceCrop = CameraImageMapper.extractFaceCrop(
            frame,
            primaryFace.boundingBox,
          );
          emotion = await _detectionRepository.analyzeEmotion(faceCrop);
          _inferenceTimer.recordEmotionAnalysis();

          // Adjust emotion using ML Kit face features (smile/eye detection).
          // ML Kit classifiers are very reliable and supplement the TFLite
          // model — especially for detecting smiles and tiredness.
          emotion = ResultMapper.adjustWithFaceFeatures(
            emotion,
            smilingProbability: primaryFace.smilingProbability,
            leftEyeOpenProbability: primaryFace.leftEyeOpenProbability,
            rightEyeOpenProbability: primaryFace.rightEyeOpenProbability,
          );
        } on Exception catch (e) {
          _logger.debug(
            _tag,
            'Emotion analysis skipped for this frame: $e',
          );
          // Non-fatal — continue with face results only.
        }
      }

      // Stage 3: Lighting analysis (stub — implemented in Phase 5).
      const lighting = LightingResult.balanced();

      _inferenceTimer.stop();

      final result = DetectionFrame(
        faces: faces,
        emotion: emotion,
        lighting: lighting,
        timestamp: frame.timestamp,
        processingTimeMs: _inferenceTimer.totalMs,
      );

      _resultController.add(result);
      _processedFrames++;
      _totalLatencyMs += _inferenceTimer.totalMs;
      _consecutiveFailures = 0;
    } on InferenceException catch (e) {
      _handleInferenceFailure(e);
    } on Exception catch (e, st) {
      _logger.warning(_tag, 'Frame processing error: $e');
      _handleInferenceFailure(
        InferenceException(message: '$e', stackTrace: st),
      );
    } finally {
      _isProcessingFrame = false;
      _throttleService.markIdle();
      _cameraService.isFrameBusy = false;
    }
  }

  void _onFrameError(Object error, StackTrace stackTrace) {
    _logger.warning(_tag, 'Camera frame stream error: $error');
  }

  /// Circuit breaker: after 5 consecutive failures, pauses for 2 seconds.
  void _handleInferenceFailure(InferenceException e) {
    _consecutiveFailures++;
    _logger.warning(
      _tag,
      'Inference failure #$_consecutiveFailures: ${e.message}',
    );

    if (_consecutiveFailures >= 5) {
      _circuitOpen = true;
      _logger.error(
        _tag,
        'Circuit breaker tripped after $_consecutiveFailures failures',
      );

      Future<void>.delayed(const Duration(seconds: 2), () {
        _circuitOpen = false;
        _consecutiveFailures = 0;
        _logger.info(_tag, 'Circuit breaker reset — resuming pipeline');
      });
    }
  }

  /// Loads the emotion model with up to 3 retries and exponential backoff.
  ///
  /// This prevents transient failures (e.g., after a crash) from
  /// permanently disabling emotion analysis.
  Future<void> _loadEmotionModelWithRetry() async {
    const maxRetries = 3;
    const baseDelayMs = 500;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final success = await _detectionRepository.initializeEmotion(
        modelPath: _appConfig.emotionModelPath,
      );

      if (success) {
        _logger.info(_tag, 'Emotion model ready (attempt $attempt)');
        return;
      }

      if (attempt < maxRetries) {
        final delayMs = baseDelayMs * attempt; // 500, 1000, 1500
        _logger.warning(
          _tag,
          'Emotion model load attempt $attempt/$maxRetries failed, '
              'retrying in ${delayMs}ms',
        );
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    _logger.error(
      _tag,
      'Emotion model failed to load after $maxRetries attempts. '
          'Emotion analysis will be unavailable.',
    );
  }

  Future<void> dispose() async {
    await stop();
    await _detectionRepository.dispose();
    await _resultController.close();
    _logger.info(_tag, 'DetectionPipelineService disposed');
  }
}
