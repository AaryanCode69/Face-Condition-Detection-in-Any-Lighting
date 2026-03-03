import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/core/error/error_handler.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:face_mood_light_detector/services/camera_service.dart';
import 'package:face_mood_light_detector/services/frame_throttle_service.dart';
import 'package:get/get.dart';

/// Registers all dependencies for the dashboard / detection screen.
///
/// Phase 2: Camera service, throttle service, camera controller.
/// Later phases add: FaceDetection (P3), Emotion (P4),
/// Lighting (P5), Isolate inference (P6).
class DetectionBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get
      ..lazyPut<CameraService>(
        () => CameraService(
          logger: Get.find<AppLogger>(),
          frameRateMonitor: Get.find<FrameRateMonitor>(),
        ),
      )
      ..lazyPut<FrameThrottleService>(
        () => FrameThrottleService(
          targetFps: Get.find<AppConfig>().defaultTargetFps,
        ),
      );

    // Controllers
    // ignore: cascade_invocations
    Get
      ..lazyPut<AppCameraController>(
        () => AppCameraController(
          cameraService: Get.find<CameraService>(),
          logger: Get.find<AppLogger>(),
          errorHandler: Get.find<ErrorHandler>(),
        ),
      )
      ..lazyPut<DashboardController>(DashboardController.new);
  }
}
