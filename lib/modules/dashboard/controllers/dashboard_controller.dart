import 'dart:async';

import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:face_mood_light_detector/domain/enums/camera_state.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:get/get.dart';

/// Composes detection sub-states for the main dashboard UI.
/// Does NOT duplicate sub-controller state; only aggregates.
///
/// Phase 2 — reads camera state. Later phases add face detection,
/// emotion, and lighting sub-controllers.
class DashboardController extends GetxController {
  final isFullPipelineReady = false.obs;
  final fps = 0.0.obs;
  final overallStatus = 'Initializing...'.obs;

  late final AppCameraController _cameraController;
  late final FrameRateMonitor _frameRateMonitor;
  late final AppLogger _logger;

  Worker? _cameraStateWorker;
  Timer? _fpsTimer;

  @override
  void onInit() {
    super.onInit();
    _cameraController = Get.find<AppCameraController>();
    _frameRateMonitor = Get.find<FrameRateMonitor>();
    _logger = Get.find<AppLogger>();

    // React to camera state changes.
    _cameraStateWorker = ever(
      _cameraController.cameraState,
      _onCameraStateChanged,
    );

    // Poll FPS from the frame rate monitor every second.
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      fps.value = _frameRateMonitor.fps;
    });

    // Set initial status from current camera state.
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
        overallStatus.value = 'Camera streaming';
        isFullPipelineReady.value = true;
        _logger.info('Dashboard', 'Camera ready — pipeline active');
      case CameraState.error:
        overallStatus.value = 'Camera error';
        isFullPipelineReady.value = false;
    }
  }

  @override
  void onClose() {
    _cameraStateWorker?.dispose();
    _fpsTimer?.cancel();
    super.onClose();
  }
}
