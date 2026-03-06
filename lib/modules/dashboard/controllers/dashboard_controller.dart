import 'dart:async';

import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:face_mood_light_detector/domain/enums/camera_state.dart';
import 'package:face_mood_light_detector/domain/enums/detection_state.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/emotion_controller.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/face_detection_controller.dart';
import 'package:get/get.dart';

/// Composes detection sub-states for the main dashboard UI.
class DashboardController extends GetxController {
  final isFullPipelineReady = false.obs;
  final fps = 0.0.obs;
  final overallStatus = 'Initializing...'.obs;

  late final AppCameraController _cameraController;
  late final FaceDetectionController _faceDetectionController;
  late final EmotionController _emotionController;
  late final FrameRateMonitor _frameRateMonitor;
  late final AppLogger _logger;

  Worker? _cameraStateWorker;
  Worker? _detectionStateWorker;
  Worker? _emotionReadyWorker;
  Timer? _fpsTimer;

  @override
  void onInit() {
    super.onInit();
    _cameraController = Get.find<AppCameraController>();
    _faceDetectionController = Get.find<FaceDetectionController>();
    _emotionController = Get.find<EmotionController>();
    _frameRateMonitor = Get.find<FrameRateMonitor>();
    _logger = Get.find<AppLogger>();

    _cameraStateWorker = ever(
      _cameraController.cameraState,
      _onCameraStateChanged,
    );

    _detectionStateWorker = ever(
      _faceDetectionController.detectionState,
      _onDetectionStateChanged,
    );

    _emotionReadyWorker = ever(
      _emotionController.isModelReady,
      (_) => _refreshStatus(),
    );

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      fps.value = _frameRateMonitor.fps;
    });

    _onCameraStateChanged(_cameraController.cameraState.value);
  }

  void _onCameraStateChanged(CameraState state) {
    switch (state) {
      case CameraState.idle:
        overallStatus.value = 'Camera idle';
        isFullPipelineReady.value = false;
      case CameraState.initializing:
        overallStatus.value = 'Initializing camera...';
        isFullPipelineReady.value = false;
      case CameraState.ready:
        _updateStatusFromDetection(
          _faceDetectionController.detectionState.value,
        );
      case CameraState.error:
        overallStatus.value = 'Camera error';
        isFullPipelineReady.value = false;
    }
  }

  void _onDetectionStateChanged(DetectionState state) {
    if (_cameraController.cameraState.value == CameraState.ready) {
      _updateStatusFromDetection(state);
    }
  }

  void _refreshStatus() {
    if (_cameraController.cameraState.value == CameraState.ready) {
      _updateStatusFromDetection(
        _faceDetectionController.detectionState.value,
      );
    }
  }

  void _updateStatusFromDetection(DetectionState state) {
    switch (state) {
      case DetectionState.idle:
        overallStatus.value = 'Camera ready — detection idle';
        isFullPipelineReady.value = false;
      case DetectionState.detecting:
        final count = _faceDetectionController.faceCount.value;
        final emotionReady = _emotionController.isModelReady.value;
        final emotionLabel = emotionReady
            ? _emotionController.smoothedEmotion.value.label
            : 'loading model';
        overallStatus.value = count > 0
            ? 'Detecting — $count face${count == 1 ? '' : 's'} '
                '($emotionLabel)'
            : 'Detecting — no faces';
        isFullPipelineReady.value = true;
      case DetectionState.paused:
        overallStatus.value = 'Detection paused';
        isFullPipelineReady.value = false;
      case DetectionState.error:
        overallStatus.value = 'Detection error';
        isFullPipelineReady.value = false;
    }
    _logger.debug('Dashboard', 'Status: ${overallStatus.value}');
  }

  @override
  void onClose() {
    _cameraStateWorker?.dispose();
    _detectionStateWorker?.dispose();
    _emotionReadyWorker?.dispose();
    _fpsTimer?.cancel();
    super.onClose();
  }
}
