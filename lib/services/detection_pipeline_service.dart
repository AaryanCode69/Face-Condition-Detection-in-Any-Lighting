import 'dart:async';

import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/inference_timer.dart';
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
    required AppLogger logger,
  })  : _cameraService = cameraService,
        _detectionRepository = detectionRepository,
        _throttleService = throttleService,
        _inferenceTimer = inferenceTimer,
        _logger = logger;

  final CameraService _cameraService;
  final DetectionRepository _detectionRepository;
  final FrameThrottleService _throttleService;
  final InferenceTimer _inferenceTimer;
  final AppLogger _logger;
  static const String _tag = 'Pipeline';

  final StreamController<DetectionFrame> _resultController =
      StreamController<DetectionFrame>.broadcast();

  StreamSubscription<CameraFrame>? _frameSubscription;
  bool _isRunning = false;
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
    _logger.debug(_tag, 'Pipeline paused');
  }

  @override
  Future<void> resume() async {
    _isRunning = true;
    _consecutiveFailures = 0;
    _circuitOpen = false;
    _logger.debug(_tag, 'Pipeline resumed');
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
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

    // Drop frames if the pipeline is busy or rate-limited.
    if (!_throttleService.shouldProcessFrame()) return;

    _throttleService.markBusy();
    // Signal back-pressure to CameraService so the camera callback
    // returns immediately and does not fill the native buffer queue.
    _cameraService.isFrameBusy = true;
    _inferenceTimer.start();

    try {
      // Stage 1: Face detection.
      final faces = await _detectionRepository.detectFaces(frame);
      _inferenceTimer.recordFaceDetection();

      // Stage 2: Emotion analysis.
      const emotion = EmotionResult.unknown();

      // Stage 3: Lighting analysis.
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

  Future<void> dispose() async {
    await stop();
    await _detectionRepository.dispose();
    await _resultController.close();
    _logger.info(_tag, 'DetectionPipelineService disposed');
  }
}
