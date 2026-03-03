import 'dart:async';

import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/domain/entities/detection_frame.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/detection_state.dart';
import 'package:face_mood_light_detector/services/detection_pipeline_service.dart';
import 'package:get/get.dart';

class FaceDetectionController extends GetxController {
  FaceDetectionController({
    required DetectionPipelineService pipelineService,
    required AppLogger logger,
  }) : _pipelineService = pipelineService,
       _logger = logger;

  final DetectionPipelineService _pipelineService;
  final AppLogger _logger;
  static const String _tag = 'FaceDetCtrl';

  // -- Reactive state --

  final detectionState = DetectionState.idle.obs;
  final faces = <FaceDetectionResult>[].obs;
  final faceCount = 0.obs;
  final confidence = 0.0.obs;

  final processingTimeMs = 0.obs;

  StreamSubscription<DetectionFrame>? _resultSubscription;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  Future<void> _startListening() async {
    detectionState.value = DetectionState.detecting;

    try {
      await _pipelineService.start();

      _resultSubscription = _pipelineService.resultStream.listen(
        _onDetectionResult,
        onError: _onDetectionError,
      );

      _logger.info(_tag, 'Listening to detection pipeline');
    } on Exception catch (e, st) {
      _logger.error(_tag, 'Failed to start pipeline: $e', st);
      detectionState.value = DetectionState.error;
    }
  }

  void _onDetectionResult(DetectionFrame frame) {
    faces.value = frame.faces;
    faceCount.value = frame.faceCount;
    processingTimeMs.value = frame.processingTimeMs;

    if (frame.hasFaces) {
      confidence.value = frame.primaryFace!.confidence;
    } else {
      confidence.value = 0;
    }

    // Ensure we're in detecting state.
    if (detectionState.value != DetectionState.detecting) {
      detectionState.value = DetectionState.detecting;
    }
  }

  void _onDetectionError(Object error, StackTrace stackTrace) {
    _logger.warning(_tag, 'Detection stream error: $error');
  }

  Future<void> pauseDetection() async {
    await _pipelineService.pause();
    detectionState.value = DetectionState.paused;
  }

  Future<void> resumeDetection() async {
    await _pipelineService.resume();
    detectionState.value = DetectionState.detecting;
  }

  @override
  void onClose() {
    _resultSubscription?.cancel();
    unawaited(_pipelineService.dispose());
    super.onClose();
  }
}
